class_name TVSceneCamera extends Camera3D

var ref_world: World = null

var MOVE_SPEED: float = 0.25

var current_time: float = 0.0
var accelerate: float = 0.0
var accelarate_fast: float = 0.0
var decelerate: float = 1.0
var started: bool = false

var flag_video_on: bool = false

func _ready() -> void:
    ref_world = get_tree().current_scene


func exit()-> void:
    started = false
    ref_world.setCurrentScene(ref_world.SCENE_ORTHO)
    ref_world.ref_hud2D.visible = true


func _process(delta: float)-> void:
    if !started: return
    current_time += delta

    if Input.is_action_just_pressed("ui_cancel"):
        exit()

    if current_time < 3.0:
        pass
    elif current_time < 4.0:
        accelerate = accelerate + delta if accelerate < 1.0 else 1.0
        global_position.z -= MOVE_SPEED * delta * accelerate
    elif current_time < 8.0:
        global_position.z -= MOVE_SPEED * delta
    elif !flag_video_on:
        flag_video_on = true
        ref_world.ref_initscreentv.ref_videostreamplayer.play()
    elif current_time < 11.0:
        decelerate = decelerate - (delta / 3.0) if decelerate > 0.0 else 0.0
        global_position.z -= MOVE_SPEED * delta * decelerate
    elif global_position.z > -8.0:
        accelarate_fast = accelarate_fast + (delta * 5.0)
        global_position.z -= MOVE_SPEED * delta * accelarate_fast
    else:
        exit()


func start()-> void:
    started = true
