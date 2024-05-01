class_name GDCubismLipSync extends GDCubismEffectCustom

var ref_world: World = null

var param_mouth_open_y: GDCubismParameter
var param_mouth_form: GDCubismParameter

var last_open: float = 0.0
var last_form: float = 0.0


func _ready() -> void:
    ref_world = get_tree().current_scene
    cubism_init.connect(_on_cubism_init)
    cubism_process.connect(_on_cubism_process)


func _on_cubism_init(model: GDCubismUserModel)-> void:
    var param_names: PackedStringArray = [
        "ParamMouthOpenY",
        "ParamMouthForm",
    ]
    for param in model.get_parameters():
        if param_names.has(param.id):
            set(param.id.to_snake_case(), param)


func _on_cubism_process(_model: GDCubismUserModel, _delta: float)-> void:
    param_mouth_open_y.value = last_open
    param_mouth_form.value = last_form


func setMouthParams(open: float, form: float)-> void:
    last_open = open
    last_form = form
    param_mouth_open_y.value = last_open
    param_mouth_form.value = last_form
