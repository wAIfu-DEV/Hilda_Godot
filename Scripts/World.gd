class_name World extends Node3D

@export var flag_auto_scene_switching: bool = true
@export var flag_display_chat: bool = true

class Scene:
    var scene_name: String
    var hilda: String
    var camera: String

    var fn_start_anim = func(): pass
    var fn_end_anim = func(): pass

    func _init(_name: String, _hilda: String, _camera: String) -> void:
        scene_name = _name
        hilda = _hilda
        camera = _camera


# CONSTANTS --------------------------------------------------------------------
const SCENE_INIT: String = "Init"
const SCENE_START: String = "StartScreen"
const SCENE_ORTHO: String = "Orthogonal"
const SCENE_NONE: String = "None"
const SCENE_TRACKING: String = "Tracking"
const SCENE_REACT: String = "React"
const SCENE_CONCERT: String = "Concert"

var ScenesDict: Dictionary = {
    SCENE_INIT: Scene.new(SCENE_INIT, "Hilda", "TVSceneCamera"),
    SCENE_START: Scene.new(SCENE_START, "StartingScreenHilda", "StartingScreenCamera"),
    SCENE_ORTHO: Scene.new(SCENE_ORTHO, "HildaOrthoCam", "OrthogonalCamera2"),
    SCENE_NONE: Scene.new(SCENE_NONE, "Hilda", ""),
    SCENE_TRACKING: Scene.new(SCENE_TRACKING, "Hilda", "TrackingCamera1"),
    SCENE_REACT: Scene.new(SCENE_REACT, "HildaReact", "ReactCamera"),
    SCENE_CONCERT: Scene.new(SCENE_CONCERT, "HildaConcert", "ConcertHallCamera1")
}

var AUTO_SCENES: Array[String] = [
    SCENE_START,
    SCENE_ORTHO,
    SCENE_NONE
]

const AUTO_SCENE_CHANGE_COOLDOWN: float = 120.0

const VOICE_PADDING_START: float = 0.05
const VOICE_PADDING_END: float = 0.0

const DEFAULT_VOICE_PLAYER_VOLUME: float = 13.0
const DEFAULT_NARRATOR_PLAYER_VOLUME: float = 8.0

const MAX_SPAWNED_OBJECTS: int = 200

const RANDOMS_ARRAY_AMOUNT: int = 64

const L2D_MOTION_IDLE: String = "Idle"
const L2D_MOTION_TALKING: String = "Talking"
const L2D_MOTION_LISTENING: String = "Listening"
const L2D_MOTION_PUNCH: String = "Punch"
const L2D_MOTION_SING: String = "Singing"
const L2D_MOTION_NONO: String = "Nono"

const L2D_ANIMATIONS: Dictionary = {
    L2D_MOTION_IDLE: 1,
    L2D_MOTION_TALKING: 1,
    L2D_MOTION_LISTENING: 0,
    L2D_MOTION_PUNCH: 0,
    L2D_MOTION_SING: 0,
    L2D_MOTION_NONO: 0,
}

const L2D_EXPR_NEUTRAL = "Neutral"
const L2D_EXPR_COW = "Cow"
const L2D_EXPR_ANGRY = "Angry"
const L2D_EXPR_FURIOUS = "Furious"
const L2D_EXPR_SAD = "Sad"
const L2D_EXPR_BLUSHING = "Blushing"
const L2D_EXPR_HAPPY = "Happy"
const L2D_EXPR_DISTURBED = "Disturbed"
const L2D_EXPR_SCARED = "Scared"
const L2D_EXPR_SMUG = "Smug"

