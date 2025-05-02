extends CharacterBody3D


const JOG_SPEED = 2.68224
const WALK_SPEED = 1.38888889
const JUMP_VELOCITY = 4.5
var HeadRot = Vector3(PI*0.5,0.0,0.0)
@onready var Body : Node3D = get_node("test mixamo anims")
@onready var HeadMod : HeadRotater = get_node("test mixamo anims/Armature/GeneralSkeleton/HeadRotater")

func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	Engine.time_scale=1.0-0.9*Input.get_action_strength("SLOWMO")
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("LEFT", "RIGHT", "UP", "DOWN")
	var direction := (Basis().from_euler(Vector3(0.0,Body.global_rotation.y,0.0)) * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var DesSpeed = lerp(JOG_SPEED,WALK_SPEED,Input.get_action_strength("WALK"))
	if direction:
		velocity.x = ExpDecay(velocity.x,direction.x * DesSpeed,20,delta)
		velocity.z = ExpDecay(velocity.z,direction.z * DesSpeed,20,delta)
	else:
		velocity.x = ExpDecay(velocity.x,0.0,20,delta)
		velocity.z = ExpDecay(velocity.z,0.0,20,delta)
	move_and_slide()

func _process(delta: float) -> void:
	Body.global_rotation.y=ExpDecayAngle(Body.global_rotation.y,HeadRot.y,20,delta)
	HeadMod.Head=HeadRot

static func ExpDecayAngle(a, b, decay:float, dt:float):
	var result
	if typeof(a)==TYPE_VECTOR3:
		a.x=ExpDecayAngle(a.x,b.x,decay,dt)
		a.y=ExpDecayAngle(a.y,b.y,decay,dt)
		a.z=ExpDecayAngle(a.z,b.z,decay,dt)
		result = a
	else:
		result = b + (fmod(2.0 * fmod(a - b, TAU),TAU) - fmod(a - b, TAU)) * exp(-decay *dt)
	return result

func _unhandled_input(event) -> void:
	if (event is InputEventMouseMotion):
		HeadRot.y=HeadRot.y-event.relative.x*0.001
		HeadRot.x=clamp(HeadRot.x+event.relative.y*(0.001),0.0,PI)

static func ExpDecay(a,b,decay : float,dt : float):
	if typeof(a)==TYPE_BASIS:
		var result = Basis.IDENTITY
		result.x = ExpDecay(a.x,b.x,decay,dt)
		result.y = ExpDecay(a.y,b.y,decay,dt)
		result.z = ExpDecay(a.z,b.z,decay,dt)
		return result.orthonormalized()
	return b+(a-b)*exp(-decay*dt)
