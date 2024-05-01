class_name Hilda extends Node3D
## Script responsible for the movements, animations of Hilda
## @author: DEV
## @date: 2024-03-05


# CONSTANTS --------------------------------------------------------------------
const WALK_SPEED: float =               10.0
const ROTATION_SPEED: float =           3.0
const SLOW_ROTATION_SPEED: float =      1.5

const BLINK_RATE_MAX_MS: float =        2_000.0
const BLINK_DURATION_MS: float =        250.0

const RANDOMS_ARRAY_AMOUNT: int =       64

const MOUTH_CHANGE_RATE_MS: float =     50.0
const VOLUME_LOW_THRESHOLD: float =     0.01
const VOLUME_MID_THRESHOLD: float =     0.05
const VOLUME_HIGH_THRESHOLD: float =    1

const FREQUENCY_MIN: int =              0
const FREQUENCY_MAX: int =              10_000
const FREQUENCY_LOW_THRESHOLD: int =    300
const FREQUENCY_MID_THRESHOLD: int =    600
const FREQUENCY_HIGH_THRESHOLD: int =   FREQUENCY_MAX

const ANIM_TPOSE: String =      "Default"
const ANIM_IDLE: String =       "Idle"
const ANIM_TALKING: String =    "Talking"
const ANIM_TALKING2: String =    "Talking2"
const ANIM_WALKING: String =    "Walking"
const ANIM_WLK_SELFIE: String = "WalkingSelfie"
const ANIM_WAITING: String =    "Waiting"
const ANIM_SIT: String =        "Sit"
const ANIM_SIT_DOWN: String =   "SitDown"
const ANIM_SIT_TALK: String =   "SitTalk"
const ANIM_STARTSCRN: String =  "SitStartScreen"
const ANIM_PUNCH: String =      "Punch"
const ANIM_PUNCH_ORTH: String = "PunchOrtho"
const ANIM_LISTENING: String =  "Listening"
const ANIM_LISTENING2: String = "Listening2"

const LIST_ANIM_TALKING: PackedStringArray= [
    ANIM_TALKING,
    ANIM_TALKING2,
]

const LIST_ANIM_LISTENING: PackedStringArray = [
    ANIM_LISTENING,
    ANIM_LISTENING2,
]

const MAX_ANIMATION_QUEUE: int = 50
const ANIMATION_BLEND_TIME: float = 1.0

const THROW_OBJECT_VELOCITY: float = 75.0
const MAX_THROW_PER_FRAME: int = 1
const THROW_TARGET_DISTORTION: float = 3.0
const BALD_COOLDOWN: float = 45.0


# ENUMS ------------------------------------------------------------------------
enum Frequency {LOW, MID, HIGH}
enum MouthType {CLOSED, SLIGHT, LARGE, LARGELOW, SLIGHTLOW}
enum Position {STANDING, WALKING, SITTING}


# EXPORTED VARS ----------------------------------------------------------------
@export_group("")
@export var id: String = ""
@export_enum(
    ANIM_TPOSE, ANIM_IDLE, ANIM_TALKING,
    ANIM_WALKING, ANIM_WLK_SELFIE, ANIM_WAITING,
    ANIM_SIT, ANIM_SIT_DOWN, ANIM_SIT_TALK,
    ANIM_STARTSCRN, ANIM_PUNCH, ANIM_PUNCH_ORTH,
) var default_anim: String = ANIM_IDLE
@export var action_script: Array[String] = []

@export_group("Flags")
@export var flag_is_current: bool = false
@export var flag_use_camera: bool = false
@export var flag_is_static: bool = false
@export var flag_is_visible: bool = false
@export var flag_use_front_light: bool = true


# REFERENCES -------------------------------------------------------------------
var ref_world: World = null
@onready var ref_animplayer: AnimationPlayer = $"AnimationPlayer" as AnimationPlayer
@onready var ref_frontcam: Camera3D = $"Armature/Skeleton3D/BoneAttachment3D/Camera3D" as Camera3D
@onready var ref_spectrum: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1, 0) as AudioEffectSpectrumAnalyzerInstance
@onready var ref_navagent: NavigationAgent3D = $"NavigationAgent3D"

