extends Node

# Database Item
var inventory_data: Array = [] 
# Database Progres (Status pintu, gembok, dll)
var interaction_states: Dictionary = {} 

# Data Transisi
var next_spawn_pos: Vector2 = Vector2.ZERO
var next_spawn_flip: bool = false
var is_transitioning: bool = false

func _ready():
	print("Global: Autoload aktif dan siap menjaga data!")

func add_item(item_dict: Dictionary):
	# Validasi data agar tidak null
	if not item_dict.has("name") or not item_dict.has("texture"):
		push_error("Global: Data item tidak lengkap!")
		return
		
	# Cek supaya tidak double
	for item in inventory_data:
		if item["name"] == item_dict["name"]: 
			return
			
	inventory_data.append(item_dict)
	print("Global: Item masuk database -> ", item_dict["name"], " | Total: ", inventory_data.size())

func remove_item(item_name: String):
	for i in range(inventory_data.size()):
		if inventory_data[i]["name"] == item_name:
			inventory_data.remove_at(i) # Ini yang beneran hapus dari memori
			print("Global: Data " + item_name + " resmi dibuang dari memori.")
			return
			
func save_state(obj_name: String, data: Dictionary):
	interaction_states[obj_name] = data

func get_state(obj_name: String):
	return interaction_states.get(obj_name, null)