const L2D_EXPRESSIONS: Dictionary = {
    L2D_EXPR_NEUTRAL : {},
    L2D_EXPR_COW: {
        "CowToggle": 1.0
    },
    L2D_EXPR_FURIOUS: {
        "ParamEyeLOpen": 0.4,
        "ParamEyeROpen": 0.4,
        "ParamEyeLSmile": 0.15,
        "ParamEyeRSmile": 0.15,
        "ParamMouthForm": -1.0,
        "angry": 1.0
    },
    L2D_EXPR_ANGRY: {
        "ParamEyeLOpen": 0.55,
        "ParamEyeROpen": 0.55,
        "ParamEyeLSmile": 0.2,
        "ParamEyeRSmile": 0.2,
        "ParamMouthForm": -0.55,
        "angry": 0.5
    },
    L2D_EXPR_BLUSHING: {
        "blushing": 1.0
    },
    L2D_EXPR_HAPPY: {
        "ParamEyeLSmile": 0.75,
        "ParamEyeRSmile": 0.75,
        "ParamEyeLOpen": 0.8,
        "ParamEyeROpen": 0.8,
    },
    L2D_EXPR_SAD: {
        "crying": 1.0,
        "ParamMouthForm": -0.25
    },
    L2D_EXPR_DISTURBED: {
        "eyesize": 0.65,
        "ParamEyeLSmile": 0.75,
        "ParamEyeRSmile": 0.75,
    },
    L2D_EXPR_SCARED: {
        "eyesize": 0.85,
        "ParamEyeLSmile": 1.0,
        "ParamEyeRSmile": 1.0,
        "ParamMouthForm": -0.25,
    },
    L2D_EXPR_SMUG: {
        "ParamEyeLOpen": 0.35,
        "ParamEyeROpen": 0.35,
        "ParamMouthForm": 0.65,
    }
}


# REFS -------------------------------------------------------------------------
@onready var ref_staticcameras: Node3D = $"StaticCameras"
@onready var ref_pointsofinterest: Node3D = $"PointsOfInterest"
@onready var ref_trackingcameras: Node3D = $"TrackingCameras"
@onready var ref_hildas: Node3D = $"NavigationRegion3D/Hildas"
@onready var ref_voiceplayer: AudioStreamPlayer = $"Sound/VoicePlayer"
@onready var ref_narratorplayer: AudioStreamPlayer = $"Sound/NarratorPlayer"
@onready var ref_soundeffectplayer: AudioStreamPlayer = $"Sound/SoundEffectPlayer"
@onready var ref_wsmanager: WebSocketManager = $"WebSocketManager"
@onready var ref_emotemanager: TwitchEmotesManager = $"TwitchEmotesManager"
@onready var ref_subtitles: Subtitles = $"HUD/CanvasLayer/Subtitles"
@onready var ref_twitchchat: TwitchChat = $"HUD/CanvasLayer/TwitchChat"
@onready var ref_spawnedobjects: Node3D = $"SpawnedObjects"
@onready var ref_hud2D: CanvasLayer = $"HUD/CanvasLayer"
@onready var ref_initscreentv: Node3D = $"Props/TVPhysicsBody/TV3D"
@onready var ref_hud_statusbar: StatusBar = $"HUD/CanvasLayer/StatusBar"
@onready var ref_nukescene: NukeScene = $"NukeScene"
@onready var ref_live2d: GDCubismUserModel = $"HUD/CanvasLayer/Simple/Sprite2D/GDCubismUserModel"
@onready var ref_live2d_lipsync: GDCubismLipSync = $"HUD/CanvasLayer/Simple/Sprite2D/GDCubismUserModel/GDCubismEffectCustom"
@onready var ref_live2d_reset: GDCubismCustomBlink = $"HUD/CanvasLayer/Simple/Sprite2D/GDCubismUserModel/GDCubismEffectCustom2"
@onready var ref_live2d_toggles: GDCubismCustomToggle = $HUD/CanvasLayer/Simple/Sprite2D/GDCubismUserModel/GDCubismEffectCustom3
@onready var ref_fpscounter: Label = $"HUD/CanvasLayer/FpsCounter"
@onready var ref_popup: Control = $"HUD/CanvasLayer/Popup"
@onready var ref_backgroundsing = $"HUD/CanvasLayer/SpectrogramVizu"
@onready var ref_spinningwheel = $"HUD/CanvasLayer/SpinningWheel"


