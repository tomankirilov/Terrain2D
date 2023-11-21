@tool
extends RefCounted
class_name Island2D

var polygons:PackedVector2Array
var center:Vector2

func get_aabb() -> Rect2:
	return Terrain2DPlugin.create_aabb(self)

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
