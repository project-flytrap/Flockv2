extends Node3D

@onready var chunk_inst = preload("res://Scenes/chunk.tscn")
#Number of chunks you can see out in each direction. 
@export var chunk_dist : int = 1
#LOD must be a power of 2
@export var LOD : int = 4
@export var iso_level : float = 2.0
var chunk_scale : float = 100

@export var player : Node3D
var curr_chunk : Vector3i = Vector3i.ZERO
#Stores references to active chunks.
var chunk_dict : Dictionary = {}

#Stores references to pooled chunks. Pooled chunks are disabled.
var chunk_pool : Dictionary = {}
@export var max_pool_size : int = 50
@export var min_pool_size : int = 10

#Used to store a cube starting at 0,0,0 extending out in chunk_dist directions.
var cube : PackedVector3Array = PackedVector3Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	chunk_scale = RenderInfo.chunk_scale
	cube = generate_square_array(Vector3i.ZERO,chunk_dist)
	#update_chunks(Vector3i.ZERO)
	build_initial_chunks()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	calc_current_chunk()
	#print(is_within_cube(Vector3i.ZERO, Vector3i(-1,0,2), 1))
	#print(Engine.get_frames_per_second())
	#print(chunk_pool.size())
#	pass

func update_chunks(center : Vector3i):
	print("update?")
	var rb : Array = calculate_chunks_to_release_and_build(curr_chunk, center)
	for ind in rb[0].size():
		#Destroy
		remove_chunk(rb[0][ind])
		#Create
		var r = rb[1][ind]
		var r_i : Vector3i = Vector3i(r)
		if !chunk_dict.has(r_i):
			create_chunk(r)
		else:
			print("Something went wrong." + str(r_i))


#A bit annoying that PackedVector3iArray doesn't exist. Need to typecast when used.
#Optimize this later! This is a really naive approach. Currently it iterates through both arrays which is really foolish.
func calculate_chunks_to_release_and_build(old_center: Vector3i, new_center: Vector3i) -> Array:
	var release : PackedVector3Array = PackedVector3Array()
	var build : PackedVector3Array = PackedVector3Array()
	for p in cube:
		var p_int = Vector3i(p) #EWWW
		if !is_within_square(p_int + old_center, new_center, chunk_dist):
			release.append(Vector3(p_int + old_center))
		if !is_within_square(p_int + new_center, old_center, chunk_dist):
			build.append(Vector3(p_int + new_center))
	print("release " + str(release))
	print("build " + str(build))
	return [release, build]

#Returns an array containing each of the points in a cube
func generate_cube_array(center : Vector3i , dist : int) -> PackedVector3Array:
	var r : PackedVector3Array = PackedVector3Array()
	for x in range(-dist + center.x, dist + 1 + center.x):
		for y in range(-dist + center.y, dist + 1 + center.y):
			for z in range(-dist + center.z, dist + 1 + center.z):
				#Really stinky typecasting. Not a fan.
				r.append(Vector3(Vector3i(x,y,z)))
	return r

func generate_square_array(center : Vector3i, dist: int) -> PackedVector3Array:
	var r : PackedVector3Array = PackedVector3Array()
	for x in range(-dist + center.x, dist + 1 + center.x):
		for z in range(-dist + center.y, dist + 1 + center.y):
			r.append(Vector3(Vector3i(x,0,z)))
	return r

#Checks if two points are within certain manhattan distance.
func is_within_dist(point1 : Vector3i, point2 : Vector3i, dist : int) -> bool:
	var d : Vector3i = point1 - point2
	d = abs(d)
	return d.x <= dist && d.y <= dist && d.z <= dist

func is_within_dist_xz(point1 : Vector3i, point2 : Vector3i, dist : int) -> bool:
	var d : Vector3i = point1 - point2
	d = abs(d)
	return d.x <= dist && d.z <= dist

#Checks if a point is inside a cube.
func is_within_cube(point: Vector3i, center_cube : Vector3i, dist : int) -> bool:
	#var half_size: int = cube_size >> 1
	return is_within_dist(point, center_cube, dist)

func is_within_square(point : Vector3i, center_cube : Vector3i, dist : int) -> bool:
	return is_within_dist_xz(point, center_cube, dist)

func build_initial_chunks():
	chunk_dict.clear()
	for p in cube:
		create_chunk(p)

func create_chunk(chunk_pos : Vector3):
	var new_chunk
	var v3i : Vector3i = Vector3i(chunk_pos)
	if chunk_pool.has(v3i): #Create chunk from existing chunk.
		new_chunk = chunk_pool[v3i]
		new_chunk.reenable()
		chunk_pool.erase(v3i)
	elif chunk_pool.is_empty() || chunk_pool.size() < min_pool_size:
		new_chunk = chunk_inst.instantiate()
		new_chunk.player = player
		add_child(new_chunk)
		new_chunk.chunk_pos = v3i
		new_chunk.position = chunk_pos * RenderInfo.chunk_size 
	else:
		#Recycle chunk from chunk cache.
		var key = chunk_pool.keys()[0] #Create chunk from oldest chunk in chunk pool
		new_chunk = chunk_pool[key]
		new_chunk.reenable()
		new_chunk.chunk_pos = v3i
		new_chunk.position = chunk_pos * RenderInfo.chunk_size
		chunk_pool.erase(key)
	chunk_dict[v3i] = new_chunk
	return new_chunk

func remove_chunk(chunk_pos : Vector3):
	var r_i : Vector3i = Vector3i(chunk_pos)
	if !chunk_dict.has(r_i):
		print("Error: Chunk " + str(r_i) + " missing")
		return
	if chunk_pool.size() < min_pool_size: #Add to pool.
		chunk_dict[r_i].disable()
		chunk_pool[r_i] = chunk_dict[r_i]
	elif chunk_pool.size() < max_pool_size:
		chunk_dict[r_i].queue_free() #Between min and max.
	else:
		chunk_dict[r_i].queue_free() #This is correct
	#print(chunk_pool.size())
	#print(chunk_dict.size())
	chunk_dict.erase(r_i)

func calc_current_chunk() -> Vector3i:
	#print("Current Position: " + str(position))
	#print("Chunk: " + str(round(position/chunk_size)))
	var chunk : Vector3i = round(player.position/RenderInfo.chunk_size)
	chunk.y = 0
	if chunk != curr_chunk:
		#Update chunk.
		curr_chunk = chunk
		print("Current Chunk Coord updated to " + str(curr_chunk))
		update_chunks(curr_chunk)
		#print(chunk_dict)
	return curr_chunk
