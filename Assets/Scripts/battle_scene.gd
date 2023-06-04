extends Node2D

@export var board : TileMap
@export var astarDebug : Control
@export var player : Node2D
@export var line : Line2D

func _input(event):
	var cell_size = board.tile_set.tile_size
	
	if event.is_action_pressed("mouse_left"):
		var target_cell = (event.position / cell_size).floor() * cell_size
		var path_points = board.get_astar_path_avoiding_obstacles_and_units(player.global_position, target_cell)
		line.position = cell_size/2
		line.points = path_points
	
	if event.is_action_pressed("mouse_right"):
		line.points = []
	
	if event.is_action_pressed("ui_accept"):
		astarDebug.visible = !astarDebug.visible
