extends AnimationTree

@onready var Player = owner
@export var RootSpeed=0.0
var SmoothingMode=true
@onready var BlendSpace : AnimationNodeBlendSpace2D = tree_root.get_node("GroundedMovement")
@onready var SmoothingText : Label = get_node("Control/Label")

#func _ready() -> void:
	#print(get_property_list())

func _process(delta: float) -> void:
	var XZSpeed=Vector2(Player.velocity.x,-Player.velocity.z).rotated(-Player.Body.global_rotation.y)
	
	
	var TargetSpeedScale=0.01
	
	if Input.is_action_just_pressed("SWITCHMODE"):
		SmoothingMode=!SmoothingMode
	SmoothingText.text = "BlendPoint Smoothing: "+str(SmoothingMode)
	if SmoothingMode:
		BlendSpace.default_blend_time=0.5
	else:
		BlendSpace.default_blend_time=0.0
	self["parameters/GroundedMovement/blend_position"]=ExpDecay(self["parameters/GroundedMovement/blend_position"],XZSpeed/Player.WALK_SPEED,15,delta)
		
	if RootSpeed>0.0 && self["parameters/SpeedScale/scale"] > 0: # check if really needs to be applied
		TargetSpeedScale = max(XZSpeed.length(),0.01)/max(RootSpeed,0.01)#get the difference
	self["parameters/SpeedScale/scale"] = lerp(self["parameters/SpeedScale/scale"],TargetSpeedScale,Engine.get_physics_interpolation_fraction()) # interpolate to compensate for physics tik rate
	if self["parameters/SpeedScale/scale"]==NAN || self["parameters/SpeedScale/scale"]==INF: # incase it some how devides by zero even if it shouldn't
		self["parameters/SpeedScale/scale"] = 1.0

static func ExpDecay(a,b,decay : float,dt : float):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)
