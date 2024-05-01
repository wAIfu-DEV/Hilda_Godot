class_name TrackingCameraManager extends Node

const CAMERA_SWITCH_COOLDOWN: float = 2.0

var ref_world: World = null

var camera_cooldown: float = 0.0
var current_camera: Camera3D = null
var current_distance: float = 0.0

func _ready() -> void:
    ref_world = get_tree().current_scene as World

func _process(delta: float) -> void:
    current_distance = 0.0

    if camera_cooldown > 0.0:
        camera_cooldown -= delta

    if ref_world.global_script_vars["SCENE"] == "Tracking" && camera_cooldown <= 0.0:
        var camera: Camera3D = null
        var min_dist: float = 999999.9
        for cam: Camera3D in ref_world.ref_trackingcameras.get_children():
            var dist: float = ref_world.current_hilda.global_position.distance_to(cam.global_position)
            if dist < min_dist:
                camera = cam
                min_dist = dist
        current_camera = camera
        current_distance = min_dist
        current_camera.make_current()
        camera_cooldown = CAMERA_SWITCH_COOLDOWN

    if current_camera != null:
        if current_distance == 0.0:
            current_distance = ref_world.current_hilda.global_position.distance_to(current_camera.global_position)

        current_camera.fov = 25.0 \
                             if current_distance > 50.0 \
                             else ((1.0 - (current_distance / 50.0)) * 25.0) + 25.0
