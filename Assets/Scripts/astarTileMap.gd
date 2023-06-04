extends TileMap
class_name AstarTileMap

const DIRECTIONS := [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]
const PAIRING_LIMIT = int(pow(2, 30))
enum pairing_methods {
	CANTOR_UNSIGNED,	# positive values only
	CANTOR_SIGNED,		# both positive and negative values	
	SZUDZIK_UNSIGNED,	# more efficient than cantor
	SZUDZIK_SIGNED,		# both positive and negative values
	SZUDZIK_IMPROVED,	# improved version (best option)
}

@export var current_pairing_method : pairing_methods = pairing_methods.SZUDZIK_IMPROVED
@export var diagonals := true

var astar := AStar2D.new()
var obstacles := []
var units := []

func _ready() -> void:
	update()

func update() -> void:
	create_pathfinding_points()
	
	var unitNodes = get_tree().get_nodes_in_group("Units")
	for unitNode in unitNodes:
		add_unit(unitNode)
	
	var obstacleNodes = get_tree().get_nodes_in_group("Obstacles")
	for obstacleNode in obstacleNodes:
		add_obstacle(obstacleNode)

func create_pathfinding_points() -> void:
	astar.clear()
	var used_cell_positions = get_used_cell_global_positions()
	
	for cell_position in used_cell_positions:
		astar.add_point(get_point(cell_position), cell_position)

	for cell_position in used_cell_positions:
		connect_cardinals(cell_position)

func add_obstacle(obstacle: Object) -> void:
	obstacles.append(obstacle)
	
	if not obstacle.tree_exiting.is_connected(remove_obstacle):
		var _error = obstacle.tree_exiting.connect(remove_obstacle.bind([obstacle]))
		if _error != 0: push_error(str(obstacle) + ": failed connect() function")
	

func remove_obstacle(obstacle: Object) -> void:
	obstacles.erase(obstacle)

func add_unit(unit: Object) -> void:
	units.append(unit)
	
	if not unit.tree_exiting.is_connected(remove_unit):
		var _error = unit.tree_exiting.connect(remove_unit.bind([unit]))
		if _error != 0: push_error(str(unit) + ": failed connect() function")
	

func remove_unit(unit: Object) -> void:
	units.erase(unit)

func position_has_obstacle(obstacle_position: Vector2, ignore_obstacle_position = null) -> bool:
	if obstacle_position == ignore_obstacle_position: return false
	
	for obstacle in obstacles:
		if obstacle.global_position == obstacle_position: return true
	
	return false

func position_has_unit(unit_position: Vector2, ignore_unit_position = null) -> bool:
	if unit_position == ignore_unit_position: return false
	
	for unit in units:
		if unit.global_position == unit_position: return true
	
	return false

func get_astar_path_avoiding_obstacles_and_units(start_pos: Vector2, end_pos: Vector2, exception_units := [], max_distance := -1) -> Array:
	set_obstacles_points_disabled(true)
	set_unit_points_disabled(true, exception_units)
	var astar_path := astar.get_point_path(get_point(start_pos), get_point(end_pos))
	set_obstacles_points_disabled(false)
	set_unit_points_disabled(false)
	return set_path_length(astar_path, max_distance)

func get_astar_path_avoiding_obstacles(start_pos: Vector2, end_pos: Vector2, max_distance := -1) -> Array:
	set_obstacles_points_disabled(true)
	var astar_path := astar.get_point_path(get_point(start_pos), get_point(end_pos))
	set_obstacles_points_disabled(false)
	return set_path_length(astar_path, max_distance)

func stop_path_at_unit(potential_path_points: Array) -> Array:
	for i in range(1, potential_path_points.size()):
		var point : Vector2 = potential_path_points[i]
		if position_has_unit(point):
			potential_path_points.resize(i)
			break
	
	return potential_path_points

func get_astar_path(start_pos: Vector2, end_pos: Vector2, max_distance := -1) -> Array:
	var astar_path := astar.get_point_path(get_point(start_pos), get_point(end_pos))
	
	return set_path_length(astar_path, max_distance)

func set_path_length(point_path: Array, max_distance: int) -> Array:
	if max_distance < 0: return point_path
	
	var new_size := int(min(point_path.size(), max_distance))
	point_path.resize(new_size)
	return point_path

func set_obstacles_points_disabled(value: bool) -> void:
	for obstacle in obstacles:
		astar.set_point_disabled(get_point(obstacle.global_position), value)

func set_unit_points_disabled(value: bool, exception_units: Array = []) -> void:
	for unit in units:
		if unit in exception_units or unit.owner in exception_units:
			continue
		
		astar.set_point_disabled(get_point(unit.global_position), value)

