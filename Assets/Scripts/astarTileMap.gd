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
	pass

func add_obstacle(obstacle: Object) -> void:
	pass

func remove_obstacle(obstacle: Object) -> void:
	pass

func add_unit(unit: Object) -> void:
	pass

func remove_unit(unit: Object) -> void:
	pass
