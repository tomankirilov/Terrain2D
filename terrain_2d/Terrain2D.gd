@tool
extends Node2D
class_name Terrain2D


@export var terrain_resource:TerrainResource :
	set(value):
		terrain_resource = value
		update_configuration_warnings()
		queue_redraw()
		Terrain2D_MenuButtons.enable_add_island(value != null)
	get:
		return terrain_resource

var selected_island:Island2D = null

func _enter_tree() -> void:
	#set_process(false)
	if terrain_resource != null: return
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:
	
	if terrain_resource == null:
		return ["TerrainResource must be created"]
	
	return []

func _process(delta: float) -> void:
	if Terrain2DPlugin.selected_terrain != self: return
	queue_redraw()



#
#@export var polygons:PackedVector2Array
#const POLY_SIZE := 10.0
#var is_over_index:int = -1
#var is_selecting_add:bool = false
#var add_after_index:int = -1
#
#
#@export var crmesh:bool = false :
	#set(value):
		#crmesh = value
		#create_mesh()

func create_basic_shape(island:Island2D) -> void: #create the initial shape
	var DIST := 64.0
	island.add_polygon(Vector2(-DIST,-DIST))
	island.add_polygon(Vector2(DIST,-DIST))
	island.add_polygon(Vector2(DIST,DIST))
	island.add_polygon(Vector2(-DIST,DIST))
	
	terrain_resource.islands.push_back(island)
	print("basic shape created")
	
	queue_redraw()
	
	
	pass

func just_selected() -> void:
	queue_redraw()
	pass

const POLY_SIZE = 16
#called by Terrain2DPlugin
func _draw() -> void:
	if terrain_resource == null: return
	if terrain_resource.islands.size() < 1: return
	
	for island:Island2D in terrain_resource.islands:
		draw_polygons_connection(island)
		draw_move_button(island)
		check_edit_line(island)
		var poly_index:int = 0
		for poly:Vector2 in island.polygons:
			draw_custom_icon(poly)
			check_edit_polygon(poly,poly_index, island)
			poly_index += 1
		#draw_island_aabb(island)
		pass
	
	pass

func draw_island_aabb(island:Island2D) -> void:
	var rect := island.get_aabb()
	rect.size = rect.size * 1.2
	rect.position = island.center
	draw_rect(rect, Color.SALMON,false,2.0)
	pass

func draw_polygons_connection(island:Island2D) -> void:
	draw_polyline(island.polygons,Color.WHITE_SMOKE,2) # all other connections
	draw_line(island.polygons[-1],island.polygons[0],Color.WHITE_SMOKE, 2) #the last polygon connects to the first one
	pass

func draw_custom_icon(at:Vector2, modulate:Color=Color.WHITE, icon:CompressedTexture2D=Terrain2DPlugin.ICONS.POLY,icon_scale:float=1.0) -> void:
	var rect := Rect2(Vector2.ONE * at,Vector2(POLY_SIZE*2,POLY_SIZE*2))
	rect.size *= icon_scale
	rect.position -= POLY_SIZE * Vector2.ONE
	draw_texture_rect(icon,rect, false, modulate)
	pass

func draw_move_button(island:Island2D) -> void:
	var rect := Rect2()
	rect.size = Vector2(32,32)
	rect.position = island.center - (rect.size * .5)
	draw_texture_rect(Terrain2DPlugin.ICONS.MOVE, rect, false)
	draw_arc(island.center,10,0,360,16,Color.RED)
	#print("draw move button")
	pass



func left_clicked(pos:Vector2) -> void:
	check_move_island()
	
