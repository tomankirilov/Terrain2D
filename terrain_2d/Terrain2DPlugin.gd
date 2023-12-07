@tool
extends EditorPlugin
class_name Terrain2DPlugin

var tools_created:bool = false

const T2D_MENU_BUTTONS = preload("res://addons/terrain_2d/ui/t2d_menu_buttons.tscn")
static var menu_buttons:Terrain2D_MenuButtons = null
static var selected_terrain:Terrain2D = null
static var selected_island:Island2D = null

const COLOR_UNSELECTED:Color = Color.DIM_GRAY
const COLOR_SELECTED:Color = Color.WHITE

# PLUGIN CONFIGURATION ============

func _enter_tree() -> void:


	add_custom_type("Terrain2D", "Node", Terrain2D, load("res://addons/terrain_2d/icons/icon-terrain-2d.svg"))
	EditorInterface.get_selection().selection_changed.connect(on_selection_changed)
	if menu_buttons == null:
		menu_buttons = T2D_MENU_BUTTONS.instantiate()
		menu_buttons.visible = false
		Terrain2D_MenuButtons.instance = menu_buttons
		menu_buttons.create_island.connect(_on_create_island_pressed)
		#menu_buttons.move_island.connect(_on_move_island_pressed)
		#menu_buttons.select_island.connect(_on_select_island_pressed)
		add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,menu_buttons)
	# Initialization of the plugin goes here.
	pass

func _handles(object: Object) -> bool:
	if object is Terrain2D:
		return true
	return false


func _exit_tree() -> void:
	remove_custom_type("Terrain2D")

	menu_buttons = null
	# Clean-up of the plugin goes here.
	pass


func on_selection_changed() -> void:

	var selection := EditorInterface.get_selection()
	if selection.get_selected_nodes().size() != 1: return
	var selected := selection.get_selected_nodes()[0]

	if selected_island != null:
		selected_island.unselected()
		selected_island = null

	if selected is Island2D:
		selected_island = selected
		selected.just_selected()

	if selected_island == null: return
	print("selected islands: " + selected_island.name)

	pass

var first_time_selecting_terrain:bool = true

func show_tools(visible:bool) -> void:
	menu_buttons.visible = visible

	if first_time_selecting_terrain:
		first_time_selecting_terrain = false
		do_hack_editor()

	show_default_godot_tools(!visible)

	pass

#func _input(event: InputEvent) -> void:
	#if selected_terrain == null: return
	#
	#if event is InputEventMouseMotion:
		#selected_terrain.queue_redraw()
	#elif event is InputEventMouseButton:
		#selected_terrain.on_mouse_pressed(event as InputEventMouseButton)
		#pass
	#pass


#func _forward_canvas_draw_over_viewport(overlay:Control):
	## Draw a circle at cursor position.
	#if selected_terrain == null: return
	##overlay.draw_circle(overlay.get_local_mouse_position(), 64, Color.WHITE)
	#overlay.draw_arc(overlay.get_local_mouse_position(), 16, 0.0, 360.0,12,Color.WHEAT,1.0)
	#selected_terrain.draw(overlay)
#
func _forward_canvas_gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected_terrain.left_clicked(event.position)
			return true
	#if event is InputEventMouseMotion:
		## Redraw viewport when cursor is moved.
		#update_overlays()
		#return true
	return false


const ICONS := {
	ADD = preload("res://addons/terrain_2d/icons/icon-add.svg"),
	MOVE = preload("res://addons/terrain_2d/icons/icon-move.svg"),
	POLY = preload("res://addons/terrain_2d/icons/icon-poly.svg")
}


### HACKY FUNCTIONS

var tools_panel:Control = null

func do_hack_editor() -> void:

	#get the CONTINER_CANVAS_EDITOR_MENU node manually
	tools_panel = menu_buttons.get_parent().get_parent().get_parent()
	# remove my custom menu_buttons from this container
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU,menu_buttons)
	# add it again manually
	tools_panel.add_child(menu_buttons)

	#you may ask why the fuck you are doing this shit dude?
	# well my friend, basically when I'm calling (show_default_godot_tools()) it will hide this container
	# but I still want to keep menu_buttons visible
	pass

func show_default_godot_tools(show:bool) -> void:
	#this is a hacky way to hide godot default tools, do not replicate at home!

	for child in tools_panel.get_children():

		if child is HBoxContainer:
			for c in child.get_children():
				c.visible = show
			return
	pass


#### TOOL MANAGEMENT

var current_id :int = -1

const DATA_PATH := "res://addons/terrain_2d/data.cfg"
const RESOURCE_PATH := "res://addons/terrain_2d/%s.tres"
func _on_create_island_pressed() -> void:
	if selected_terrain == null:
		push_error("no Terrain2D is selected!")
		return
	var island := Island2D.new()
	selected_terrain.create_basic_shape(island)
	#menu_buttons.set_state(Terrain2D_MenuButtons.STATES.move, island)
	pass

func _on_select_island_pressed() -> void:
	selected_terrain.select_island()
	pass

func _on_move_island_pressed() -> void:
	selected_terrain.move_island()
	pass

#### HELPER FUNCTIONS

static func create_aabb(island:Island2D) -> Rect2:
	var result := Rect2()

	var _min := island.polygons[0]
	var _max := island.polygons[0]

	for polygon:Vector2 in island.polygons:
		_min.x = min(_min.x, polygon.x)
		_min.y = min(_min.y, polygon.y)
		_max.x = max(_max.x, polygon.x)
		_max.y = max(_max.x, polygon.y)


	result.size = (_max - _min) * 1.2
	result.position = ((_min + _max) / 2) - result.size / 2

	return result

static func is_circle_circle_collision(circle_a:Vector2, circle_b:Vector2, radius:float) -> bool:
	var dist := pow(circle_a.x - circle_b.x, 2) + pow(circle_a.y - circle_b.y, 2)
	return dist < radius

static func get_line_midpoint(line_start:Vector2, line_end:Vector2, offset:float = 0.0) -> Vector2:
	return ( (line_start + line_end) * .5 ) - Vector2.ONE * offset

# projects a point C into line AB with a certain radius
# clamp_offset is a value from 0-1 that represents how long from center to line borders will be detectable from point_c
static func is_circle_line_collision(point_a:Vector2, point_b:Vector2, point_c:Vector2, radius:float, clamp_offset:float=1.0) -> bool:
	var direction := (point_b - point_a).normalized()
	var distance := (point_c-point_a).dot(direction)
	var line_length := (point_b - point_a).length()
	distance = clamp(distance,0 + (line_length - (line_length * clamp_offset)), line_length * clamp_offset)
	var projection := direction * distance
	var closest := point_a + projection

	return Terrain2DPlugin.is_circle_circle_collision(point_c, closest, radius)
