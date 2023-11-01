@tool
extends MeshInstance2D
class_name TerrainInstance2D

@export var polygons:PackedVector2Array
const POLY_SIZE := 10.0
var is_over_index:int = -1
var is_selecting_add:bool = false
var add_after_index:int = -1


@export var crmesh:bool = false :
	set(value):
		crmesh = value
		create_mesh()

func create_basic_shape() -> void: #create the initial shape
	if polygons.size() > 0: return
	is_over_index = -1
	var DIST := 64.0
	
	polygons.push_back(Vector2(-DIST,-DIST))
	polygons.push_back(Vector2(DIST,-DIST))
	polygons.push_back(Vector2(DIST,DIST))
	polygons.push_back(Vector2(-DIST,DIST))
	
	print("basic shape created")
	pass

func just_selected() -> void:
	create_basic_shape()
	queue_redraw()
	pass



func _draw() -> void:
	if !Engine.is_editor_hint(): return
	if polygons.size() == 0: return
	
	draw_polyline(polygons,Color.WHITE_SMOKE,1) # all other connections
	draw_line(polygons[-1],polygons[0],Color.WHITE_SMOKE, 1) #the last polygon connects to the first one
	for poly in polygons:
		var rect := Rect2(Vector2.ONE * poly,Vector2(POLY_SIZE*2,POLY_SIZE*2))
		rect.position -= POLY_SIZE * Vector2.ONE
		draw_texture_rect(Terrain2D.ICONS.POLY,rect, false)
		pass
	check_mouse()
	move_polygon()
	
	draw_target_mesh()

func draw_target_mesh() -> void:
	if target_mesh.size() < 3: return
	var color := Color.BLACK
	var size := 1.0
	for i in range(0,target_mesh.size(),3):
		draw_line(target_mesh[i],target_mesh[i+1],color, size, true)
		draw_line(target_mesh[i+1],target_mesh[i+2],color, size, true)
		draw_line(target_mesh[i+2],target_mesh[i],color, size, true)
		pass
	pass

var mouse_pos := Vector2()
func check_mouse() -> void:
	
	#debug draw mouse
	mouse_pos = EditorInterface.get_editor_viewport_2d().get_mouse_position() - global_position
	draw_circle(mouse_pos, POLY_SIZE * .5, Color.BLACK)
	
	
	# polygon mouse hover effect
	var index := 0
	for poly in polygons:
		if is_circle_circle_collision(mouse_pos, poly):
			var rect := Rect2(Vector2.ONE * poly,Vector2(POLY_SIZE*2,POLY_SIZE*2))
			rect.position -= POLY_SIZE * Vector2.ONE
			draw_texture_rect(Terrain2D.ICONS.POLY,rect, false,Color.AQUA)
			is_over_index = index
			pass
		index += 1
		pass
	
	# draw (+) icon in middle of the lines and line hover effect
	for i in range(polygons.size()-1):
		var polygon_start := polygons[i]
		var polygon_end := polygons[(i+1) % polygons.size()]
		if is_circle_line_collision(mouse_pos, POLY_SIZE, polygon_start, polygon_end):
			draw_line(polygon_start,polygon_end,Color.AQUA,1.2)
			var rect := Rect2(get_line_midpoint(polygon_start,polygon_end),Vector2(POLY_SIZE*2,POLY_SIZE*2))
			rect.position -= POLY_SIZE * Vector2.ONE
			draw_texture_rect(Terrain2D.ICONS.ADD,rect, false)
			
			if is_circle_circle_collision(mouse_pos, rect.position + POLY_SIZE * Vector2.ONE, 20.0):
				draw_texture_rect(Terrain2D.ICONS.ADD,rect, false,Color.LIME)
				is_selecting_add = true
				add_after_index = i
				pass
			else: 
				is_selecting_add = false
				add_after_index = -1
			
			return #return statement here make sure only one line can be selected at time
		pass
		
	#is_circle_line_collision(mouse_pos, POLY_SIZE,polygons[0],polygons[1])
	
	pass

var left_mouse_holding:bool = false
func on_mouse_pressed(event:InputEventMouseButton) -> void:
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		left_mouse_holding = true
		check_add_button_pressed()
	else: left_mouse_holding = false
	pass

func move_polygon() -> void:
	if is_over_index < 0: return
	if not left_mouse_holding: 
		is_over_index = -1
		return
	polygons[is_over_index] = mouse_pos
	pass

func check_add_button_pressed() -> void:
	if not is_selecting_add: return
	if add_after_index < 0: return
	
	polygons.insert(add_after_index+1,mouse_pos)
	queue_redraw()

func is_circle_line_collision(circle_center:Vector2, circle_radius:float, line_start:Vector2, line_end:Vector2) -> bool:
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

func is_circle_circle_collision(circle_a:Vector2, circle_b:Vector2, radius:float = POLY_SIZE * 10) -> bool:
	
	var dist := pow(circle_a.x - circle_b.x, 2) + pow(circle_a.y - circle_b.y, 2)
	
	if dist < radius:
		return true
	
	return false

func get_line_midpoint(line_start:Vector2, line_end:Vector2, offset:float = 0.0) -> Vector2:
	return ( (line_start + line_end) * .5 ) - Vector2.ONE * offset

var target_mesh := PackedVector2Array()

func create_mesh() -> void:
	print("creating mesh")
	target_mesh = PackedVector2Array()
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygons)
	
	if triangles.size() < 1: 
		push_error("there was an error creating the mesh")
		return
		
	var st := SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(0,triangles.size(), 3):
		
		var vert1_index := triangles[i]
		var vert2_index := triangles[i+1]
		var vert3_index := triangles[i+2]
		
		var vert1 := polygons[vert1_index]
		var vert2 := polygons[vert2_index]
		var vert3 := polygons[vert3_index]
		
		target_mesh.append_array([vert1,vert2,vert3])
		
		st.set_color(Color.RED)
		st.set_uv(vert1)
		#st.add_index(vert1_index)
		st.add_vertex(Vector3(vert1.x,vert1.y,0))
		#st.add_index(vert2_index)
		st.set_uv(vert2)
		st.add_vertex(Vector3(vert2.x,vert2.y,0))
		#st.add_index(vert3_index)
		st.set_uv(vert3)
		st.add_vertex(Vector3(vert3.x,vert3.y,0))
		
		
		
		pass
	var arr_mesh := st.commit()
	print(target_mesh)
	mesh = arr_mesh
	
	
	pass
