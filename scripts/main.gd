extends Node2D
## Builds the whole race from data: a loop of track cells (tiles are picked
## automatically from neighbours), decor obstacles, checkpoints, HUD, audio.

const TILE := 32
const SAVE_PATH := "user://best_time.cfg"

# Track loop corners (tile coords, inclusive segments, closed loop).
const LOOP_CORNERS: Array[Vector2i] = [
	Vector2i(5, 3), Vector2i(19, 3), Vector2i(19, 8),
	Vector2i(11, 8), Vector2i(11, 13), Vector2i(19, 13),
	Vector2i(19, 16), Vector2i(5, 16), Vector2i(5, 3),
]
const N_CHECKPOINTS := 6
# Decor: kind -> cells ("tree", "rock", "hay"). All on grass, all solid.
const DECOR := {
	"tree": [Vector2i(3, 1), Vector2i(8, 1), Vector2i(14, 1), Vector2i(22, 3),
			 Vector2i(22, 10), Vector2i(2, 8), Vector2i(2, 14), Vector2i(9, 18),
			 Vector2i(14, 18), Vector2i(2, 5), Vector2i(23, 6), Vector2i(8, 6)],
	"rock": [Vector2i(14, 5), Vector2i(6, 10), Vector2i(16, 15)],
	"hay": [Vector2i(13, 10), Vector2i(4, 7)],
}
# Sand patch cells (off-track, slows the car).
const SAND_CELLS := [Vector2i(8, 14), Vector2i(9, 14), Vector2i(8, 15), Vector2i(9, 15)]

var loop_cells: Array[Vector2i] = []
var road_set := {}
var tilemap: TileMapLayer
var player: CharacterBody2D
var sfx: AudioStreamPlayer
var lap_label: Label

var lap_time := 0.0
var best_time := 0.0
var next_checkpoint := 0
var checkpoint_positions: Array[Vector2] = []


func _ready() -> void:
	_setup_input()
	_build_loop()
	_build_tileset_and_map()
	_spawn_decor()
	_place_checkpoints()
	_spawn_player()
	_build_hud()
	_load_best()
	next_checkpoint = 1  # race starts with checkpoint 1 armed
	sfx = AudioStreamPlayer.new()
	add_child(sfx)


func _process(delta: float) -> void:
	lap_time += delta
	_update_hud()
	if Input.is_action_just_pressed("restart"):
		_restart()
	player.surface = _surface_at(player.global_position)


# ---------------------------------------------------------------- track build

func _build_loop() -> void:
	for i in range(LOOP_CORNERS.size() - 1):
		var a := LOOP_CORNERS[i]
		var b := LOOP_CORNERS[i + 1]
		var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
		var c := a
		while c != b:
			if not c in loop_cells:
				loop_cells.append(c)
			c += step
	if not loop_cells[0] in loop_cells:
		pass
	if loop_cells.back() != loop_cells[0]:
		loop_cells.append(loop_cells[0])


func _tile_name_for(cell: Vector2i) -> String:
	var n := Vector2i(cell.x, cell.y - 1) in loop_cells
	var s := Vector2i(cell.x, cell.y + 1) in loop_cells
	var e := Vector2i(cell.x + 1, cell.y) in loop_cells
	var w := Vector2i(cell.x - 1, cell.y) in loop_cells
	if n and s: return "road-straight"
	if e and w: return "road-straight-h"
	if w and s: return "road-corner-ws"
	if e and s: return "road-corner-es"
	if w and n: return "road-corner-wn"
	if e and n: return "road-corner-en"
	return "road-straight"


func _build_tileset_and_map() -> void:
	tilemap = TileMapLayer.new()
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var source_ids := {}
	var paths := {
		"road-straight": "res://assets/road-straight.png",
		"road-straight-h": "res://assets/road-straight-h.png",
		"road-corner-ws": "res://assets/road-corner-ws.png",
		"road-corner-es": "res://assets/road-corner-es.png",
		"road-corner-wn": "res://assets/road-corner-wn.png",
		"road-corner-en": "res://assets/road-corner-en.png",
		"finish": "res://assets/finish-tile.png",
		"grass-1": "res://assets/grass-1.png",
		"grass-2": "res://assets/grass-2.png",
		"sand": "res://assets/sand.png",
	}
	var idx := 0
	for name in paths:
		var src := TileSetAtlasSource.new()
		src.texture = load(paths[name])
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i.ZERO)
		ts.add_source(src, idx)
		source_ids[name] = idx
		idx += 1
	tilemap.tile_set = ts
	add_child(tilemap)

	# grass/sand everywhere under the track
	for y in range(20):
		for x in range(26):
			var name := "sand" if Vector2i(x, y) in SAND_CELLS else ("grass-2" if (x + y) % 7 == 0 else "grass-1")
			tilemap.set_cell(Vector2i(x, y), source_ids[name], Vector2i.ZERO)
	# track tiles
	for cell in loop_cells:
		var name := _tile_name_for(cell)
		tilemap.set_cell(cell, source_ids[name], Vector2i.ZERO)
		road_set[cell] = true
	# finish line replaces the first straight cell after the loop start
	var finish_cell := loop_cells[3]
	tilemap.set_cell(finish_cell, source_ids["finish"], Vector2i.ZERO)


