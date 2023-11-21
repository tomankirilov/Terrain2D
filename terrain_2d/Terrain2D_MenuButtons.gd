@tool
extends HBoxContainer
class_name Terrain2D_MenuButtons

signal create_island

static var instance:Terrain2D_MenuButtons = null
var selected_island:Island2D = null

@export var button_add:Button
@export var button_remove:Button

@export var button_move:Button

static func enable_add_island(enable:bool) -> void:
	instance.button_add.disabled = !enable

static func enable_remove_island(enable:bool) -> void:
	instance.button_remove.disabled = !enable


func _on_bt_create_island_pressed() -> void:
	create_island.emit()
	pass # Replace with function body.

func _process(delta: float) -> void:
	#button_move.global_position = get_global_mouse_position()
	pass
