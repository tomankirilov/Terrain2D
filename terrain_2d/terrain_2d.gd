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

#### HELPER FUNCTIONS

static func is_circle_circle_collision(circle_a:Vector2, circle_b:Vector2, radius:float) -> bool:
	
	var dist := pow(circle_a.x - circle_b.x, 2) + pow(circle_a.y - circle_b.y, 2)
	
	if dist < radius:
		return true
	
	return false

static func get_line_midpoint(line_start:Vector2, line_end:Vector2, offset:float = 0.0) -> Vector2:
	return ( (line_start + line_end) * .5 ) - Vector2.ONE * offset

static func is_circle_line_collision(circle_center:Vector2, circle_radius:float, line_start:Vector2, line_end:Vector2) -> bool:
	# Calculate the line equation
	var m := (line_end.y - line_start.y) / (line_end.x - line_start.x)
	var b := line_start.y - m * line_start.x

	# Calculate the closest point on the line to the circle center
	var px := (circle_center.x + m * circle_center.y - m * b) / (1 + m * m)
	var py := m * px + b

	# Calculate the distance between the circle center and the closest point on the line
	var distance := circle_center.distance_to(Vector2(px, py))

	# Check for collision
	return distance <= circle_radius
