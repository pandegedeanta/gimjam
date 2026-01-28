extends Node

# Menyimpan data item agar tidak hilang saat pindah scene
var inventory_data = [] 

func add_item(item_name: String):
	if not item_name in inventory_data:
		inventory_data.append(item_name)
		print("Global: Item disimpan -> ", item_name)

func remove_item(item_name: String):
	if item_name in inventory_data:
		inventory_data.erase(item_name)
		print("Global: Item dihapus -> ", item_name)