@onready var ref_face_eyes: MeshInstance3D = $"Armature/Skeleton3D/Face00" as MeshInstance3D
@onready var ref_face_blink: MeshInstance3D = $"Armature/Skeleton3D/Face00_1" as MeshInstance3D
@onready var ref_face_mouth_closed: MeshInstance3D = $"Armature/Skeleton3D/Face01" as MeshInstance3D
@onready var ref_face_mouth_slight: MeshInstance3D = $"Armature/Skeleton3D/Face02" as MeshInstance3D
@onready var ref_face_mouth_large: MeshInstance3D = $"Armature/Skeleton3D/Face03" as MeshInstance3D
@onready var ref_face_mouth_large_low: MeshInstance3D = $"Armature/Skeleton3D/Face04" as MeshInstance3D
@onready var ref_face_mouth_slight_low: MeshInstance3D = $"Armature/Skeleton3D/Face05" as MeshInstance3D

@onready var ref_throw_pivot: Node3D = $"Armature/Skeleton3D/BoneAttachment3D2/ThrowSpawner"
@onready var ref_throw_spawner: Node3D = $"Armature/Skeleton3D/BoneAttachment3D2/ThrowSpawner/ThrowSpawnerSpawPoint"
@onready var ref_template_throw_object: RigidBody3D = $"Armature/Skeleton3D/BoneAttachment3D2/ThrowSpawner/ThrowSpawnerSpawPoint/TemplateThrowObject"


# VARS -------------------------------------------------------------------------
var blink_threshold: float = BLINK_RATE_MAX_MS
var blink_accumulator: float = 0.0
var blink_cooldown: float = 0.0
var last_mouth: MouthType = MouthType.CLOSED
var mouth_cooldown: float = 0.0
var randoms_array: Array[float] = []
var random_index: int = RANDOMS_ARRAY_AMOUNT
var current_animation: String = default_anim
var current_position: Position = Position.STANDING
var current_instruction = null
var instruction_ptr: int = 0
var last_instruction_ptr: int = -1
var instruction_args: Array = []
var local_script_vars: Dictionary = {
    "CMP": false,
}
var wait_cooldown: float = 0.0
var bald_cooldown: float = 0.0
var rgx_only_alphanum: RegEx = RegEx.create_from_string("[^a-z0-9/]")


# SIGNALS ----------------------------------------------------------------------
signal finished_script


# CODE -------------------------------------------------------------------------
func _ready()-> void:
    ref_world = get_tree().current_scene as World
    _initRandomsArray(randoms_array)
    self.visible = flag_is_visible
    if !flag_use_front_light:
        $"Armature/Skeleton3D/BoneAttachment3D/SpotLight3D".visible = false
        $"Armature/Skeleton3D/BoneAttachment3D/SpotLight3D2".visible = false
    if flag_is_current: ref_frontcam.current = true
    ref_animplayer.playback_default_blend_time = ANIMATION_BLEND_TIME
    current_animation = default_anim
    ref_animplayer.current_animation = default_anim


func _process(delta: float)-> void:
    if !flag_is_visible: return
    var delta_ms: float = delta * 1_000.0
    _handleBlink(delta_ms)
    _handleLipSync(delta_ms)
    if _canHandleScript():
        _handleScript(delta)
    _handleBaldness(delta)


func _canHandleScript()-> bool:
    return action_script.size() || current_instruction


