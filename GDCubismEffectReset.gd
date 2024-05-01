class_name GDCubismReset extends GDCubismEffectCustom

var ref_world: World = null

const BLINK_MIN_TIME: float = 0.5
const BLINK_MAX_TIME: float = 3.0
const BLINK_SPEED: float = 5.0

enum BLINK_STATE {
    OPEN,
    CLOSING,
    CLOSED,
    OPENING
}

var punchid: GDCubismParameter
var glasscrack: GDCubismParameter

var param_eye_l_open: GDCubismParameter
var param_eye_r_open: GDCubismParameter

var blink_cooldown: float = 0.0
var blink_state: BLINK_STATE = BLINK_STATE.OPEN
var eyes_closed_amount: float = 0.0


func _ready() -> void:
    ref_world = get_tree().current_scene
    cubism_init.connect(_on_cubism_init)
    cubism_process.connect(_on_cubism_process)


func _on_cubism_init(model: GDCubismUserModel)-> void:
    var param_names: PackedStringArray = [
        "punchid",
        "glasscrack",
        "ParamEyeLOpen",
        "ParamEyeROpen"
    ]
    for param in model.get_parameters():
        if param_names.has(param.id):
            set(param.id.to_snake_case(), param)


func _on_cubism_process(_model: GDCubismUserModel, delta: float)-> void:
    if blink_state == BLINK_STATE.OPEN:
        blink_cooldown -= delta

    if punchid.value != 0.0:
        print("punch:", punchid.value)
        print("glass:", glasscrack.value)

    if blink_cooldown <= 0.0 && blink_state == BLINK_STATE.OPEN:
        blink_state = BLINK_STATE.CLOSING

    match blink_state:
        BLINK_STATE.OPEN:
            param_eye_l_open.value = 1.0
            param_eye_r_open.value = 1.0
        BLINK_STATE.CLOSED:
            param_eye_l_open.value = 0.0
            param_eye_r_open.value = 0.0
            blink_state = BLINK_STATE.OPENING
        BLINK_STATE.OPENING:
            param_eye_l_open.value = 1.0 - eyes_closed_amount
            param_eye_r_open.value = 1.0 - eyes_closed_amount
            eyes_closed_amount -= delta * BLINK_SPEED
            if eyes_closed_amount <= 0.0:
                eyes_closed_amount = 0.0
                blink_state = BLINK_STATE.OPEN
                blink_cooldown = randf_range(BLINK_MIN_TIME, BLINK_MAX_TIME)
        BLINK_STATE.CLOSING:
            param_eye_l_open.value = 1.0 - eyes_closed_amount
            param_eye_r_open.value = 1.0 - eyes_closed_amount
            eyes_closed_amount += delta * BLINK_SPEED
            if eyes_closed_amount >= 1.0:
                eyes_closed_amount = 1.0
                blink_state = BLINK_STATE.CLOSED


func resetParameters()-> void:
    punchid.reset()
    punchid.value = 0.0
    glasscrack.reset()
    glasscrack.value = 0.0
