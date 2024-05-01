extends Camera3D

@export var target: Node3D = null;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    if !self.current: return
    if target:
        var target_pos: Vector3 = target.global_transform.origin
        target_pos.y += 11
        var direction: Vector3 = (target_pos - global_transform.origin).normalized()
        global_transform.basis = Basis.looking_at(direction, Vector3(0, 1, 0))
