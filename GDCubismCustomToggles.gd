class_name GDCubismCustomToggle extends GDCubismEffectCustom

var ref_world: World = null

var active_toggles: Array[String] = []
var params: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    ref_world = get_tree().current_scene
    cubism_process.connect(_on_cubism_process)


func _on_cubism_process(_model: GDCubismUserModel, _delta: float)-> void:
    for key in params.keys():
        params[key]["param"].value = params[key]["value"]


func setToggle(toggle_name: String)-> void:
    if not ref_world.L2D_EXPRESSIONS.has(toggle_name): return
    var toggle_dict: Dictionary = ref_world.L2D_EXPRESSIONS[toggle_name]
    for key in toggle_dict.keys():
        if not params.has(key):
            params[key] = {}
            params[key]["refs"] = 0
        params[key]["value"] = toggle_dict[key]
        params[key]["refs"] += 1
        for param in ref_world.ref_live2d.get_parameters():
            if key == param.id:
                params[key]["param"] = param

func unToggle(toggle_name: String)-> void:
    if not ref_world.L2D_EXPRESSIONS.has(toggle_name): return
    var toggle_dict: Dictionary = ref_world.L2D_EXPRESSIONS[toggle_name]
    var to_erase = []
    for key in toggle_dict.keys():
        if not params.has(key): continue
        params[key]["refs"] -= 1
        if params[key]["refs"] <= 0:
            to_erase.push_back(key)
    for key in to_erase:
        params.erase(key)
