@tool
extends EditorPlugin
class_name Terrain2D

var tools_created:bool = false


func _enter_tree() -> void:
	EditorInterface.get_selection().selection_changed.connect(on_selection_changed)
	
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass

var target_terrain:TerrainInstance2D = null

func on_selection_changed() -> void:
	var selection := EditorInterface.get_selection()
	if selection.get_selected_nodes().size() != 1: return
	var terrain := selection.get_selected_nodes()[0]
	if not terrain is TerrainInstance2D: 
		show_tools(false)
		return
	else: 
		create_tools()
		show_tools(true)
	
	target_terrain = terrain
	terrain.just_selected()
	print("selected terrain")
	pass

func create_tools() -> void:
	if tools_created: return
	tools_created = true
	
	pass

func show_tools(visible:bool) -> void:
	
	pass

func _input(event: InputEvent) -> void:
	if target_terrain == null: return
	
	if event is InputEventMouseMotion:
		target_terrain.queue_redraw()
	elif event is InputEventMouseButton:
		target_terrain.on_mouse_pressed(event as InputEventMouseButton)
		pass
	pass

const ICONS := {
	ADD = preload("res://addons/terrain_2d/icons/icon-add.svg"),
	POLY = preload("res://addons/terrain_2d/icons/icon-poly.svg")
}
