extends AnimationTree

@onready var Player = owner
@export var RootSpeed=0.0
var SmoothingMode=true
@onready var BlendSpace : AnimationNodeBlendSpace2D = tree_root.get_node("GroundedMovement")
@onready var SmoothingText : Label = get_node("Control/Label")

var AnimFPS=25.0
var IntCounter=0.0
var speed_scale = 1.0


func _process(delta: float) -> void:
	var XZSpeed=Vector2(Player.velocity.x,-Player.velocity.z).rotated(-Player.Body.global_rotation.y)
	
	if callback_mode_process==ANIMATION_CALLBACK_MODE_PROCESS_MANUAL:
		IntCounter+=delta
		if IntCounter>1.0/AnimFPS:
			call_deferred("advance",IntCounter)
			IntCounter=0.0
	
	
	if Input.is_action_just_pressed("SWITCHMODE"):
		SmoothingMode=!SmoothingMode
	SmoothingText.text = "BlendPoint Smoothing: "+str(SmoothingMode)
	if SmoothingMode:
		BlendSpace.use_velocity_limit=true
	else:
		BlendSpace.use_velocity_limit=false
	self["parameters/GroundedMovement/blend_position"]=ExpDecay(self["parameters/GroundedMovement/blend_position"],XZSpeed/Player.WALK_SPEED,20,delta)
		
		
	var TargetSpeedScale=0.01
	TargetSpeedScale = max(XZSpeed.length(),0.01)/max(RootSpeed,0.01)#get the difference
	speed_scale = lerp(speed_scale,TargetSpeedScale,Engine.get_physics_interpolation_fraction()) # interpolate to compensate for physics tik rate
	if speed_scale==NAN || speed_scale==INF: # incase it some how devides by zero even if it shouldn't
		speed_scale = 1.0
	for i in 11:
		self["parameters/GroundedMovement/"+str(i+1)+"/TimeScale/scale"]=speed_scale

static func ExpDecay(a,b,decay : float,dt : float):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)
