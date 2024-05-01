class_name TwitchEmotesManager extends Node

const FFMPEG = "C:\\ffmpeg\\ffmpeg.exe"

class AnimatedTextureWorker:
    signal done
    var is_done: bool = false
    var emote_name: String
    var id: String
    var dir: String
    var data: PackedByteArray
    var result: AnimatedTexture

class CacheAwaitHandler:
    signal done

var workers: Array[AnimatedTextureWorker] = []

var emotes: Dictionary = {}
var cached_emotes: Dictionary = {}

var awaiting_caching: Dictionary = {}

func _ready():
    print("EMOTES::FETCHING")
    var http_request = HTTPRequest.new()
    add_child(http_request)
    http_request.request_completed.connect(_7tvEmotesRequestCompleted)

    var error = http_request.request("https://7tv.io/v3/users/twitch/895349420")
    if error != OK:
        push_error("An error occurred in the HTTP request.")


func _process(_delta: float) -> void:
    if !workers.size(): return
    for worker in workers:
        if worker.is_done:
            worker.done.emit()
            for handler in awaiting_caching[worker.emote_name]:
                handler.done.emit()
            awaiting_caching.erase(worker.emote_name)


func _7tvEmotesRequestCompleted(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
    var body_str = body.get_string_from_utf8()
    #print(body_str)
    var json = JSON.parse_string(body_str)

    if typeof(json) != TYPE_DICTIONARY:
        printerr("Could not parse 7TV emotes.")
        return

    print("EMOTES::FETCHED")
    var emote_set: Array = json["emote_set"]["emotes"]
    for emote in emote_set:
        emotes[emote["name"].to_lower()] = emote


func isEmote(text: String)-> bool:
    return emotes.has(text)


func _isEmoteCached(emote_name: String)-> bool:
    return cached_emotes.has(emote_name)


func getEmoteIfCached(emote_name: String)-> Texture2D:
    if !_isEmoteCached(emote_name): return null
    return cached_emotes[emote_name]


func _animatedTextureWorkerFunc(worker: AnimatedTextureWorker)-> void:
    # TODO: Check if frames already present in folder
    var err = DirAccess.make_dir_recursive_absolute(worker.dir)
    if err != OK:
        printerr("Could not create directory: ", worker.dir)
        worker.result = null
        worker.is_done = true
        return
    var f = FileAccess.open(worker.dir + "\\img.gif", FileAccess.WRITE)
    f.store_buffer(worker.data)
    f.close()
    OS.execute(FFMPEG, ["-i", worker.dir + "\\img.gif", worker.dir + "\\%04d.png"])
    DirAccess.remove_absolute(worker.dir + "\\img.gif")
    var files = DirAccess.get_files_at(worker.dir)
    var animated_texture = AnimatedTexture.new()
    for filename in files:
        var idx: int = int(filename.replace(".png", ""))
        if idx > 255: continue
        var img_data: PackedByteArray = FileAccess.get_file_as_bytes(worker.dir + "\\" + filename)
        var image: Image = Image.new()
        image.load_png_from_buffer(img_data)
        var texture: ImageTexture = ImageTexture.create_from_image(image)
        animated_texture.frames = idx
        animated_texture.set_frame_texture(idx - 1, texture)
        animated_texture.set_frame_duration(idx - 1, 0.05)
    worker.result = animated_texture
    worker.is_done = true


func _generateAnimatedTexture(emote_name: String, id: String, data: PackedByteArray)-> AnimatedTexture:
    var dir = OS.get_user_data_dir() + "\\hilda3D_emote\\%s" % id
    # worker will act as a bundle we want to pass to the new thread
    var worker: AnimatedTextureWorker = AnimatedTextureWorker.new()
    worker.id = id
    worker.dir = dir
    worker.data = data
    worker.emote_name = emote_name
    var t = Thread.new()
    workers.push_back(worker)
    t.start(_animatedTextureWorkerFunc.bind(worker), Thread.PRIORITY_NORMAL)
    await worker.done
    t.wait_to_finish()
    workers.remove_at(workers.find(worker))
    return worker.result


func _asyncFetchGifEmote(id: String)-> PackedByteArray:
    var http_request = HTTPRequest.new()
    add_child(http_request)

    var url = "https://cdn.7tv.app/emote/%s/1x.gif" % id

    var error = http_request.request(url)
    if error != OK:
        push_error("An error occurred in the HTTP request.")

    var request = await http_request.request_completed

    remove_child(http_request)
    http_request.queue_free()

    return request[3]


func _asyncFetchPngFallback(id: String)-> PackedByteArray:
    var http_request = HTTPRequest.new()
    add_child(http_request)

    var url = "https://cdn.7tv.app/emote/%s/1x.png" % id

    var error = http_request.request(url)
    if error != OK:
        push_error("An error occurred in the HTTP request.")

    var request = await http_request.request_completed

    remove_child(http_request)
    http_request.queue_free()

    return request[3]


func _isCachedOnDisk(id: String)-> bool:
    var dir = OS.get_user_data_dir() + "\\hilda3D_emote\\%s" % id
    return DirAccess.dir_exists_absolute(dir)


func _cachePngToDisk(id: String, data: PackedByteArray)-> void:
    var dir = OS.get_user_data_dir() + "\\hilda3D_emote\\%s" % id
    var err = DirAccess.make_dir_recursive_absolute(dir)
    if err != OK:
        printerr("Could not create directory: ", dir)
        return
    var f = FileAccess.open(dir + "\\img.png", FileAccess.WRITE)
    f.store_buffer(data)
    f.close()


func _getPngFromDisk(id)-> ImageTexture:
    var dir = OS.get_user_data_dir() + "\\hilda3D_emote\\%s" % id
    var data = FileAccess.get_file_as_bytes(dir + "\\img.png")
    var img = Image.new()
    var err = img.load_png_from_buffer(data)
    if err != OK:
        pass
    return ImageTexture.create_from_image(img)


func _gifCacheRetreiveWorker(worker: AnimatedTextureWorker)-> void:
    var files = DirAccess.get_files_at(worker.dir)
    var animated_texture = AnimatedTexture.new()

    for filename in files:
        var idx: int = int(filename.replace(".png", ""))
        if idx > 255: continue
        var img_data: PackedByteArray = FileAccess.get_file_as_bytes(worker.dir + "\\" + filename)
        var image: Image = Image.new()
        image.load_png_from_buffer(img_data)
        var texture: ImageTexture = ImageTexture.create_from_image(image)
        animated_texture.frames = idx
        animated_texture.set_frame_texture(idx - 1, texture)
        animated_texture.set_frame_duration(idx - 1, 0.05)

    worker.result = animated_texture
    worker.is_done = true


func _getGifFromDisk(id, emote_name)-> AnimatedTexture:
    var dir = OS.get_user_data_dir() + "\\hilda3D_emote\\%s" % id
    var worker: AnimatedTextureWorker = AnimatedTextureWorker.new()
    worker.id = id
    worker.dir = dir
    worker.data = []
    worker.emote_name = emote_name
    var t = Thread.new()
    workers.push_back(worker)
    t.start(_gifCacheRetreiveWorker.bind(worker), Thread.PRIORITY_NORMAL)
    await worker.done
    t.wait_to_finish()
    workers.remove_at(workers.find(worker))
    return worker.result


func asyncFetchEmote(emote_name: String)-> Texture2D:
    # If for some reason the emote is already in cache, return directly
    if cached_emotes.has(emote_name):
        return cached_emotes[emote_name] as Texture2D

    # If is in the process of getting cached, await end of caching
    if awaiting_caching.has(emote_name):
        var handler = CacheAwaitHandler.new()
        awaiting_caching[emote_name].push_back(handler)
        await handler.done
        return cached_emotes[emote_name] as Texture2D

    # If is not in the process of getting cached, start the caching process
    awaiting_caching[emote_name] = []

    var emote: Dictionary = emotes[emote_name]

    # Check if is animated emote
    var is_gif: bool = emote["data"]["animated"]
    var id: String = emote["id"]

    # If has alread been stored to disk
    if _isCachedOnDisk(id):
        var texture: Texture2D
        if is_gif:
            texture = await _getGifFromDisk(id, emote_name)
        else:
            texture = _getPngFromDisk(id)
        cached_emotes[emote_name] = texture
        return texture

    # If hasn't been stored to disk, download from 7TV
    var http_request: HTTPRequest = HTTPRequest.new()
    add_child(http_request)

    var url: String = "https://cdn.7tv.app/emote/%s/1x%s" % [id, ".gif" if is_gif else ".png"]

    var error = http_request.request(url)
    if error != OK:
        push_error("An error occurred in the HTTP request.")

    var request = await http_request.request_completed

    remove_child(http_request)
    http_request.queue_free()

    if is_gif:
        # If is gif, the image must be split into frames before being used as texture
        # This function will offload the work to another thread in order to unclog
        # the main thread.
        var animated_texture = await _generateAnimatedTexture(emote_name, id, request[3])
        cached_emotes[emote_name] = animated_texture
        return animated_texture
    else:
        _cachePngToDisk(id, request[3])
        var img = Image.new()
        var err = img.load_png_from_buffer(request[3])
        if err != OK:
            pass
        var texture: ImageTexture = ImageTexture.create_from_image(img)
        cached_emotes[emote_name] = texture
        return texture
