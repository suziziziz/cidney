extends KinematicBody

const speed         := 12.5
const acceleration  := 5
const gravity       := 9.8 * 4
const jumpforce     := 12.0

var yvelocity := Vector3()
var velocity  := Vector3()
var direction := Vector3()
var is_crouch := false

onready var nickname = $Nickname
onready var cameraPivot = $CameraPivot
onready var camera = $CameraPivot/Camera
onready var anim = $Model/RootNode/AnimationPlayer
onready var collAnim = $Coll/Anim
onready var ceilDetector = $CeilDetector

enum states {
	IDLE,
	WALK,
	JUMP,
}
var state = states.IDLE


### === FUNCTIONS === ###
func Vector3Int(vector: Vector3) -> Vector3:
	return Vector3(int(vector.x), int(vector.y), int(vector.z))


func toggleFlashlight():
	$CameraPivot/SpotLight.visible = !$CameraPivot/SpotLight.visible


func updateLan():
	if is_network_master():
		rpc_unreliable("_set_position", global_transform.origin)
		rpc_unreliable("_set_state", state)
		rpc_unreliable('_set_rotation', rotation_degrees, $CameraPivot.rotation_degrees)
		rpc_unreliable('_set_flashlight', $CameraPivot/SpotLight.visible)


### === REMOTES === ###
remote func _set_position(pos):
	global_transform.origin = pos

remote func _set_rotation(rot: Vector3, camRot: Vector3):
	rotation_degrees = rot
	cameraPivot.rotation_degrees = camRot

remote func _set_state(currentState):
	state = currentState

remote func _set_flashlight(currentVisible: bool):
	$CameraPivot/SpotLight.visible = currentVisible


### === GAME === ###
func _ready():
	if is_network_master():
		$Model.visible = false
		nickname.queue_free()
	else:
		nickname.get_node("Viewport/Nickname").text = str(Globals.playerInfo[get_tree().get_network_unique_id()].name)
		camera.hide()
		$GUI.hide()


func _input(event):
	if event is InputEventMouseMotion:
		if is_network_master():
			rotate_y(deg2rad(-event.relative.x * Globals.game.sensitivity))
			cameraPivot.rotate_x(deg2rad(-event.relative.y * Globals.game.sensitivity))
			cameraPivot.rotation_degrees.x = clamp(cameraPivot.rotation_degrees.x, -90, 90)


func _physics_process(delta):
	if is_network_master():
		# MOVEMENT
		direction = Vector3()
		if Input.is_action_pressed("move_forward") : direction -= transform.basis.z
		if Input.is_action_pressed("move_backward"): direction += transform.basis.z
		if Input.is_action_pressed("move_left")    : direction -= transform.basis.x
		if Input.is_action_pressed("move_right")   : direction += transform.basis.x
		direction = direction.normalized()
		velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
		velocity = move_and_slide(Vector3(velocity.x, 0, velocity.z), Vector3.UP, true)
		
		# GRAVITY AND JUMP
		yvelocity = move_and_slide(Vector3(0, yvelocity.y, 0), Vector3.UP, true)
		if is_on_floor():
			yvelocity.y = -0.1
			if Input.is_action_just_pressed("jump"): yvelocity.y = jumpforce # JUMP
		else:
			yvelocity.y -= gravity * delta
		
		# CROUCH
		if Input.is_action_pressed("crouch"):
			if collAnim.current_animation != "Crouch":
				collAnim.play("Crouch", .075)
		else:
			if collAnim.current_animation != "Normal":
				if !ceilDetector.is_colliding():
					collAnim.play("Normal", .075)
		
		# ANIMATION STATE
		if is_on_floor():
			if direction != Vector3():
				state = states.WALK
			else:
				state = states.IDLE
		else:
			state = states.JUMP
		
		# TOGGLE FLASHLIGHT
		if Input.is_action_just_pressed("flash"):
			toggleFlashlight()
		
		# TOGGLE MOUSE MODE
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# APPLY ANIMATIONS
	match state:
		states.IDLE: if anim.current_animation != "Idle":     anim.play("Idle", .1)
		states.WALK: if anim.current_animation != "Running":  anim.play("Running", .1)
		states.JUMP: if anim.current_animation != "Falling":  anim.play("Falling", .1)
	
	# UPDATE FOR ALL
	updateLan()