## Advances the script to the next instruction.
## Next instruction will be stored in `current_instruction`.
## `current_instruction` will be null if no new instructions found.
func _advanceScript()-> void:
    if !action_script.size():
        current_instruction = null
        finished_script.emit()
        return
    var inst: String = action_script.pop_front()
    var split_inst: PackedStringArray = inst.split(" ")
    instruction_args.clear()
    current_instruction = split_inst[0]

    instruction_ptr += 1
    match current_instruction:
        ActionScript.INST_TP,\
        ActionScript.INST_FLY,\
        ActionScript.INST_ROT,\
        ActionScript.INST_PATH,\
        ActionScript.INST_FACE:
            if split_inst.size() < 4: return
            instruction_args.push_back(float(split_inst[1]))
            instruction_args.push_back(float(split_inst[2]))
            instruction_args.push_back(float(split_inst[3]))
        ActionScript.INST_ANIM,\
        ActionScript.INST_LABEL,\
        ActionScript.INST_GOTO,\
        ActionScript.INST_GTNE,\
        ActionScript.INST_PATHTOPOI,\
        ActionScript.INST_CAM:
            if split_inst.size() < 2: return
            instruction_args.push_back(split_inst[1])
        ActionScript.INST_WAIT:
            if split_inst.size() < 2: return
            instruction_args.push_back(float(split_inst[1]))
        ActionScript.INST_CMP:
            if split_inst.size() < 3: return
            instruction_args.push_back(split_inst[1])
            instruction_args.push_back(split_inst[2])
        ActionScript.INST_JNE, ActionScript.INST_JMP:
            if split_inst.size() < 2: return
            instruction_args.push_back(int(split_inst[1]))
        ActionScript.INST_RET:
            if split_inst.size() < 1: return
        _:
            printerr("SCRIPT::ADVANCE: Unsupported instruction %s." % current_instruction)
            current_instruction = null


## Handles script instructions.
## Multiple instructions can be handled each frame depending on the type of instruction
## Instructions for character movement will most likely take multiple frames to finish
## signal `finished_script` is emited once the script is finished
func _handleScript(delta: float)-> void:
    var done: bool
    if !current_instruction:
        _advanceScript()
    if last_instruction_ptr != instruction_ptr:
        var args_str: String = ""
        for item in instruction_args:
            args_str += "%s " % str(item)
        print("SCRIPT::CALL: %s %s %s" % [str(instruction_ptr).pad_zeros(3), current_instruction, args_str])
    match current_instruction:
        ActionScript.INST_TP:
            teleportTo(Vector3(instruction_args[0], instruction_args[1], instruction_args[2]))
            done = true
        ActionScript.INST_FACE:
            var dir = transform.looking_at(Vector3(instruction_args[0], instruction_args[1], instruction_args[2]), Vector3(0, 1, 0), true)
            var angle = dir.basis.get_euler()
            #angle.x = rad_to_deg(angle.x)
            angle.y = rad_to_deg(angle.y)
            #angle.z = rad_to_deg(angle.z)
            #done = _faceTowards(delta, Vector3(instruction_args[0], instruction_args[1], instruction_args[2]))
            done = _rotateTowards(delta, angle, ROTATION_SPEED)
        ActionScript.INST_FLY:
            done = _flyTowards(delta, Vector3(instruction_args[0], instruction_args[1], instruction_args[2]))
        ActionScript.INST_PATH:
            done = _pathTowards(delta, Vector3(instruction_args[0], instruction_args[1], instruction_args[2]))
        ActionScript.INST_PATHTOPOI:
            done = _pathTowardsPOI(delta, instruction_args[0])
        ActionScript.INST_ROT:
            done = _rotateTowards(delta, Vector3(instruction_args[0], instruction_args[1], instruction_args[2]), ROTATION_SPEED)
        ActionScript.INST_ANIM:
            setAnimation(instruction_args[0])
            done = true
        ActionScript.INST_WAIT:
            if wait_cooldown <= 0.0:
                wait_cooldown = instruction_args[0]
            wait_cooldown -= delta
            done = wait_cooldown < 0.0
        ActionScript.INST_CMP:
            var x = instruction_args[0]\
                    if !_isVariableName(instruction_args[0])\
                    else _fetchScriptVar(instruction_args[0])
            var y = instruction_args[1]\
                    if !_isVariableName(instruction_args[1])\
                    else _fetchScriptVar(instruction_args[1])
            local_script_vars["CMP"] = x == y
            done = true
        ActionScript.INST_JNE:
            var cmp: bool = local_script_vars["CMP"]
            var skip: int = instruction_args[0]
            while skip && !cmp:
                skip -= 1
                _advanceScript()
            done = true
        ActionScript.INST_JMP:
            var skip: int = instruction_args[0]
            while skip:
                skip -= 1
                _advanceScript()
            done = true
        ActionScript.INST_RET:
            while current_instruction != null:
                _advanceScript()
            done = true
        ActionScript.INST_LABEL:
            done = true
        ActionScript.INST_GOTO:
            var label_name = instruction_args[0]
            while true:
                _advanceScript()
                if current_instruction == null: break
                if current_instruction == ActionScript.INST_LABEL && label_name == instruction_args[0]:
                    break
            done = true
        ActionScript.INST_GTNE:
            var cmp: bool = local_script_vars["CMP"]
            var label_name: String = instruction_args[0]
            while !cmp:
                _advanceScript()
                if current_instruction == null: break
                if current_instruction == ActionScript.INST_LABEL && label_name == instruction_args[0]:
                    break
            done = true
        ActionScript.INST_CAM:
            var cam_name: String = instruction_args[0]
            ref_world.setCurrentCamera(cam_name)
            done = true
        _:
            printerr("SCRIPT::HANDLE: Unsupported instruction %s." % current_instruction)
            done = true
    if done:
        _advanceScript()
        if _canHandleScript():
            _handleScript(delta)
    else:
        last_instruction_ptr = instruction_ptr


