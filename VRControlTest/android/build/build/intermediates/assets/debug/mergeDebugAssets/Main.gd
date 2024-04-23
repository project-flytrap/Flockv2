extends Node3D

var xr_interface : XRInterface

# Called when the node enters the scene tree for the first time.
func _ready():
	init_xr_interface()



func init_xr_interface():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
