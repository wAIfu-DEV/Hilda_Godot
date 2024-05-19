extends Camera3D

# Variables to control the sway effect
var sway_amplitude = 0.5
var sway_speed = 0.75

# Variables to control the zoom effect
var zoom_amount = 2.0
var zoom_speed = 0.5

# Internal timers to make the effects periodic
var sway_timer = 0.0
var zoom_timer = 0.0
var default_fov = 0.0

func _ready():
    # Initialize timers
    sway_timer = 0.0
    zoom_timer = 0.0
    default_fov = fov

func _process(delta):
    # Update the timers
    sway_timer += delta * sway_speed
    zoom_timer += delta * zoom_speed

    # Calculate the sway effect
    var sway_x = sin(sway_timer) * sway_amplitude
    var sway_y = cos(sway_timer) * sway_amplitude / 2.0

    # Apply the sway effect to the camera position
    transform.origin.x += sway_x * delta
    transform.origin.y += sway_y * delta

    # Calculate the zoom effect
    set_fov(default_fov + sin(zoom_timer) * zoom_amount)
