@tool
extends Node2D
class_name Island2D

signal polygons_updated(island)

var _line_color = Terrain2DPlugin.COLOR_UNSELECTED

@export var polygons:PackedVector2Array
@export var show_mesh:bool:
	set(value):
		show_mesh = value
		if terrain == null: return
		#terrain.create_mesh(polygons,name)
		create_mesh()
		print("mesh created")
var center:Vector2
var terrain:Terrain2D = null #this variable is set by terrain2D when entered as child of it

func _enter_tree() -> void:
	update_configuration_warnings()
	check_for_polygons()
	terrain = get_parent()
	polygons_updated.connect(terrain.on_polygons_updated)
	visibility_changed.connect(func():
		if visible and Terrain2DPlugin.selected_island == self: just_selected())
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
	_line_color = Terrain2DPlugin.COLOR_SELECTED
	while(is_selected and visible):
		queue_redraw()
		#print("drawing:" + name)
		await get_tree().process_frame
		await get_tree().process_frame
	pass



func unselected() -> void:
	_line_color = Terrain2DPlugin.COLOR_UNSELECTED
	is_selected = false
	queue_redraw()
	print("unselected:" + name)
	pass
#end
#
#func get_world_polygons() -> PackedVector2Array
#
	#pass

func add_polygon(pos:Vector2) -> void:
	polygons.push_back(pos)
	var result := Vector2()
	var size := polygons.size()
	for poly in polygons:
		result += poly

	center = result / size

	pass

func add_polygon_after(index:int, pos:Vector2) -> void:
	if index+1 >= polygons.size():
		polygons.insert(0,pos)
	else:
		polygons.insert(index+1,pos)
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

@export var square_scale:float = 4.0
func _draw() -> void:

	#if terrain.meshes.has(name):
		#var xform := global_transform
		#xform.origin = terrain.global_position
		#draw_mesh(terrain.meshes[name],terrain.terrain_resource.main_texture,xform)

	draw_polygons_connection()

	for i in range(polygons.size()):
		var p1 := polygons[i]
		var p2 := polygons[(i + 1) % polygons.size()]

		check_edit_line(p1,p2,i)
		draw_custom_icon(p1)
		check_edit_polygon(p1, i)
		pass

	#create_border(polygons[0],polygons[1])



	pass

func create_border(center_left:Vector2, center_right:Vector2,draw:bool=true) -> Dictionary:
	var data := {}
	var dir := (center_right - center_left).normalized()
	var perpendicular: Array[float] = [-dir.y,dir.x]
	var vertices :Array[Vector2] = [
		Vector2(center_left.x - ( square_scale * perpendicular[0]),center_left.y - (square_scale * perpendicular[1]) ), #bottom-left
		Vector2(center_left.x + ( square_scale * perpendicular[0]),center_left.y + (square_scale * perpendicular[1]) ), #top-left
		Vector2(center_right.x + ( square_scale * perpendicular[0]),center_right.y + (square_scale * perpendicular[1]) ), #top_right
		Vector2(center_right.x - ( square_scale * perpendicular[0]),center_right.y - (square_scale * perpendicular[1]) ) #bottom_right
	]
	var colors:PackedColorArray = [Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]
	var uvs:PackedVector2Array = [Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(1,0)]
	data.colors = colors
	data.vertices = vertices
	data.uvs = uvs

	if draw:
		draw_primitive(vertices,colors,uvs)

	return data

func check_edit_line(s1:Vector2, s2:Vector2, s1_index:int) -> void:
	if is_editing: return
	if not Terrain2DPlugin.is_circle_line_collision(s1, s2, get_local_mouse_position(),10.0,.8): return

	# (+) PLUS ICON SYSTEM

	draw_line(s1,s2,Color.AQUA,3.0)
	var middle := Terrain2DPlugin.get_line_midpoint(s1,s2)
	draw_custom_icon(middle, Color.WHITE,Terrain2DPlugin.ICONS.ADD)

	if not Terrain2DPlugin.is_circle_circle_collision(middle,get_local_mouse_position(),POLY_SIZE): return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return

	add_polygon_after(s1_index, get_local_mouse_position())

	# hacky way to avoid create more tha one polygon at click
	is_editing = true
	await get_tree().process_frame
	is_editing = false
	#end of hack

	print("added polygon")
	return
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
	polygons_updated.emit(self)
	is_editing = false
	pass

func draw_polygons_connection() -> void:
	draw_polyline(polygons,_line_color,2) # all other connections
	draw_line(polygons[-1],polygons[0],_line_color, 2) #the last polygon connects to the first one
	pass

const POLY_SIZE := 16.0
func draw_custom_icon(at:Vector2, modulate:Color=Color.WHITE, icon:CompressedTexture2D=Terrain2DPlugin.ICONS.POLY,icon_scale:float=1.0) -> void:
	var rect := Rect2(Vector2.ONE * at,Vector2(POLY_SIZE*2,POLY_SIZE*2))
	rect.size *= icon_scale
	rect.position -= POLY_SIZE * Vector2.ONE
	draw_texture_rect(icon,rect, false, modulate)
	pass

func create_mesh() -> void:
	#data contains: colors, vertices, uvs
	var data := create_border(polygons[0], polygons[1], false)
	print(data)
	#get a square between polygons

	var mesh := ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

		# Define indices for the quad.

	for v in data.vertices:
		verts.append(Vector3(v.x,v.y,0.0))

	for u in data.uvs:
		uvs.append(u)

	indices = PackedInt32Array([
		0, 1, 2,
		1, 3, 2
	])

	normals = PackedVector3Array([
	Vector3(0.0, 0.0, 1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(0.0, 0.0, 1.0)
	])

	# Append vertices, normals, and UVs to arrays.
	verts.append_array(verts)
	normals.append_array(normals)
	uvs.append_array(uvs)
	indices.append_array(indices)


	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	var instance := MeshInstance2D.new()
	instance.mesh = mesh
	add_child(instance)
	instance.owner = owner
	instance.global_position = global_position



	pass