## Moves Hilda towards destination by delta
func _flyTowards(delta: float, dest: Vector3, face_towards: bool = true)-> bool:
    setWalkAnimation()
    if face_towards:
        faceTowards(dest)

    var norm_dir = global_position.direction_to(dest)

    var amount = WALK_SPEED * delta
    global_position.x += norm_dir.x * amount
    global_position.y += norm_dir.y * amount
    global_position.z += norm_dir.z * amount

    if _vecCmp(global_position, dest, 0.1):
        setWaitingAnimation()
        return true
    return false


func _faceTowards(delta: float, to: Vector3)-> bool:
    var pos2d = Vector2(global_position.x, global_position.z)
    var towards2d = Vector2(to.x, to.z)

    var angle = pos2d.angle_to_point(towards2d)
    rotation.y += rotate_toward(rotation.y, angle, delta)

    if _fltCmp(angle_difference(rotation.y, angle), 0.0, 0.01):
        return true
    return false


## Rotates Hilda towards angle by delta
func _rotateTowards(delta: float, to: Vector3, speed: float)-> bool:
    var amount = speed * delta
    var to_rad: Vector3 = Vector3(deg_to_rad(to.x), deg_to_rad(to.y), deg_to_rad(to.z))
    rotation.x = rotate_toward(rotation.x, to_rad.x, amount)
    rotation.y = rotate_toward(rotation.y, to_rad.y, amount)
    rotation.z = rotate_toward(rotation.z, to_rad.z, amount)
    return _arePara(rotation, to_rad)


## Responsible for the blinking of Hilda's eyes
func _handleBlink(delta_ms: float)-> void:
    if blink_cooldown > 0.0:
        blink_cooldown -= delta_ms
        if blink_cooldown <= 0.0: _blinkOpenEyes()
    else:
        blink_accumulator += delta_ms

    if blink_accumulator > blink_threshold:
        _resetBlinkAcc()
        _blinkCloseEyes()


## Responsible for the mouth movements of Hilda based on sound
func _handleLipSync(delta_ms: float)-> void:
    if mouth_cooldown > 0.0:
        mouth_cooldown -= delta_ms
    elif ref_world.ref_voiceplayer.playing:
        _lipSync(_getAudioVolume(), _getDominantFrequency())
    elif last_mouth != MouthType.CLOSED:
        _setMouth(MouthType.CLOSED)


func _resetBlinkAcc()-> void:
    blink_accumulator = 0.0
    blink_threshold = (_randf() + 0.5) * BLINK_RATE_MAX_MS
    blink_cooldown = (_randf() * 0.5 + 0.5) * BLINK_DURATION_MS


func _blinkOpenEyes()-> void:
    ref_face_eyes.visible = true
    ref_face_blink.visible = false


func _blinkCloseEyes()-> void:
    ref_face_eyes.visible = false
    ref_face_blink.visible = true