func check_move_island() -> void:
	var pos := get_local_mouse_position()
	print("clicked at: ", pos)
	for island:Island2D in terrain_resource.islands:
		if Terrain2DPlugin.is_circle_circle_collision(island.center, get_global_mouse_position(), 32.0):
			while(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
				island.move_polygons(get_global_mouse_position())
				queue_redraw()
				await get_tree().process_frame
			island.recalculate_center()

func check_edit_polygon(poly:Vector2, index:int, island:Island2D) -> void:
	if not Terrain2DPlugin.is_circle_circle_collision(poly,get_global_mouse_position(),POLY_SIZE * 6): return
	
	draw_custom_icon(poly,Color.AQUA)
	while(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		island.polygons[index] = get_global_mouse_position()
		#island.recalculate_center()
		
		await get_tree().process_frame
	pass

func check_edit_line(island:Island2D) -> void:
	for i in range(island.polygons.size()-1):
		var polygon_start := island.polygons[i]
		var polygon_end := island.polygons[(i+1) % island.polygons.size()]
		if not Terrain2DPlugin.is_circle_line_collision(polygon_start,polygon_end,get_global_mouse_position(),POLY_SIZE,.9): continue
		draw_line(polygon_start,polygon_end,Color.AQUA,3.0)
		var line_center := Terrain2DPlugin.get_line_midpoint(polygon_start, polygon_end)
		draw_custom_icon(line_center, Color.WHITE, Terrain2DPlugin.ICONS.ADD)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			island.polygons.insert(i+1,get_global_mouse_position())
			queue_redraw()
			break
	pass

#
#func _draw() -> void:
	#if !Engine.is_editor_hint(): return
	#if polygons.size() == 0: return
	#
	#draw_polyline(polygons,Color.WHITE_SMOKE,1) # all other connections
	#draw_line(polygons[-1],polygons[0],Color.WHITE_SMOKE, 1) #the last polygon connects to the first one
	#for poly in polygons:
		#var rect := Rect2(Vector2.ONE * poly,Vector2(POLY_SIZE*2,POLY_SIZE*2))
		#rect.position -= POLY_SIZE * Vector2.ONE
		#draw_texture_rect(Terrain2D.ICONS.POLY,rect, false)
		#pass
	#check_mouse()
	#move_polygon()
	#
	#draw_target_mesh()
#
#func draw_target_mesh() -> void:
	#if target_mesh.size() < 3: return
	#var color := Color.BLACK
	#var size := 1.0
	#for i in range(0,target_mesh.size(),3):
		#draw_line(target_mesh[i],target_mesh[i+1],color, size, true)
		#draw_line(target_mesh[i+1],target_mesh[i+2],color, size, true)
		#draw_line(target_mesh[i+2],target_mesh[i],color, size, true)
		#pass
	#pass
#
#var mouse_pos := Vector2()
#func check_mouse() -> void:
	#
	##debug draw mouse
	#mouse_pos = EditorInterface.get_editor_viewport_2d().get_mouse_position() - global_position
	#draw_circle(mouse_pos, POLY_SIZE * .5, Color.BLACK)
	#
	#
	## polygon mouse hover effect
	#var index := 0
	#for poly in polygons:
		#if Terrain2D.is_circle_circle_collision(mouse_pos, poly, POLY_SIZE * 10):
			#var rect := Rect2(Vector2.ONE * poly,Vector2(POLY_SIZE*2,POLY_SIZE*2))
			#rect.position -= POLY_SIZE * Vector2.ONE
			#draw_texture_rect(Terrain2D.ICONS.POLY,rect, false,Color.AQUA)
			#is_over_index = index
			#pass
		#index += 1
		#pass
	#
	## draw (+) icon in middle of the lines and line hover effect
	#for i in range(polygons.size()-1):
		#var polygon_start := polygons[i]
		#var polygon_end := polygons[(i+1) % polygons.size()]
		#if Terrain2D.is_circle_line_collision(mouse_pos, POLY_SIZE, polygon_start, polygon_end):
			#draw_line(polygon_start,polygon_end,Color.AQUA,1.2)
			#var rect := Rect2(Terrain2D.get_line_midpoint(polygon_start,polygon_end),Vector2(POLY_SIZE*2,POLY_SIZE*2))
			#rect.position -= POLY_SIZE * Vector2.ONE
			#draw_texture_rect(Terrain2D.ICONS.ADD,rect, false)
			#
			#if Terrain2D.is_circle_circle_collision(mouse_pos, rect.position + POLY_SIZE * Vector2.ONE, 20.0):
				#draw_texture_rect(Terrain2D.ICONS.ADD,rect, false,Color.LIME)
				#is_selecting_add = true
				#add_after_index = i
				#pass
			#else: 
				#is_selecting_add = false
				#add_after_index = -1
			#
			#return #return statement here make sure only one line can be selected at time
		#pass
		#
	##is_circle_line_collision(mouse_pos, POLY_SIZE,polygons[0],polygons[1])
	#
	#pass
#

#
#func move_polygon() -> void:
	#if is_over_index < 0: return
	#if not left_mouse_holding: 
		#is_over_index = -1
		#return
	#polygons[is_over_index] = mouse_pos
	#pass
#
#func check_add_button_pressed() -> void:
	#if not is_selecting_add: return
	#if add_after_index < 0: return
	#
	#polygons.insert(add_after_index+1,mouse_pos)
	#queue_redraw()
#
#
#
#
#var target_mesh := PackedVector2Array()
#
#func create_mesh() -> void:
	#print("creating mesh")
	#target_mesh = PackedVector2Array()
	#var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygons)
	#
	#if triangles.size() < 1: 
		#push_error("there was an error creating the mesh")
		#return
		#
	#var st := SurfaceTool.new()
	#
	#st.begin(Mesh.PRIMITIVE_TRIANGLES)
	#
	##calculate UV to 0-1 range values
	#
	#var min_uv := Vector2.ONE * INF
	#var max_uv := Vector2.ONE * -INF
	#
	#for i in range(0, triangles.size(), 3):
		#
		#var vert1_index := triangles[i]
		#var vert2_index := triangles[i+1]
		#var vert3_index := triangles[i+2]
		#
		#var vert1 := polygons[vert1_index]
		#var vert2 := polygons[vert2_index]
		#var vert3 := polygons[vert3_index]
		#
		#target_mesh.append_array([vert1,vert2,vert3])
		#pass
	#
	#for vertex in target_mesh:
		#min_uv.x = min(min_uv.x , vertex.x)
		#min_uv.y = min(min_uv.y , vertex.y)
		#
		#max_uv.x = max(max_uv.x , vertex.x)
		#max_uv.y = max(max_uv.y , vertex.y)
		#pass
	#
	#var scale_uv := Vector2(1.0 / (max_uv.x - min_uv.x), 1.0 / (max_uv.y - min_uv.y))
	#var target_mesh_uv := PackedVector2Array()
	#
	#for i in range(target_mesh.size()):
		#var vertex = target_mesh[i]
		#vertex = Vector2( (vertex.x - min_uv.x) * scale_uv.x,
						  #(vertex.y - min_uv.y) * scale_uv.y )
		#target_mesh_uv.push_back( vertex )
		#pass
	#print(target_mesh_uv)
	##end uv calculation
	#target_mesh.clear() # TODO: we can remove the vert1,2,3 from below because we already calculated above in UV
	## but I'm keeping just for testing purposes
	#
	#for i in range(0,triangles.size(), 3):
		#
		#var vert1_index := triangles[i]
		#var vert2_index := triangles[i+1]
		#var vert3_index := triangles[i+2]
		#
		#var vert1 := polygons[vert1_index]
		#var vert2 := polygons[vert2_index]
		#var vert3 := polygons[vert3_index]
		#
		#var uv1 := target_mesh_uv[i]
		#var uv2 := target_mesh_uv[i+1]
		#var uv3 := target_mesh_uv[i+2]
		#
		#target_mesh.append_array([vert1,vert2,vert3])
		#
		#st.set_color(Color.RED)
		#st.set_uv(uv1)
		#st.add_vertex(Vector3(vert1.x,vert1.y,0))
		#st.set_uv(uv2)
		#st.add_vertex(Vector3(vert2.x,vert2.y,0))
		#st.set_uv(uv3)
		#st.add_vertex(Vector3(vert3.x,vert3.y,0))
		#
		#
		#
		#pass
	#var arr_mesh := st.commit()
	#print(target_mesh)
	#mesh = arr_mesh
	#
	#
	#pass
