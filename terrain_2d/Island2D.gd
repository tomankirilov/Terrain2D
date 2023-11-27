@tool
extends Node2D
class_name Island2D

@export var polygons:PackedVector2Array
var center:Vector2
var terrain:Terrain2D = null #this variable is set by terrain2D when entered as child of it

func _enter_tree() -> void:
	update_configuration_warnings()
	check_for_polygons()
	pass

func _get_configuration_warnings() -> PackedStringArray:
	
	if not get_parent()  is Terrain2D:
		return ["parent must be a Terrain2D Node"]
	
	return []

#called by Terrain2DPlugin
var is_selected := false
func just_selected() -> void:
	check_for_polygons()
	is_selected = true
	while(is_selected):
		queue_redraw()
		await get_tree().process_frame
	pass

func unselected() -> void:
	is_selected = false
	pass
#end

func add_polygon(pos:Vector2) -> void:
	polygons.push_back(pos)
	var result := Vector2()
	var size := polygons.size()
	for poly in polygons:
		result += poly
	
	center = result / size
	
	pass

func move_polygons(new_center:Vector2) -> void:
	print("move polygons")
	var polygons_offset := PackedVector2Array()
	
	for poly in polygons:
		var offset := center - poly
		polygons_offset.push_back(offset)
	
	for i in range(polygons.size()):
		polygons[i] = new_center - polygons_offset[i]
	
	
	center = new_center
	pass

func recalculate_center() -> void:
	var new_center := Vector2.ZERO
	
	for poly:Vector2 in polygons:
		new_center += poly
	
	center = new_center / polygons.size()
	print("center recalculated")
	pass

func check_for_polygons() -> void:
	if polygons.size() > 1 : return
	
	create_basic_shape()

func create_basic_shape() -> void: #create the initial shape
	var DIST := 64.0
	add_polygon(Vector2(-DIST,-DIST))
	add_polygon(Vector2(DIST,-DIST))
	add_polygon(Vector2(DIST,DIST))
	add_polygon(Vector2(-DIST,DIST))
	print("basic shape created")
	pass

func _draw() -> void:
	draw_polygons_connection()

	for i in range(polygons.size()):
		var p1 := polygons[i]
		var p2 := polygons[(i + 1) % polygons.size()]
		
		check_edit_line(p1,p2)
		draw_custom_icon(p1)
		check_edit_polygon(p1, i)
		pass
	
	pass

func check_edit_line(s1:Vector2, s2:Vector2) -> void:
	if is_editing: return
	if not Terrain2DPlugin.is_circle_line_collision(s1, s2, get_local_mouse_position(),10.0,.8): return
	
	draw_line(s1,s2,Color.AQUA,3.0)
	pass

func check_edit_polygon(poly:Vector2,index:int) -> void:
	if is_editing: return
	if not Terrain2DPlugin.is_circle_circle_collision(poly,get_local_mouse_position(),POLY_SIZE * 8): return
	
	draw_custom_icon(poly,Color.AQUA,Terrain2DPlugin.ICONS.POLY)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		update_polygon_position(index)
	
	pass

var is_editing:bool = false

func update_polygon_position(index) -> void:
	is_editing = true
	while(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		polygons[index] = get_local_mouse_position()
		await get_tree().process_frame
	is_editing = false
	pass


func draw_polygons_connection() -> void:
	draw_polyline(polygons,Color.WHITE_SMOKE,2) # all other connections
	draw_line(polygons[-1],polygons[0],Color.WHITE_SMOKE, 2) #the last polygon connects to the first one
	pass
	
const POLY_SIZE := 16.0
func draw_custom_icon(at:Vector2, modulate:Color=Color.WHITE, icon:CompressedTexture2D=Terrain2DPlugin.ICONS.POLY,icon_scale:float=1.0) -> void:
	var rect := Rect2(Vector2.ONE * at,Vector2(POLY_SIZE*2,POLY_SIZE*2))
	rect.size *= icon_scale
	rect.position -= POLY_SIZE * Vector2.ONE
	draw_texture_rect(icon,rect, false, modulate)
	pass
