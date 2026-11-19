extends SceneTree
## Headless smoke test: boots the main scene, simulates driving input and
## checkpoint/finish logic. Run:
##   godot47 --headless --path . --script res://tests/smoke.gd

var main: Node2D
var frame := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	physics_frame.connect(_on_physics_frame)


func _on_physics_frame() -> void:
	frame += 1
	if frame == 1:
		_check("player spawned", main.player != null)
		_check("track cells built", main.loop_cells.size() > 40)
		_check("checkpoints placed", main.checkpoint_positions.size() == main.N_CHECKPOINTS)
		_start = main.player.global_position
		Input.action_press("accelerate")
	elif frame == 480:  # ~8 s of full throttle
		Input.action_release("accelerate")
		var travelled: float = main.player.global_position.distance_to(_start)
		_check("car drives (%.0f px in 8 s)" % travelled, travelled > 128.0)
		_check("engine idles at min pitch", main.player.engine_audio.pitch_scale >= 0.7)
		# open stretch of road for a clean rev-up measurement
		main.player.global_position = main.checkpoint_positions[1]
		Input.action_press("accelerate")
	elif frame == 490:
		_check("engine revs with throttle", main.player.engine_audio.pitch_scale > 0.75)
		Input.action_release("accelerate")
		var drove_through: int = main.next_checkpoint
		_check("checkpoints captured while driving (nc=%d)" % drove_through, drove_through >= 2)
		# out-of-order checkpoint must be rejected
		main.next_checkpoint = 1
		main.player.global_position = main.checkpoint_positions[3]
	elif frame == 500:
		_check("out-of-order checkpoint rejected", main.next_checkpoint == 1)
		# correct sequential capture
		main.player.global_position = main.checkpoint_positions[1]
	elif frame == 510:
		_check("checkpoint 1 captured", main.next_checkpoint == 2)
		# skip to final checkpoint, then place car on finish cell
		main.next_checkpoint = main.N_CHECKPOINTS
		main.player.global_position = Vector2(main.loop_cells[3]) * 32.0 + Vector2(16, 16)
	elif frame == 520:
		_check("finish -> new lap, timer reset", main.next_checkpoint == 1 and main.lap_time < 1.0)
		_check("best time saved", main.best_time > 0.0)
		_check("HUD updates", "LAP" in main.lap_label.text)
		print("SMOKE: ALL PASS" if _failed == 0 else "SMOKE: %d FAILURES" % _failed)
		quit(1 if _failed > 0 else 0)


var _start: Vector2
var _failed := 0


func _check(name: String, ok: bool) -> void:
	if not ok:
		_failed += 1
	print("%s %s" % ["PASS" if ok else "FAIL", name])
