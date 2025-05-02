@tool
extends SkeletonModifier3D
class_name HeadRotater

var HeadBone : int
var NeckBone : int
@export var Head : Vector3 = Vector3(PI * 0.5, 0.1, 0)
@onready var LookPoint : Node3D = get_node("LookPoint")
@onready var CameraDefault : Camera3D = get_node("CameraDefault")
@onready var CameraCurrent : Camera3D = get_node("CameraCurrent")

var HeadMaxxed = Vector3()
@export var CameraStabilizationToggle = true

@export_range(0.0,1.0,0.1) var GlobalLocal=0.0
@export_range(0.0,1.0,0.1) var CStabilize=1.0
@export_range(0.0,1.0,0.1) var NeckWeight=1.0
@export var HeadXRangeM=0.001
@export var HeadXRangeP=PI*0.999


#func _validate_property(property: Dictionary) -> void:
	#if property.name == "DesiredBone":
		#var skeleton: Skeleton3D = get_skeleton()
		#if skeleton:
			#property.hint = PROPERTY_HINT_ENUM
			#property.hint_string = skeleton.get_concatenated_bone_names()

func _ready() -> void:
	var skeleton = get_skeleton()
	HeadBone = skeleton.find_bone("Head")
	NeckBone = skeleton.find_bone("Neck")

func _process_modification() -> void:
	var skeleton = get_skeleton()
	if !skeleton:
		return
	
	
	
	var NeckTransform=skeleton.get_bone_pose(NeckBone)
	HeadMaxxed=Vector3(clamp(Head.x,HeadXRangeM,HeadXRangeP),Head.y,Head.z)
	var NeckRotBasis = Basis().from_euler(Vector3(
		-(HeadMaxxed.x*0.5)+PI*0.25,
		-angle_difference(HeadMaxxed.y,skeleton.global_rotation.y) * 0.5,
		0.0))
	
	var OldNeckTransform = NeckTransform
	NeckTransform.basis*=NeckRotBasis
	skeleton.set_bone_pose(NeckBone,OldNeckTransform.interpolate_with(NeckTransform,NeckWeight))
	
	
	var HeadTransformLOCAL=skeleton.get_bone_pose(HeadBone)
	var HeadTransformGLOBAL=HeadTransformLOCAL
	var HeadRotBasis = Basis().from_euler(Vector3(-HeadMaxxed.x+PI*0.5,-angle_difference(HeadMaxxed.y,skeleton.global_rotation.y),0.0))
	#LOCAL CALC
	HeadTransformLOCAL.basis*=HeadRotBasis
	
	HeadTransformLOCAL.orthonormalized()
	#GLOBAL CALC
	HeadTransformGLOBAL.basis*=skeleton.get_bone_global_pose(HeadBone).basis.inverse()*HeadRotBasis
	#SwapBetween the 2
	skeleton.set_bone_pose(HeadBone,HeadTransformGLOBAL.interpolate_with(HeadTransformLOCAL,0.1+GlobalLocal*0.9))
	
	transform=skeleton.get_bone_global_pose(HeadBone)
	CameraStabilize(skeleton)

func CameraStabilize(skeleton : Skeleton3D):
	if (CameraStabilizationToggle == true):
		var HeadPos = global_position
		LookPoint.global_position = HeadPos + Vector3(0, 0, 12).rotated(Vector3(1, 0, 0), HeadMaxxed.x - PI * 0.5).rotated(Vector3(0, 1, 0), HeadMaxxed.y - PI)
		var DirToPoint = HeadPos.direction_to(LookPoint.global_position)
		var NewRot = Vector3(asin(DirToPoint.y) - skeleton.global_rotation.x, atan2(-DirToPoint.z, DirToPoint.x) - PI * 0.5, skeleton.global_rotation.z)
		#print(NewRot.z)
		CameraCurrent.position=(Vector3(0.013, 0.152, -0.119));
		var CameDefaultRot = CameraDefault.global_rotation
		var X_rot = lerp_angle(CameDefaultRot.x, NewRot.x, CStabilize)
		var Y_rot = lerp_angle(CameDefaultRot.y, NewRot.y, CStabilize)
		var Z_rot = lerp_angle(CameDefaultRot.z, NewRot.z, CStabilize)
		CameraCurrent.global_rotation=Vector3(X_rot, Y_rot, Z_rot)
