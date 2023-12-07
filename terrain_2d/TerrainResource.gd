@tool
extends Resource
class_name TerrainResource


@export var center_material:Terrain2DMaterial:
	set(value):
		center_material = value
		center_material.shader = load("res://addons/terrain_2d/shaders/sh_terrain2D_center.gdshader")


@export var border_material:Terrain2DMaterial:
	set(value):
		border_material = value
		border_material.shader = load("res://addons/terrain_2d/shaders/sh_terrain2d_border.gdshader")

func get_texture_region(index:int) -> void:

	pass


