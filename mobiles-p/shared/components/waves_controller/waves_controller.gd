extends Node2D

@onready var spawners : Array[Node] = get_children()

var enemy_ammount : int = 0
var enemy_hp : float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	PATHS.btn_next_wave.pressed.connect(start_wave)

func get_wave_data() -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var payload = {
		"salud": float(PATHS.core.health),
		"ayudas": int(PATHS.ia_assistance_used),
		"codigo": int(PATHS.drones_built)
	}
	var headers = ["Content-Type: application/json"]
	var err = http_request.request("http://127.0.0.1:5000/predict", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		http_request.queue_free()
		return {"enemigos": enemy_ammount, "hp": enemy_hp}

	var result = await http_request.request_completed
	var response_code = result[1]
	var response_body = result[3]
	if result[0] != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		http_request.queue_free()
		return {"enemigos": enemy_ammount, "hp": enemy_hp}

	var body_text = response_body.get_string_from_utf8()
	var json_result = JSON.parse_string(body_text)
	if typeof(json_result) == TYPE_DICTIONARY:
		if json_result.has("enemigos"):
			enemy_ammount = int(json_result.enemigos)
		if json_result.has("hp"):
			enemy_hp = float(json_result.hp)

	http_request.queue_free()
	return {"enemigos": enemy_ammount, "hp": enemy_hp}

func start_wave() -> void:
	PATHS.btn_next_wave.disabled = true
	var wave_data = await get_wave_data()
	GLOBAL.enemies_alive = wave_data.enemigos
	GLOBAL.wave_number += 1

	var enemy_per_spawner = int(ceil(float(wave_data.enemigos) / spawners.size()))

	for spawner in spawners:
		var insect_scene : PackedScene = load("uid://bjplqihi53swl")
		for i in range(enemy_per_spawner):
			var enemy : Node2D = insect_scene.instantiate()
			spawner.add_child(enemy)
			enemy.global_position = spawner.global_position
			enemy.hp = wave_data.hp

func end_wave() -> void:
	PATHS.btn_next_wave.disabled = false

func _process(_delta: float) -> void:
	if GLOBAL.enemies_alive <= 0:
		end_wave()
	
