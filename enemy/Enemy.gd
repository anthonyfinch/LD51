extends KinematicBody

enum EnemyState {
	Scanning,
	Wandering,
	Investigating,
	Attacking
}

export (float) var turn_speed := 1.0
export (EnemyState) var state = EnemyState.Scanning
export (float) var scan_time := 4.0
export (float) var wander_speed := 2.0
export (float) var attack_speed := 5.0
export (float) var total_visibility_cutoff := 0.75
export (float) var partial_visibility_cutoff := 0.15

onready var nav_agent : NavigationAgent = $NavigationAgent
onready var timer : Timer = $Timer
onready var vision_cone : Area = $VisionCone
onready var vision_ray : RayCast = $VisionCone/RayCast
onready var rad := PI / 180
onready var patrol_points = get_tree().get_nodes_in_group("patrol_points")
onready var label = $Label

var target := Vector3.ZERO


func _ready():
	randomize()
	timer.connect("timeout", self, "_on_timeout")
	_start_scanning()

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

func _process(delta):
	var debug_text = ""
	match state:
		EnemyState.Attacking:
			debug_text = "Attacking"
		EnemyState.Investigating:
			debug_text = "Investigating"
		EnemyState.Scanning:
			debug_text = "Scanning"
		EnemyState.Wandering:
			debug_text = "Wandering"
	label.text = debug_text

func _physics_process(_delta):
	var bodies = vision_cone.get_overlapping_bodies()
	if bodies.size() > 0:
		# print("Maybe body")
		var possible_body = bodies[0]
		if possible_body is Player:
			# print("Got player")
			# vision_ray.set_cast_to(possible_body.global_transform.origin - vision_ray.global_transform.origin)
			# vision_ray.force_raycast_update()
			var space_state = get_world().direct_space_state
			var from = global_transform.origin
			var to = possible_body.global_transform.origin
			var result = space_state.intersect_ray(from, to, [self])
			if result:
			# var body = vision_ray.get_collider()
				var body = result['collider']
				if body is Player:
					print(body.visibility)
					if body.visibility > total_visibility_cutoff:
						target = body.global_transform.origin
						_set_path()
						state = EnemyState.Attacking
						print("I can see you")
					elif body.visibility > partial_visibility_cutoff:
						target = body.global_transform.origin
						_set_path()
						state = EnemyState.Investigating
						print("Who goes there?")
					else:
						print("Huh, nothing to see")
	match state:
		EnemyState.Scanning:
			global_rotate(Vector3.UP, rad * turn_speed)
		EnemyState.Wandering:
			_navigate_to_point(wander_speed)
		EnemyState.Investigating:
			_navigate_to_point(wander_speed)
		EnemyState.Attacking:
			_navigate_to_point(attack_speed)

func _start_scanning():
	state = EnemyState.Scanning
	timer.wait_time = scan_time
	timer.start()

func _navigate_to_point(speed):
	var next_move = nav_agent.get_next_location()
	var dir = (next_move - get_global_transform().origin).normalized()

	look_at(next_move, Vector3.UP)

	if not nav_agent.is_navigation_finished():
		move_and_slide(dir * speed)
	else:
		_start_scanning()