# VARS -------------------------------------------------------------------------
var current_cam: Camera3D = null
var current_hilda: Hilda = null
var current_scene: Scene = null
var current_speak_id: String = ""
var current_user: String = "w-AI-fu_DEV"
var spawned_objects: Array[Node3D] = []
var scene_change_cooldown: float = 0.0
var current_l2d_anime: String = ""
var last_l2d_variant: int = 999
var fps_counter_refresh_cooldown: float = 0.0

var randoms_array: Array[float] = []
var random_index: int = RANDOMS_ARRAY_AMOUNT

var cow_redeem_cooldown: float = 0.0
var threed_redeem_cooldown: float = 0.0
var temporary_l2d_expr: Array[String] = []
var persistent_l2d_expr: Array[String] = []

var global_script_vars: Dictionary = {
    "PREVSCENE": "",
    "SCENE": "",
}

var cached_sound_effects: Dictionary = {
    "HitMarker": loadAudioStream("res://Audio/hitmarker.mp3"),
    "Nuke": loadAudioStream("res://Audio/nuke.wav", 48000, true),
    "Blank": loadAudioStream("res://Audio/blank.mp3"),
}

var timestamp: int = 0

# CODE -------------------------------------------------------------------------
func _ready()-> void:
    ref_hud2D.visible = false
    _initRandomsArray(randoms_array)
    _initializeSceneAnimations()
    setCurrentScene(SCENE_INIT)
    ref_live2d.assets = "res://Live2DHilda/HildaV.model3.json"
    setLive2dAnimationLoop(L2D_MOTION_IDLE)
    hideLive2dModel()
    if (!flag_display_chat): hideTwitchChat()


func _process(delta: float)-> void:
    timestamp = Time.get_unix_time_from_system()

    if _isFinishedPlayingPadded(VOICE_PADDING_END) && current_speak_id.length():
        if current_l2d_anime == L2D_MOTION_SING:
            ref_backgroundsing.visible = false
            setLive2dAnimationLoop(L2D_MOTION_IDLE)
        stopAudioStreams()
        setFinishedSpeaking()

    if current_speak_id.length() && ref_voiceplayer.playing && ref_narratorplayer.playing:
        handleSongDesync()

    ref_spinningwheel.rotation_degrees += delta * 25.0

    if flag_auto_scene_switching:
        scene_change_cooldown += delta
        if scene_change_cooldown > AUTO_SCENE_CHANGE_COOLDOWN:
            var next_scene = AUTO_SCENES[_pickRdmIndex(AUTO_SCENES)]
            if next_scene != global_script_vars["SCENE"]:
                setCurrentScene(next_scene)

    fps_counter_refresh_cooldown += delta
    if fps_counter_refresh_cooldown > 1.0:
        fps_counter_refresh_cooldown = 0.0
        _setFpsCounter()

    if cow_redeem_cooldown > 0.0:
        cow_redeem_cooldown -= delta
        if cow_redeem_cooldown <= 0.0:
            unsetLive2dExpr(L2D_EXPR_COW)

    if threed_redeem_cooldown > 0.0:
        threed_redeem_cooldown -= delta
        if threed_redeem_cooldown <= 0.0:
            displayLive2dModel()
            current_hilda.visible = false

    if Input.is_action_just_pressed("scene_01"):
        print("WORLD::SCENE: START")
        setCurrentScene(SCENE_START)
    elif Input.is_action_just_pressed("scene_02"):
        print("WORLD::SCENE: NONE")
        setCurrentScene(SCENE_NONE)
    elif Input.is_action_just_pressed("scene_03"):
        print("WORLD::SCENE: ORTHO")
        setCurrentScene(SCENE_ORTHO)
    elif Input.is_action_just_pressed("scene_04"):
        print("WORLD::SCENE: TRACKING")
        setCurrentScene(SCENE_TRACKING)
    elif Input.is_action_just_pressed("scene_05"):
        print("WORLD::SCENE: REACT")
        setCurrentScene(SCENE_REACT)
    elif Input.is_action_just_pressed("scene_06"):
        print("WORLD::SCENE: CONCERT")
        setCurrentScene(SCENE_CONCERT)
    elif Input.is_action_just_pressed("spawn_object"):
        print("WORLD::THROW")
        current_hilda.spawnMultipleObjects(50)
    elif Input.is_action_just_pressed("test_feature"):
        print("WOLRD::TESTFEATURE")
        ref_nukescene.start()


