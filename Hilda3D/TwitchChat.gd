class_name TwitchChat extends ScrollContainer

const SCROLL_SPEED: int = 800
const MAX_DISPLAYED_MSGS: int = 10
const RANDOMS_ARRAY_AMOUNT: int = 64

var displayed_msgs_amount: int = 0
var randoms_array: Array[float] = []
var random_index: int = RANDOMS_ARRAY_AMOUNT
var rgx_only_alphanum: RegEx = RegEx.create_from_string("[^a-z0-9]")

var ref_world: World = null
@onready var ref_chatcont: VBoxContainer = $"VBoxContainer"
@onready var ref_template_msg: VBoxContainer = $"VBoxContainer/TemplateChatMessage"


func _ready() -> void:
    ref_world = get_tree().current_scene
    _initRandomsArray(randoms_array)


func _process(delta: float) -> void:
    if scroll_vertical < ref_chatcont.size.y:
        scroll_vertical += int(SCROLL_SPEED * delta)


## Initializes an array of random numbers, faster than using randf()
## Use those random numbers using _randf()
func _initRandomsArray(array: Array[float])-> void:
    if array.resize(RANDOMS_ARRAY_AMOUNT): return
    var i: int = RANDOMS_ARRAY_AMOUNT
    while i:
        i -= 1
        array[i] = randf()


## randf() but faster
func _randf()-> float:
    random_index = random_index - 1 if random_index else RANDOMS_ARRAY_AMOUNT - 1
    return randoms_array[random_index]


func removeOverflowMessage()-> void:
    var cnb = ref_chatcont.get_child_count()
    while cnb > MAX_DISPLAYED_MSGS:
        var child = ref_chatcont.get_child(1)
        ref_chatcont.remove_child(child)
        child.queue_free()
        cnb -= 1


func displayChatMessage(username: String, content: String)-> void:
    var temp = ref_template_msg.duplicate()
    var lbl_username: Label = temp.get_child(1) as Label
    lbl_username.text = username
    lbl_username.visible_characters = 26
    lbl_username.self_modulate = Color.from_hsv(
        _randf(),
        (_randf() * 0.5) + 0.3,
        (_randf() * 0.25) + 0.75,
        1.0
    )
    populateChatMessageContent(content, temp)
    temp.visible = true
    ref_chatcont.add_child(temp)
    removeOverflowMessage()


func populateChatMessageContent(content: String, chatnode: VBoxContainer)-> void:
    var em: TwitchEmotesManager = ref_world.ref_emotemanager
    var ref_wrapcont: HFlowContainer = chatnode.get_child(2) as HFlowContainer
    var ref_tempword: Label = chatnode.get_child(3) as Label
    var ref_tempemote: TextureRect = chatnode.get_child(4) as TextureRect
    var split: PackedStringArray = content.split(" ", false)
    for word: String in split:
        var sanitized: String = rgx_only_alphanum.sub(word.to_lower(), "")
        if em.isEmote(sanitized):
            var emote: TextureRect = ref_tempemote.duplicate() as TextureRect
            ref_wrapcont.add_child(emote)
            var emote_texture: Texture2D = em.getEmoteIfCached(sanitized)
            if emote_texture == null:
                emote_texture = await em.asyncFetchEmote(sanitized)
            if !is_instance_valid(emote): continue
            emote.texture = emote_texture
            emote.visible = true
            continue
        if !is_instance_valid(chatnode): return
        var tword: Label = ref_tempword.duplicate() as Label
        tword.text = "%s " % word
        tword.visible_characters = 26
        tword.visible = true
        ref_wrapcont.add_child(tword)
