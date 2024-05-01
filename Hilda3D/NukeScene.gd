class_name NukeScene extends Node3D

class AnimationVars:
    var animation_time: float = 0.0
    var ejected: bool = false
    var prev_cam: String = ""
    var chatter_name: String = ""


var anim_vars: AnimationVars = null
var started: bool = false

@onready var ref_nuke_shroom: Node3D = $"nuclear_shroom"
@onready var ref_nuke_explode: Node3D = $"nuke_explode"
@onready var ref_chatter: RigidBody3D = $"RigidBody3D"
@onready var ref_chatter_label: Label3D = $"RigidBody3D/chatter/Label3D"
var ref_chatter_copy: RigidBody3D = null

var ref_world: World = null

func _ready() -> void:
    ref_world = get_tree().current_scene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if !started: return

    anim_vars.animation_time += delta

    if anim_vars.animation_time < 1.5:
        pass
    elif anim_vars.animation_time < 3.0:
        if !anim_vars.ejected:
            ref_chatter_copy.freeze = false
            ref_chatter_copy.apply_force(Vector3(11000.0,-8000.0,0.0))
            ref_chatter_copy.apply_force(Vector3(5.0,5.0,5.0), Vector3(5,10,0))
            anim_vars.ejected = true
    elif anim_vars.animation_time < 5.0:
        ref_nuke_explode.scale += Vector3(delta, delta, delta) * 100
        ref_nuke_shroom.scale += Vector3(delta, delta, delta)
    elif anim_vars.animation_time < 6.5:
        ref_nuke_shroom.scale += Vector3(delta, delta, delta) * 2.0
    elif anim_vars.animation_time < 7.0:
        started = false
        ref_nuke_explode.scale = Vector3(0,0,0)
        ref_nuke_shroom.scale = Vector3(0,0,0)
        remove_child(ref_chatter_copy)
        ref_chatter_copy.queue_free()

        ref_world.resetSceneCamera()
        ref_world.displayStatusMessage("%s was nuked." % anim_vars.chatter_name)


func start()-> void:
    anim_vars = AnimationVars.new()
    started = true
    ref_chatter_label.text = ref_world.current_user
    ref_chatter_copy = ref_chatter.duplicate()
    add_child(ref_chatter_copy)
    ref_chatter_copy.visible = true
    anim_vars.prev_cam = ref_world.current_cam.name
    anim_vars.chatter_name = ref_world.current_user
    ref_world.setCurrentCamera("NukeCamera")
    ref_world.setSoundEffect("Nuke")