func _isFinishedPlayingPadded(end_padding: float)-> bool:
    if !ref_voiceplayer.playing && !ref_narratorplayer.playing:
        return true
    if ref_voiceplayer.playing:
        return ref_voiceplayer.get_playback_position() \
            > (ref_voiceplayer.stream.get_length() - end_padding)
    if ref_narratorplayer.playing:
        return ref_narratorplayer.get_playback_position() \
            > (ref_narratorplayer.stream.get_length() - end_padding)
    return false


func setCurrentScene(scene_name: String)-> void:
    scene_change_cooldown = 0.0
    if current_scene:
        global_script_vars["PREVSCENE"] = current_scene.scene_name
        await current_scene.fn_end_anim.call()
    global_script_vars["SCENE"] = scene_name
    var scene: Scene = ScenesDict[scene_name]
    if !scene: return
    setCurrentHilda(scene.hilda, scene.camera.is_empty())
    if scene.camera.length():
        setCurrentCamera(scene.camera)
    scene.fn_start_anim.call()
    current_scene = scene
    scene_change_cooldown = 0.0


func resetSceneCamera()-> void:
    var scene_name = global_script_vars["SCENE"]
    var scene: Scene = ScenesDict[scene_name]
    if !scene: return
    setCurrentHilda(scene.hilda, scene.camera.is_empty())
    if scene.camera.length():
        setCurrentCamera(scene.camera)


func setCurrentCamera(camera_name: String)-> void:
    var nodes: Array[Node] = ref_staticcameras.get_children()
    var i: int = nodes.size()
    while i:
        i -= 1
        var camera: Camera3D = nodes[i] as Camera3D
        if camera.name != camera_name:
            camera.current = false
        else:
            current_cam = camera
            camera.current = true

    nodes = ref_trackingcameras.get_children()
    i = nodes.size()
    while i:
        i -= 1
        var camera: Camera3D = nodes[i] as Camera3D
        if camera.name != camera_name:
            camera.current = false
        else:
            current_cam = camera
            camera.current = true


func _initializeSceneAnimations()-> void:
    var scene_init: Scene = ScenesDict[SCENE_INIT]
    scene_init.fn_start_anim = func():
        ($"StaticCameras/TVSceneCamera" as TVSceneCamera).start()

    var scene_ortho: Scene = ScenesDict[SCENE_ORTHO]
    scene_ortho.fn_start_anim = func():
        displayLive2dModel()
#        current_hilda.setActionScript("scene_ortho_start", [
#            ActionScript.Teleport(9.0, 45.8, -1.0),
#            ActionScript.Fly(0.435, 45.8, -1.0),
#            ActionScript.Rotate(0.0, 0.0, 0.0),
#        ])
    scene_ortho.fn_end_anim = func():
        hideLive2dModel()
