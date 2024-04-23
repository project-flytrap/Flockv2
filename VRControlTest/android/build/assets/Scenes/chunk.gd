extends StaticBody3D

var player : Node3D
var chunk_pos : Vector3i
#How far from player to guarantee rendering.
@export var min_render_dist : int = 1
#Amount of time between visibility update checks.
@export var visibility_update_rate : float = 0.1



var visibility_update_time : float = 0.0
var pooled : bool = false




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	return
	#This may be inefficient to run every frame. Perhaps check every set number of seconds.
	visibility_update_time += delta
	if visibility_update_time > visibility_update_rate:
		visibility_update_time = 0.0
		#call_deferred("set_visible",  dot_product_to_player() > -0.5 || is_within_cube(chunk_pos, player.curr_chunk, min_render_dist))
		visible = dot_product_to_player() > -0.5 || is_within_cube(chunk_pos, player.curr_chunk, min_render_dist)

func dot_product_to_player() -> float:
	var pos_to_player : = position - player.position
	var player_dir = player.transform.basis.z
	return normalized_dot_prod(pos_to_player, player_dir)

func normalized_dot_prod(vec1 : Vector3, vec2 : Vector3) -> float:
	return vec1.dot(vec2)/sqrt(vec1.length_squared()*vec2.length_squared())

#Checks if two points are within certain manhattan distance.
func is_within_dist(point1 : Vector3i, point2 : Vector3i, dist : int) -> bool:
	var d : Vector3i = point1 - point2
	d = abs(d)
	return d.x <= dist && d.y <= dist && d.z <= dist

#Checks if a point is inside a cube.
func is_within_cube(point: Vector3i, center_cube : Vector3i, dist : int) -> bool:
	return is_within_dist(point, center_cube, dist)

func reenable():
	pooled = false
	show()
	set_process_mode(PROCESS_MODE_INHERIT)

func disable():
	pooled = true
	hide()
	set_process_mode(PROCESS_MODE_DISABLED)