## Responsible for chosing the correct mouth based on volume and frequency
func _lipSync(volume: float, freq: float)-> void:
    ref_world.ref_live2d_lipsync.setMouthParams(volume * 7.5, (freq - 1.0) * 0.65)
    var mouth: MouthType
    if volume < VOLUME_LOW_THRESHOLD:
        mouth = MouthType.CLOSED
    elif volume < VOLUME_MID_THRESHOLD:
        mouth = MouthType.SLIGHTLOW \
                if freq == Frequency.LOW \
                else MouthType.SLIGHT
    else:
        mouth = MouthType.LARGELOW \
                if freq == Frequency.LOW \
                else MouthType.LARGE
    _setMouth(mouth)


## Sets mouth and unsets all the other mouths that are not active
func _setMouth(mouth: MouthType)-> void:
    mouth_cooldown += MOUTH_CHANGE_RATE_MS
    last_mouth = mouth
    ref_face_mouth_closed.visible = mouth == MouthType.CLOSED
    ref_face_mouth_slight.visible = mouth == MouthType.SLIGHT
    ref_face_mouth_large.visible = mouth == MouthType.LARGE
    ref_face_mouth_large_low.visible = mouth == MouthType.LARGELOW
    ref_face_mouth_slight_low.visible = mouth == MouthType.SLIGHTLOW