#        current_hilda.setActionScript("scene_ortho_end", [
#            ActionScript.Rotate(0.0, 90.0, 0.0),
#            ActionScript.Fly(9.0, 45.8, -1.0),
#        ])
#        await current_hilda.finished_script

    var scene_start: Scene = ScenesDict[SCENE_START]
    scene_start.fn_start_anim = func():
        current_hilda.setActionScript("scene_start_start", [
            ActionScript.Teleport(-21.63, 0.9, -4.0),
            ActionScript.Fly(-15.248, 0.85, -13.8),
            ActionScript.Rotate(0.0, -123.5, 0.0),
            ActionScript.Wait(0.25),
            ActionScript.Animate("SitStartScreen"),
            ActionScript.Wait(1),
            ActionScript.Cam("StartingScreenCamera2"),
            ActionScript.Wait(1),
            ActionScript.Cam("StartingScreenCamera3"),
            ActionScript.Wait(1),
            ActionScript.Cam("StartingScreenCamera"),
        ])
    scene_start.fn_end_anim = func():
        current_hilda.setActionScript("scene_start_end", [
            ActionScript.Rotate(0.0, -123.5, 0.0),
            ActionScript.Animate("Waiting"),
            ActionScript.Wait(0.75),
            ActionScript.Face(-21.63, 0.9, -4.0),
            ActionScript.Fly(-21.63, 0.9, -4.0),
        ])
        await current_hilda.finished_script

    var scene_none: Scene = ScenesDict[SCENE_NONE]
    scene_none.fn_start_anim = func():
        current_hilda.setActionScript("scene_none_start", [
            ActionScript.Compare("$PREVSCENE", "Tracking"),
            ActionScript.GotoIfNotEqual("not_tracking"),
            ActionScript.Return(),
            ActionScript.Label("not_tracking"),
            ActionScript.Compare("$PREVSCENE", "None"),
            ActionScript.GotoIfNotEqual("not_tracking_and_not_none"),
            ActionScript.Return(),
            ActionScript.Label("not_tracking_and_not_none"),
            ActionScript.Compare("$PREVSCENE", "Orthogonal"),
            ActionScript.GotoIfNotEqual("not_ortho"),
            ActionScript.Teleport(0.95, 0.9, 71.65),
            ActionScript.Animate("WalkingSelfie"),
            ActionScript.Fly(0.95, 0.9, 44.75),
            ActionScript.Face(-7.2, 0.9, 31.7),
            ActionScript.Fly(-7.2, 0.9, 31.7),
            ActionScript.Return(),
            ActionScript.Label("not_ortho"),
            ActionScript.Teleport(-21.63, 0.9, -4.0),
            ActionScript.Animate("WalkingSelfie"),
            ActionScript.Fly(-21.63, 0.9, 8.0),
            ActionScript.PathToPoi("BigRedButton")
        ])

    var scene_tracking: Scene = ScenesDict[SCENE_TRACKING]
    scene_tracking.fn_start_anim = scene_none.fn_start_anim

    var scene_react: Scene = ScenesDict[SCENE_REACT]
    scene_react.fn_start_anim = func():
        $"Props/GreenScreen".visible = true
        $"Props/desk2".visible = true
    scene_react.fn_end_anim = func():
        $"Props/GreenScreen".visible = false
        $"Props/desk2".visible = false


func setCurrentHilda(hilda_name: String, use_camera: bool = false)-> void:
    var nodes: Array[Node] = ref_hildas.get_children()
    var i: int = nodes.size()
    while i:
        i -= 1
        var hild: Hilda = nodes[i] as Hilda
        if hild.name != hilda_name:
            hild.unsetCurrent()
        else:
            current_hilda = hild
            hild.setCurent(use_camera, global_script_vars["SCENE"] != SCENE_ORTHO)


func setFinishedSpeaking()-> void:
    if !current_speak_id.length(): return
    var packet: String = ref_wsmanager.PACKET_SEPARATOR.join(["f", current_speak_id])
    ref_wsmanager.sendPacket(packet)
    current_speak_id = ""


func validateMp3(bytes: PackedByteArray) -> bool:
    var header: String = bytes.get_string_from_ascii().substr(0, 3)
    if header == "ID3":
        return true
    if bytes.size() > 2 and (bytes[0] == 0xFF and (bytes[1] & 0xE0) == 0xE0):
        return true
    return false


