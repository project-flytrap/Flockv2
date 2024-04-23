extends Node

var chunk_scale : float = 100
var chunk_size : float = 100.0
var iso_level : float = 2.0

var noise_scale : float = 2.0
var noise_offset : Vector3 = Vector3.ZERO

var time : float = 0.0
#Stores number of voxels in width
var voxel_width : int = 4 : 
	set(value):
		num_voxels_per_axis = pow(2, value)
		#2^4 = 16
var num_voxels_per_axis : int = 16