func get_floodfill_positions(start_pos: Vector2, min_range: int, max_range: int, skip_obstacles := true, skip_units := true, return_center := false) -> Array:
	var floodfill_poss := []
	var checking_pos := [start_pos]
	
	while not checking_pos.is_empty():
		var cur_pos : Vector2 = checking_pos.pop_back()
		
		if skip_obstacles and position_has_obstacle(cur_pos, start_pos): continue
		if skip_units and position_has_unit(cur_pos, start_pos): continue
		if cur_pos in floodfill_poss: continue
		
		var cur_point := get_point(cur_pos)
		if not astar.has_point(cur_point): continue
		if astar.is_point_disabled(cur_point): continue
		
		var distance := (cur_pos - start_pos)
		var grid_dis := get_grid_distance(distance)
		if grid_dis > max_range: continue
		
		floodfill_poss.append(cur_pos)
		
		for dir in DIRECTIONS:
			var new_pos := cur_pos + map_to_local(dir)
			if skip_obstacles and position_has_obstacle(new_pos): continue
			if skip_units and position_has_unit(new_pos): continue
			if new_pos in floodfill_poss: continue
			
			var new_point := get_point(new_pos)
			if not astar.has_point(new_point): continue
			if astar.is_point_disabled(new_point): continue
			
			checking_pos.append(new_pos)
	
	if not return_center:
		floodfill_poss.erase(start_pos)
	
	var floodfill_pos_size := floodfill_poss.size()
	
	for i in floodfill_pos_size:
		var floodfill_pos : Vector2 = floodfill_poss[floodfill_pos_size - i - 1]
		var distance = (floodfill_pos - start_pos)
		var grid_distance := get_grid_distance(distance)
		
		if grid_distance < min_range:
			floodfill_poss.erase(floodfill_pos)
	
	return floodfill_poss

func path_directions(path) -> Array:
	var directions = []
	
	for p in range(1, path.size()):
		directions.append(path[p] - path[p - 1])
	
	return directions

func get_point(point_position: Vector2) -> int:
	var a := int(point_position.x)
	var b := int(point_position.y)
	match current_pairing_method:
		pairing_methods.CANTOR_UNSIGNED:
			assert(a >= 0 and b >= 0, "Board: pairing method has failed. Choose method that supports negative values.")
			return cantor_pair(a, b)
		pairing_methods.SZUDZIK_UNSIGNED:
			assert(a >= 0 and b >= 0, "Board: pairing method has failed. Choose method that supports negative values.")			
			return szudzik_pair(a, b)
		pairing_methods.CANTOR_SIGNED:
			return cantor_pair_signed(a, b)	
		pairing_methods.SZUDZIK_SIGNED:
			return szudzik_pair_signed(a, b)
		pairing_methods.SZUDZIK_IMPROVED:
			return szudzik_pair_improved(a, b)
	return szudzik_pair_improved(a, b)

func cantor_pair(a:int, b:int) -> int:
	var result := 0.5 * (a + b) * (a + b + 1) + b
	return int(result)

func cantor_pair_signed(a:int, b:int) -> int:
	if a >= 0:
		a = a * 2
	else:
		a = (a * -2) - 1
	if b >= 0:
		b = b * 2
	else:
		b = (b * -2) - 1
	return cantor_pair(a, b)

func szudzik_pair(a:int, b:int) -> int:
	if a >= b: 
		return (a * a) + a + b
	else: 
		return (b * b) + a	

func szudzik_pair_signed(a: int, b: int) -> int:
	if a >= 0: 
		a = a * 2
	else: 
		a = (a * -2) - 1
	if b >= 0:
		b = b * 2
	else: 
		b = (b * -2) - 1
	return int(szudzik_pair(a, b))

func szudzik_pair_improved(x:int, y:int) -> int:
	var a: int
	var b: int
	if x >= 0:
		a = x * 2
	else: 
		a = (x * -2) - 1
	if y >= 0: 
		b = y * 2
	else: 
		b = (y * -2) - 1	
	var c = szudzik_pair(a,b)
	if a >= 0 and b < 0 or b >= 0 and a < 0:
		return -c - 1
	return c

func has_point(point_position: Vector2) -> bool:
	var point_id := get_point(point_position)
	return astar.has_point(point_id)

func get_used_cell_global_positions() -> Array:
	var cells = get_used_cells(0)
	var cell_positions := []
	for cell in cells:
		var cell_position := global_position + map_to_local(cell)
		cell_positions.append(cell_position)
	return cell_positions

func connect_cardinals(point_position) -> void:
	var center := get_point(point_position)
	var directions := DIRECTIONS
	
	if diagonals: 
		var diagonals_array := [Vector2(1,1), Vector2(1,-1)]	# Only two needed for generation
		directions += diagonals_array
	
	for direction in directions:
		var cardinal_point := get_point(point_position + map_to_local(direction))
		if cardinal_point != center and astar.has_point(cardinal_point):
			astar.connect_points(center, cardinal_point, true)

func get_grid_distance(distance: Vector2) -> float:
	var vec := map_to_local(distance).abs().floor()
	return vec.x + vec.y