func _getMagnitude(from_hz: int, to_hz: int) -> float:
    return ref_spectrum.get_magnitude_for_frequency_range(from_hz, to_hz, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length()


## Returns the dominant frequency (HIGH, LOW) of the currently playing voice audio.
func _getDominantFrequency()-> Frequency:
    var low: float = _getMagnitude(FREQUENCY_MIN, FREQUENCY_LOW_THRESHOLD)
    var mid: float = _getMagnitude(FREQUENCY_LOW_THRESHOLD, FREQUENCY_MID_THRESHOLD)
    var high: float = _getMagnitude(FREQUENCY_MID_THRESHOLD, FREQUENCY_HIGH_THRESHOLD)
    if mid >= low && mid >= high: return Frequency.MID
    if high >= low && high >= mid: return Frequency.HIGH
    if low >= mid && low >= high: return Frequency.LOW
    return Frequency.LOW


func _dominantFreqToStr(freq: Frequency)-> String:
    match freq:
        Frequency.LOW: return "Low"
        Frequency.MID: return "Mid"
        Frequency.HIGH: return "High"
    return ""


func _getAudioVolume()-> float:
    return _getMagnitude(FREQUENCY_MIN, FREQUENCY_MAX)


func _framesToMs(frames: int)-> int:
    return int(float(frames) / 60.0 * 1_000.0)


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


## Sets the current animation for Hilda
func setAnimation(animation: String)-> void:
    current_animation = animation
    ref_animplayer.clear_queue()
    ref_animplayer.play(animation, ANIMATION_BLEND_TIME)


func setAnimationQueue(animations: PackedStringArray)-> void:
    current_animation = animations[0]
    ref_animplayer.clear_queue()
    ref_animplayer.play(animations[_pickRdmIndex(animations)], ANIMATION_BLEND_TIME)
    for i in range(MAX_ANIMATION_QUEUE):
        ref_animplayer.queue(animations[_pickRdmIndex(animations)])


## Plays a temporary animation, returns to current animation after having been played
func setTempAnimation(animation: String)-> void:
    ref_animplayer.animation_set_next(animation, current_animation)
    ref_animplayer.play(animation, ANIMATION_BLEND_TIME)


func setCurent(use_camera: bool = false, make_visible: bool = true)-> void:
    flag_is_current = true
    flag_is_visible = true
    self.visible = make_visible
    if use_camera:
        flag_use_camera = true
        ref_frontcam.current = true


func unsetCurrent()-> void:
    flag_is_current = false
    flag_is_visible = false
    self.visible = false


func setTalkingAnimation()-> void:
    ref_world.setLive2dAnimationLoop(ref_world.L2D_MOTION_TALKING)
    if current_animation == "SitStartScreen": return
    if current_animation.begins_with("Walk"): return
    if current_animation.begins_with("Sit"):
        setAnimation(ANIM_SIT_TALK)
        return
    setAnimationQueue(LIST_ANIM_TALKING)


func setIdleAnimation()-> void:
    ref_world.setLive2dAnimationLoop(ref_world.L2D_MOTION_IDLE)
    if current_animation == "SitStartScreen": return
    if current_animation.begins_with("Walk"): return
    if current_animation.begins_with("Sit"):
        setAnimation(ANIM_SIT)
        return
    setAnimation(ANIM_WAITING)


func setListeningAnimation()-> void:
    ref_world.setLive2dAnimationLoop(ref_world.L2D_MOTION_LISTENING)
    if current_animation == "SitStartScreen": return
    if current_animation.begins_with("Walk"): return
    if current_animation.begins_with("Sit"):
        setAnimation(ANIM_SIT)
        return
    setAnimationQueue(LIST_ANIM_LISTENING)


func setWalkAnimation()-> void:
    if current_animation == ANIM_WALKING: return
    setAnimation(ANIM_WALKING)


func setWaitingAnimation()-> void:
    if current_animation == ANIM_WAITING: return
    if ref_world.global_script_vars["SCENE"] != "Tracking":
        setAnimation(ANIM_WAITING)
    else:
        setAnimation(ANIM_IDLE)


func teleportTo(pos: Vector3)-> void:
    global_position = pos


func flyTo(pos: Vector3, rot = null)-> void:
    action_script.push_back("fly %f %f %f" % [pos.x, pos.y, pos.z])
    action_script.push_back("rot %f %f %f" % [rot.x, rot.y, rot.z])


func faceTowards(pos: Vector3)-> void:
    if global_position.is_equal_approx(pos): return
    var dir = transform.looking_at(pos, Vector3(0.0, 1.0, 0.0), true)
    rotation = dir.basis.get_euler()


## Sets the current script, instructions will be handled by _handleScript and _advanceScript
func setActionScript(script_name: String, instructions: Array[String])-> void:
    instruction_ptr = 0
    last_instruction_ptr = -1
    action_script.clear()
    instruction_args.clear()
    if current_instruction:
        print("SCRIPT::INTERRUPT")
    current_instruction = null
    print(("SCRIPT::SET:  [%s] " % script_name).rpad(120, "-"))
    action_script = instructions


## Loose float comparison with accuracy amount
func _fltCmp(x: float, y: float, acc: float)-> bool:
    return x > y - acc && x < y + acc


## Check if 2 angles are parallel
func _arePara(x: Vector3, y: Vector3)-> bool:
    return _fltCmp(angle_difference(x.x, y.x), 0.0, 0.001) &&\
           _fltCmp(angle_difference(x.y, y.y), 0.0, 0.001) &&\
           _fltCmp(angle_difference(x.z, y.z), 0.0, 0.001)


func _vecCmp(x: Vector3, y: Vector3, acc: float)-> bool:
    return _fltCmp(x.x, y.x, acc) &&\
           _fltCmp(x.y, y.y, acc) &&\
           _fltCmp(x.z, y.z, acc)


func _basisCmp(x: Basis, y: Basis, acc: float)-> bool:
    return _vecCmp(x.x, y.x, acc) &&\
           _vecCmp(x.y, y.y, acc) &&\
           _vecCmp(x.z, y.z, acc)


func _isVariableName(text: String)-> bool:
    return text.begins_with("$")


## Returns the value of a script variable
func _fetchScriptVar(var_name: String)-> Variant:
    var vname = var_name.replacen("$", "")
    if local_script_vars.has(vname):
        return local_script_vars[vname]
    if ref_world.global_script_vars.has(vname):
        return ref_world.global_script_vars[vname]
    printerr("Could not fetch script var: ", var_name)
    return null


func _checkKeyword(text: String)-> void:
    var lower = text.to_lower()
    var sanitized = rgx_only_alphanum.sub(lower, "", true)

    match sanitized:
        "punch", "/punch":
            ref_world.setLive2DAnimationTemp(ref_world.L2D_MOTION_PUNCH)
            setTempAnimation(ANIM_PUNCH_ORTH\
                    if ref_world.current_scene.scene_name == ref_world.SCENE_ORTHO\
                    else ANIM_PUNCH)
        "/nuke":
            ref_world.ref_nukescene.start()


func _pathTowards(delta: float, pos: Vector3)-> bool:
    ref_navagent.set_target_position(pos)
    var path_to: Vector3 = ref_navagent.get_next_path_position()

    var dir = transform.looking_at(path_to, Vector3(0, 1, 0), true)
    var angle = dir.basis.get_euler()
    #angle.x = rad_to_deg(angle.x)
    angle.y = rad_to_deg(angle.y)
    #angle.z = rad_to_deg(angle.z)
    _rotateTowards(delta, angle, SLOW_ROTATION_SPEED)

    _flyTowards(delta, path_to, false)
    return _vecCmp(global_position, pos, 1.0)


func _pathTowardsPOI(delta: float, poi_name: String)-> bool:
    var dest: Vector3 = ref_world.getPoiRefByName(poi_name).global_position
    ref_navagent.set_target_position(dest)
    var path_to: Vector3 = ref_navagent.get_next_path_position()

    var dir = transform.looking_at(path_to, Vector3(0, 1, 0), true)
    var angle = dir.basis.get_euler()
    #angle.x = rad_to_deg(angle.x)
    angle.y = rad_to_deg(angle.y)
    #angle.z = rad_to_deg(angle.z)
    _rotateTowards(delta, angle, SLOW_ROTATION_SPEED)

    _flyTowards(delta, path_to, false)
    if _vecCmp(global_position, dest, 1.0):
        setWaitingAnimation()
        return true
    return false


func spawnObject()-> void:
    var throw_obj: RigidBody3D = ref_template_throw_object.duplicate() as RigidBody3D

    ref_throw_pivot.rotation_degrees = Vector3((_randf() * 180.0) - 90.0, (_randf() * 180.0) - 90.0, 0.0)

    var spawn_pos = ref_template_throw_object.global_position
    ref_world.addSpawnedObject(throw_obj)
    throw_obj.global_position = spawn_pos

    throw_obj.body_entered.connect(_throwObjectCollide)

    throw_obj.freeze = false
    throw_obj.visible = true
    var target_pos: Vector3 = ref_throw_pivot.global_position\
                              + Vector3((_randf() - 0.5) * THROW_TARGET_DISTORTION,\
                              (_randf() - 0.5) * THROW_TARGET_DISTORTION,\
                              (_randf() - 0.5) * THROW_TARGET_DISTORTION)
    var dir_vector = (target_pos - throw_obj.global_position).normalized()

    throw_obj.set_linear_velocity(dir_vector * THROW_OBJECT_VELOCITY)


func spawnMultipleObjects(amount: int)-> void:
    var i: int = amount
    while i:
        var j: int = 0
        while i && j < MAX_THROW_PER_FRAME:
            i -= 1
            j += 1
            spawnObject()
        await get_tree().process_frame


func _throwObjectCollide(body: Node)-> void:
    if body.is_in_group("hildacollision"):
        var collided = body.get("has_coll")
        if collided: return
        ref_world.setSoundEffect("HitMarker")
    body.set("has_coll", true)


func _pickRdmIndex(list: Array)-> int:
    return floori(list.size() * _randf())


func goBald()-> void:
    bald_cooldown = BALD_COOLDOWN
    $"Armature/Skeleton3D/Hair".visible = false
    $"Armature/Skeleton3D/TwinTail_L".visible = false
    $"Armature/Skeleton3D/TwinTail_R".visible = false


func _handleBaldness(delta: float)-> void:
    if bald_cooldown > 0.0:
        bald_cooldown -= delta
        if bald_cooldown <= 0.0:
            $"Armature/Skeleton3D/Hair".visible = true
            $"Armature/Skeleton3D/TwinTail_L".visible = true
            $"Armature/Skeleton3D/TwinTail_R".visible = true


func angle_difference(x: float, y: float)-> float:
    var diff = fmod(y - x, TAU)
    return fmod(2.0 * diff, TAU) - diff


func rotate_toward(x: float, y: float, amount: float)-> float:
    var diff = angle_difference(x, y)
    var abs_diff = absf(diff)
    return x + clampf(amount, abs_diff - PI, abs_diff) * (1.0 if diff >= 0.0 else -1.0)
