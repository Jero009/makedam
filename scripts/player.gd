extends CharacterBody2D
## Top-down rally car. Sprite "up" = forward. Set `surface` from main.gd
## ("road" / "sand" / "grass") to change max speed and grip.

const ACCEL := 240.0
const BRAKE := 460.0
const REVERSE_MAX := 90.0
const TURN_RATE := 2.7
const DRAG := 0.55            # passive long. deceleration, px/s^2 per (px/s)
const GRIP := 7.0             # lateral velocity bleed per second
const GRIP_HANDBRAKE := 1.4   # drifty
const ENGINE_MIN_PITCH := 0.75

# surface -> [max speed, grip multiplier]
const SURFACES := {
	"road": [230.0, 1.0],
	"sand": [170.0, 0.8],
	"grass": [120.0, 0.65],
}

var surface := "road"
var engine_audio: AudioStreamPlayer

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	engine_audio = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://assets/sfx/engine.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2  # 16-bit mono frames
	engine_audio.stream = stream
	engine_audio.bus = "Master"
	add_child(engine_audio)
	engine_audio.play()


func _physics_process(delta: float) -> void:
	var max_speed: float = SURFACES[surface][0]
	var grip_mult: float = SURFACES[surface][1]

	var throttle := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var handbrake := Input.is_action_pressed("handbrake")

	var forward := Vector2.UP.rotated(rotation)
	var fwd_speed := velocity.dot(forward)
	var lat_speed := velocity.dot(forward.orthogonal())

	# longitudinal: throttle, brake/reverse, passive drag
	if throttle > 0.0:
		fwd_speed += ACCEL * throttle * delta * (1.0 - clampf(fwd_speed / max_speed, 0.0, 1.0))
	elif throttle < 0.0:
		if fwd_speed > 1.0:
			fwd_speed += BRAKE * throttle * delta
		else:
			fwd_speed = maxf(fwd_speed + ACCEL * 0.6 * throttle * delta, -REVERSE_MAX)
	fwd_speed -= fwd_speed * DRAG * delta
	fwd_speed = clampf(fwd_speed, -REVERSE_MAX, max_speed)

	# lateral grip (lower = more drift)
	var grip := (GRIP_HANDBRAKE if handbrake else GRIP) * grip_mult
	lat_speed *= exp(-grip * delta)

	# steering scales with speed and reverses when reversing
	var speed_factor := clampf(absf(fwd_speed) / 70.0, 0.0, 1.0)
	rotation += steer * TURN_RATE * speed_factor * signf(fwd_speed) * delta

	velocity = forward * fwd_speed + forward.orthogonal() * lat_speed
	move_and_slide()

	# engine pitch follows speed
	var pitch := ENGINE_MIN_PITCH + 0.9 * clampf(velocity.length() / max_speed, 0.0, 1.0)
	engine_audio.pitch_scale = pitch


func reset_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	rotation = 0.0