func loadAudioStream(path: String, wav_mix_rate: int = 40000, wav_stereo: bool = false)-> AudioStream:
    if !FileAccess.file_exists(path):
        printerr("VOICE::ERR: File does not exist: ", path)
        return null

    var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
    if bytes.size() == 0:
        printerr("VOICE::ERR: Could not open voice file or file is empty: ", path)
        return null

    var audio: AudioStream
    if path.ends_with(".wav"):
        audio = AudioStreamWAV.new()
        audio.data = bytes
        audio.mix_rate = wav_mix_rate
        audio.format = AudioStreamWAV.FORMAT_16_BITS
        audio.stereo = wav_stereo
    elif path.ends_with(".mp3"):
        if !validateMp3(bytes):
            printerr("VOICE::ERR: Invalid MP3 file: ", path)
            return null
        audio = AudioStreamMP3.new()
        audio.data = bytes
    else:
        printerr("VOICE::ERR: Unsupported audio format: ", path)
        return null
    return audio


func setVoice(id: String, path: String)-> void:
    #setFinishedSpeaking()
    current_speak_id = id
    ref_voiceplayer.stream = loadAudioStream(path)
    ref_voiceplayer.play(VOICE_PADDING_START)


func setNarrator(id: String, path: String)-> void:
    #setFinishedSpeaking()
    current_speak_id = id
    ref_narratorplayer.stream = loadAudioStream(path)
    ref_narratorplayer.play(VOICE_PADDING_START)


func setSoundEffect(effect_name: String)-> void:
    ref_soundeffectplayer.stream = cached_sound_effects[effect_name] as AudioStream
    ref_soundeffectplayer.play(0.0)


func interruptSound()-> void:
    stopAudioStreams()
    setFinishedSpeaking()


func setSong(id: String, path_voc: String, path_inst: String)-> void:
    current_speak_id = id
    var voc_stream = loadAudioStream(path_voc, 44100, true)
    var inst_stream = loadAudioStream(path_inst, 44100, true)
    ref_voiceplayer.stream = voc_stream
    ref_narratorplayer.stream = inst_stream
    ref_voiceplayer.volume_db = 0.0
    ref_narratorplayer.volume_db = 0.0
    ref_voiceplayer.play(0.0)
    ref_narratorplayer.play(0.0)


func getPoiRefByName(poi_name: String)-> Node3D:
    return ref_pointsofinterest.get_node_or_null(poi_name)


func addSpawnedObject(obj: Node3D)-> void:
    spawned_objects.push_back(obj)
    ref_spawnedobjects.add_child(obj)
    cullOverflowSpawnedObjects()


func cullOverflowSpawnedObjects()-> void:
    var i: int = spawned_objects.size()
    while i > MAX_SPAWNED_OBJECTS:
        i -= 1
        var obj: Node3D = spawned_objects.pop_front() as Node3D
        ref_spawnedobjects.remove_child(obj)
        obj.queue_free()


func displayStatusMessage(text:String)-> void:
    ref_hud_statusbar.displayStatus(text)


## randf() but faster
func _randf()-> float:
    random_index = random_index - 1 if random_index else RANDOMS_ARRAY_AMOUNT - 1
    return randoms_array[random_index]


func _pickRdmIndex(list: Array)-> int:
    return floori(list.size() * _randf())


## Initializes an array of random numbers, faster than using randf()
## Use those random numbers using _randf()
func _initRandomsArray(array: Array[float])-> void:
    if array.resize(RANDOMS_ARRAY_AMOUNT): return
    var i: int = RANDOMS_ARRAY_AMOUNT
    while i:
        i -= 1
        array[i] = randf()


func setLive2dAnimationLoop(animation: String)-> void:
    current_l2d_anime = animation
    var rdm_variant: int = getNextRandomVariant(animation)
    ref_live2d.start_motion(animation, rdm_variant, GDCubismUserModel.PRIORITY_FORCE)

    for connection in ref_live2d.motion_finished.get_connections():
        ref_live2d.motion_finished.disconnect(connection["callable"])
    ref_live2d.motion_finished.connect(setLive2dAnimationLoop.bind(current_l2d_anime))


