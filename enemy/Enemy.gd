extends KinematicBody

enum EnemyState {
	Scanning,
	Wandering,
	Investigating,
	Waiting,
	Attacking
}

export (float) var turn_speed := 0.4
export (EnemyState) var state = EnemyState.Scanning
export (float) var scan_time := 6.0
export (float) var wait_time := 4.0
export (float) var investigate_time := 10.0
export (float) var wander_speed := 1.0
export (float) var investigate_speed := 2.0
export (float) var attack_speed := 5.0
export (float) var total_visibility_cutoff := 0.65
export (float) var partial_visibility_cutoff := 0.15

onready var nav_agent : NavigationAgent = $NavigationAgent
onready var timer : Timer = $Timer
onready var vision_cone : Area = $VisionCone
onready var rad := PI / 180
onready var patrol_points = get_parent().find_node("PatrolPoints").get_children()
# onready var label = $Label

var target := Vector3.ZERO


func _ready():
	randomize()
	timer.connect("timeout", self, "_on_timeout")
	_start_scanning(scan_time)

func _set_path():
	var map_rid = nav_agent.get_navigation_map()
	var closest = NavigationServer.map_get_closest_point(map_rid, target)
	nav_agent.set_target_location(closest)

func _on_timeout():
	match state:
		EnemyState.Scanning:
			var idx = randi() % patrol_points.size()
			target = patrol_points[idx].global_transform.origin
			_set_path()
			state = EnemyState.Wandering
		EnemyState.Waiting:
			_start_scanning(investigate_time)

# func _process(_delta):
# 	var debug_text = ""
# 	match state:
# 		EnemyState.Attacking:
# 			debug_text = "Attacking"
# 		EnemyState.Investigating:
# 			debug_text = "Investigating"
# 		EnemyState.Scanning:
# 			debug_text = "Scanning"
# 		EnemyState.Wandering:
# 			debug_text = "Wandering"
# 		EnemyState.Waiting:
# 			debug_text = "Waiting"
# 	label.text = debug_text

func _check_for_player():
	var bodies = vision_cone.get_overlapping_bodies()
	if bodies.size() > 0:
		var possible_body = bodies[0]
		if possible_body is Player:
			var space_state = get_world().direct_space_state
			var from = global_transform.origin
			var to = possible_body.head.global_transform.origin
			var result = space_state.intersect_ray(from, to, [self])
			if result:
				var body = result['collider']
				if body is Player:
					if body.visibility > total_visibility_cutoff:
						target = body.global_transform.origin
						_set_path()
						state = EnemyState.Attacking
						# print("I can see you")
					elif body.visibility > partial_visibility_cutoff:
						target = body.global_transform.origin
						_set_path()
						state = EnemyState.Investigating
						# print("Who goes there?")
					else:
						pass
						# print("Huh, nothing to see")

func _physics_process(_delta):
	if not GameState.paused:
		_check_for_player()
		match state:
			EnemyState.Scanning:
				global_rotate(Vector3.UP, rad * turn_speed)
			EnemyState.Wandering:
				var done = _navigate_to_point(wander_speed)
				if done:
					_start_scanning(scan_time)
			EnemyState.Investigating:
				var done = _navigate_to_point(investigate_speed)
				if done:
					_start_waiting()
			EnemyState.Attacking:
				var done = _navigate_to_point(attack_speed)
				if done:
					_start_scanning(investigate_time)

		var coll_count = get_slide_count()
		for coll_idx in range(coll_count):
			var coll = get_slide_collision(coll_idx)
			var body = coll.collider
			if body is Player:
				body.die()

func _start_waiting():
	state = EnemyState.Waiting
	timer.wait_time = wait_time
	timer.start()

func _start_scanning(time):
	state = EnemyState.Scanning
	timer.wait_time = time
	timer.start()

func _navigate_to_point(speed):
	var next_move = nav_agent.get_next_location()
	var dir = (next_move - get_global_transform().origin).normalized()


	# rotate smoothly to look at the next point
	rotation.y = lerp(rotation.y, atan2(-dir.x, -dir.z), 0.1)

	if not nav_agent.is_navigation_finished():
		move_and_slide(dir * speed)
		return false
	else:
		return true

func hear_movement(body):
	target = body.global_transform.origin
	_set_path()
	state = EnemyState.Investigating
