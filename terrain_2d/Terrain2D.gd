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

@export_category("Terrain UV")
@export_range(0.0001,100,.001) var uv_scale:float = 1.0:
	set(value):
		uv_scale = value
		for child in get_children():
			child.polygons_updated.emit(child)
		pass

@export_category("Terrain Borders")
@export var border_scale:float = 4.0:
	set(value):
		border_scale = value
		for child in get_children():
			child.square_scale = value
			child.queue_redraw()

func _enter_tree() -> void:
	#set_process(false)
	child_entered_tree.connect(_on_child_entered)
	if terrain_resource != null: return
	update_configuration_warnings()

func _get_configuration_warnings() -> PackedStringArray:

	if terrain_resource == null:
		return ["TerrainResource must be created"]

	return []

func _on_child_entered(node:Node) -> void:
	node.update_configuration_warnings()
	if node is Island2D:
		node.terrain = self
	pass

func on_polygons_updated(island:Island2D) -> void:
	create_mesh(island.polygons, island.name)
	island.queue_redraw()
	pass

func create_mesh(polygons:PackedVector2Array,uid:String) -> void:
	var target_mesh := PackedVector2Array()
	var triangles: PackedInt32Array = Geometry2D.triangulate_polygon(polygons)

	if triangles.size() < 1:
		push_error("there was an error creating the mesh")
		return

	var st := SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	#calculate UV to 0-1 range values

	var min_uv := Vector2.ONE * INF
	var max_uv := Vector2.ONE * -INF

	for i in range(0, triangles.size(), 3):

		var vert1_index := triangles[i]
		var vert2_index := triangles[i+1]
		var vert3_index := triangles[i+2]

		var vert1 := polygons[vert1_index]
		var vert2 := polygons[vert2_index]
		var vert3 := polygons[vert3_index]

		target_mesh.append_array([vert1,vert2,vert3])
		pass

	for vertex in target_mesh:
		min_uv.x = min(min_uv.x , vertex.x)
		min_uv.y = min(min_uv.y , vertex.y)

		max_uv.x = max(max_uv.x , vertex.x)
		max_uv.y = max(max_uv.y , vertex.y)
		pass

	var scale_uv := Vector2(uv_scale / (max_uv.x - min_uv.x), uv_scale / (max_uv.y - min_uv.y))
	var target_mesh_uv := PackedVector2Array()

	for i in range(target_mesh.size()):
		var vertex = target_mesh[i]
		vertex = Vector2( (vertex.x - min_uv.x) * scale_uv.x,
						  (vertex.y - min_uv.y) * scale_uv.y )
		target_mesh_uv.push_back( vertex )
		pass
	print(target_mesh_uv)
	#end uv calculation
	target_mesh.clear() # TODO: we can remove the vert1,2,3 from below because we already calculated above in UV
	# but I'm keeping just for testing purposes

	for i in range(0,triangles.size(), 3):

		var vert1_index := triangles[i]
		var vert2_index := triangles[i+1]
		var vert3_index := triangles[i+2]

		var vert1 := polygons[vert1_index]
		var vert2 := polygons[vert2_index]
		var vert3 := polygons[vert3_index]

		var uv1 := target_mesh_uv[i]
		var uv2 := target_mesh_uv[i+1]
		var uv3 := target_mesh_uv[i+2]

		target_mesh.append_array([vert1,vert2,vert3])

		st.set_uv(uv1)
		st.add_vertex(Vector3(vert1.x,vert1.y,0))
		st.set_uv(uv2)
		st.add_vertex(Vector3(vert2.x,vert2.y,0))
		st.set_uv(uv3)
		st.add_vertex(Vector3(vert3.x,vert3.y,0))



		pass
	var arr_mesh := st.commit()
	#meshes[uid] = arr_mesh


	pass