func setLive2DAnimationTemp(animation: String)-> void:
    var rdm_variant: int = getNextRandomVariant(animation)
    ref_live2d.start_motion(animation, rdm_variant, GDCubismUserModel.PRIORITY_FORCE)
    await ref_live2d.motion_finished
    setLive2dAnimationLoop(current_l2d_anime)


func setLive2dExpr(expr: String)-> void:
    ref_live2d_toggles.setToggle(expr)


func unsetLive2dExpr(expr: String)-> void:
    ref_live2d_toggles.unToggle(expr)


func setTemporaryLive2dExprs(exprs: Array[String])-> void:
    for expr in temporary_l2d_expr:
        unsetLive2dExpr(expr)
    temporary_l2d_expr.clear()
    for expr in exprs:
        temporary_l2d_expr.append(expr)
        setLive2dExpr(expr)


func getNextRandomVariant(animation: String)-> int:
    print("ANIM:", animation)
    var variants = L2D_ANIMATIONS[animation]
    var rdm_variant = roundi(_randf() * variants)
    while variants > 0 and rdm_variant == last_l2d_variant:
        rdm_variant = roundi(_randf() * variants)
    last_l2d_variant = rdm_variant
    return rdm_variant


func displayLive2dModel()-> void:
    ref_live2d.get_parent().visible = true


func hideLive2dModel()-> void:
    ref_live2d.get_parent().visible = false


func stopAudioStreams()-> void:
    ref_voiceplayer.volume_db = DEFAULT_VOICE_PLAYER_VOLUME
    ref_narratorplayer.volume_db = DEFAULT_NARRATOR_PLAYER_VOLUME
    ref_voiceplayer.stop()
    ref_narratorplayer.stop()


func displayTwitchChat()-> void:
    if (!flag_display_chat): return
    ref_twitchchat.visible = true
    $"HUD/CanvasLayer/TwitchChatBG1".visible = true
    $"HUD/CanvasLayer/TwitchChatBG2".visible = true
    $"HUD/CanvasLayer/TwitchChatBG3".visible = true
    $"HUD/CanvasLayer/StatusBar".visible = true
    $"HUD/CanvasLayer/Label".visible = true
    $"HUD/CanvasLayer/TextureRect".visible = true


func hideTwitchChat()-> void:
    ref_twitchchat.visible = false
    $"HUD/CanvasLayer/TwitchChatBG1".visible = false
    $"HUD/CanvasLayer/TwitchChatBG2".visible = false
    $"HUD/CanvasLayer/TwitchChatBG3".visible = false
    $"HUD/CanvasLayer/StatusBar".visible = false
    $"HUD/CanvasLayer/Label".visible = false
    $"HUD/CanvasLayer/TextureRect".visible = false


func _setFpsCounter()-> void:
    ref_fpscounter.text = str(Engine.get_frames_per_second())


func displayPopup(text: String, font_size: int, display_time: float, callback: Callable)-> void:
    var label: Label = ref_popup.get_child(1).get_child(0)
    label.text = text
    label.set("theme_override_font_sizes/font_size", font_size)
    ref_popup.visible = true
    var timer = Timer.new()
    add_child(timer)
    timer.start(display_time)
    await timer.timeout
    remove_child(timer)
    timer.queue_free()
    ref_popup.visible = false
    callback.call()


func handleSongDesync()-> void:
    const THRESH = 0.05
    # Get the current playback positions
    var pos1 = ref_voiceplayer.get_playback_position()
    var pos2 = ref_narratorplayer.get_playback_position()

    # Calculate the difference
    var desync = abs(pos1 - pos2)

    # If desynchronized beyond the threshold, correct it
    if desync > THRESH:
        # Adjust the playback position of the lagging player
        if pos1 > pos2:
            ref_narratorplayer.seek(pos1)
        else:
            ref_voiceplayer.seek(pos2)