func _spawn_decor() -> void:
	var textures := {"tree": "res://assets/tree-1.png", "tree2": "res://assets/tree-2.png",
					 "rock": "res://assets/rock.png", "hay": "res://assets/haybale-1.png"}
	var radii := {"tree": 10.0, "rock": 8.0, "hay": 9.0}
	var i := 0
	for kind in DECOR:
		for cell in DECOR[kind]:
			var body := StaticBody2D.new()
			body.position = Vector2(cell) * TILE + Vector2(TILE, TILE) / 2.0
			var spr := Sprite2D.new()
			var tex_name: String = ("tree2" if i % 3 == 1 else "tree") if kind == "tree" else kind
			spr.texture = load(textures[tex_name])
			body.add_child(spr)
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = radii[kind]
			shape.shape = circle
			body.add_child(shape)
			add_child(body)
			i += 1


# ------------------------------------------------------------------- racing

func _place_checkpoints() -> void:
	var step := loop_cells.size() / N_CHECKPOINTS
	for i in range(N_CHECKPOINTS):
		var cell := loop_cells[i * step]
		checkpoint_positions.append(Vector2(cell) * TILE + Vector2(TILE, TILE) / 2.0)
		if i == 0:
			continue  # finish is the tile itself, not a flag
		var flag := Sprite2D.new()
		flag.texture = load("res://assets/checkpoint.png")
		flag.position = checkpoint_positions[i] + Vector2(0, -12)
		add_child(flag)


func _spawn_player() -> void:
	player = CharacterBody2D.new()
	player.set_script(load("res://scripts/player.gd"))
	player.position = checkpoint_positions[0]
	player.rotation = _heading_at(loop_cells[0])
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/audi-red-top-detail.png")
	spr.name = "Sprite"
	player.add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 26)
	shape.shape = rect
	player.add_child(shape)
	var cam := Camera2D.new()
	cam.zoom = Vector2(2, 2)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	player.add_child(cam)
	# keep the car off the trees/rocks/hay
	player.collision_layer = 1
	player.collision_mask = 1
	add_child(player)
	cam.make_current()


func _heading_at(cell: Vector2i) -> float:
	# rotation that makes the car's forward (sprite up) point along the track
	var i := loop_cells.find(cell)
	var dir := Vector2(loop_cells[(i + 1) % loop_cells.size()] - cell)
	return dir.angle() + PI / 2.0


func _surface_at(pos: Vector2) -> String:
	var cell := Vector2i((pos / TILE).floor())
	if cell in road_set:
		return "road"
	if cell in SAND_CELLS:
		return "sand"
	return "grass"


func _on_checkpoint_reached(index: int) -> void:
	if index != next_checkpoint:
		return
	next_checkpoint += 1
	sfx.stream = load("res://assets/sfx/checkpoint.wav")
	sfx.play()


func _check_finish() -> void:
	var cell := Vector2i((player.global_position / TILE).floor())
	if next_checkpoint == N_CHECKPOINTS and cell == loop_cells[3]:
		if best_time == 0.0 or lap_time < best_time:
			best_time = lap_time
			_save_best()
		sfx.stream = load("res://assets/sfx/lap_done.wav")
		sfx.play()
		next_checkpoint = 1
		lap_time = 0.0


func _restart() -> void:
	player.reset_to(checkpoint_positions[0])
	player.rotation = _heading_at(loop_cells[0])
	next_checkpoint = 1
	lap_time = 0.0


func _physics_process(_delta: float) -> void:
	# sequential checkpoints by distance (small map, exact enough)
	if next_checkpoint > 0 and next_checkpoint < N_CHECKPOINTS:
		if player.global_position.distance_to(checkpoint_positions[next_checkpoint]) < 24.0:
			_on_checkpoint_reached(next_checkpoint)
	_check_finish()


# ---------------------------------------------------------------------- hud

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	lap_label = Label.new()
	lap_label.position = Vector2(8, 4)
	lap_label.add_theme_font_size_override("font_size", 12)
	layer.add_child(lap_label)


func _update_hud() -> void:
	var best := ("  BEST %s" % _fmt(best_time)) if best_time > 0.0 else ""
	lap_label.text = "LAP %s   CP %d/%d%s" % [_fmt(lap_time), next_checkpoint, N_CHECKPOINTS, best]


func _fmt(t: float) -> String:
	var m := int(t) / 60
	var s := fmod(t, 60.0)
	return "%d:%05.2f" % [m, s]


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_time = cfg.get_value("lap", "best", 0.0)


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("lap", "best", best_time)
	cfg.save(SAVE_PATH)


# -------------------------------------------------------------------- input

func _setup_input() -> void:
	var bindings := {
		"accelerate": [KEY_W, KEY_UP],
		"brake": [KEY_S, KEY_DOWN],
		"steer_left": [KEY_A, KEY_LEFT],
		"steer_right": [KEY_D, KEY_RIGHT],
		"handbrake": [KEY_SPACE],
		"restart": [KEY_R],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
