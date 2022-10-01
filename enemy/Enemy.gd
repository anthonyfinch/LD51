extends KinematicBody

enum EnemyState {
	Scanning,
	Wandering
}

export (float) var turn_speed := 1.0
export (EnemyState) var state = EnemyState.Scanning
export (float) var scan_time := 4.0

onready var nav_agent : NavigationAgent = $NavigationAgent
onready var timer : Timer = $Timer
onready var test_pos : Position3D = get_node("../Position3D")
onready var rad := PI / 180
onready var patrol_points = get_tree().get_nodes_in_group("patrol_points")

var target := Vector3.ZERO


func _ready():
	randomize()
	timer.connect("timeout", self, "_on_timeout")
	_start_scanning()


func _on_timeout():
	match state:
		EnemyState.Scanning:
			var idx = randi() % patrol_points.size()
			target = patrol_points[idx].global_transform.origin
			var map_rid = nav_agent.get_navigation_map()
			var closest = NavigationServer.map_get_closest_point(map_rid, target)
			nav_agent.set_target_location(closest)

			state = EnemyState.Wandering


func _physics_process(_delta):
	match state:
		EnemyState.Scanning:
			rotate_y(rad * turn_speed)
		EnemyState.Wandering:
			_navigate_to_point()


func _start_scanning():
	state = EnemyState.Scanning
	timer.wait_time = scan_time
	timer.start()


func _navigate_to_point():
	var next_move = nav_agent.get_next_location()
	var dir = (next_move - get_global_transform().origin).normalized()

	look_at(next_move, Vector3.UP)

	if not nav_agent.is_navigation_finished():
		move_and_slide(dir * 5.0)
	else:
		_start_scanning()
