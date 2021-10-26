extends KinematicBody2D

export var GRAVITY = 1200
export var snap_player_on_the_ground_apply_movement: bool = true
export var verticalDistanceFromLedge: int = -60
export var horizontalDistanceFromLedge: int = 16

signal OnDeath(WhoDied)
signal OnRespawn(WhoDied)
signal GroundedUpdated(is_grounded)

const UP = Vector2(0, -1)
const SLOPE_STOP = true # Era 60 nao sei pq
const WALL_JUMP_VELOCITY = Vector2(300 , -400)
const SNAP_DIRECTION = Vector2.DOWN
const SNAP_LENGTH = 32.0
const FLOOR_MAX_ANGLE = deg2rad(46)

####################

var checkpoint_position: Vector2

export var move_speed = 210
var velocity = Vector2()
var move_direction = 0
var move_input_speed = 0
var facing = 1
var wall_direction = 1
var ledge_direction = 1
var max_health = 100
var health = 100
var wal_jumping: bool  = false
var head_direction = Vector2()
var rolling_speed = 500
var jump_count = 0
var input_direction = Vector2()

var can_stand_up : bool = true
var atack_combo = 0
var can_atack: bool  = true
var can_access_inventory_var: bool  = false
var can_climb_up: bool  = false
var can_change_move_direction: bool = true
var can_ledge_grab: bool = false

var max_jump_velocity = -550
var min_jump_velocity = -400
var double_jump_velocity = -400
var climb_jump_velocity = -550

var was_on_floor: bool  = false

# Skills control #
export var have_double_jump: bool = true
export var have_wall_jump: bool  = false
export var have_rolling: bool  = false
export var have_heavy_gun: bool  = false

# STATES #
var is_jumping: bool = false
var is_grounded: bool = false
var is_wall_sliding: bool = false
var is_wall_jumping: bool = false
var is_dead: bool = false
var is_atacking: bool = false
var is_rolling: bool = false
var is_crouched: bool = false
var is_stuned: bool = false
var is_clibing_up: bool = false
var is_wall_grab: bool = false
var is_wall_grab_jumping: bool = false

var in_menu: bool = false

############

onready var anim_player = $AnimationPlayer
onready var ground_raycaster = $Sensors/GroundRaycaster
onready var left_wall_raycaster = $Sensors/WallDetection/LeftRaycaster
onready var right_wall_raycaster = $Sensors/WallDetection/RightRaycaster
onready var fullCollider = $FullColision
onready var collider = $RaycastersSizeGuide
onready var label = $Label
#onready var player_head = $PlayerStructure/Sprites/head
onready var player_structure = $PlayerStructure
onready var ledge_grab_raycast_vertical = $PlayerStructure/LedgeGrabRaycasts/LedgeRay_Vertical
onready var ledge_grab_raycast_horisontal = $PlayerStructure/LedgeGrabRaycasts/LedgeRay_Down_Horizontal
onready var ledge_grab_raycast_horisontal_up = $PlayerStructure/LedgeGrabRaycasts/LedgeRay_Up_Horizontal
#onready var ledge_grab_raycasts = $Sensors/LedgeGrabRaycasts
#onready var ledge_grab_raycast_vertical = $PlayerStructure/ledgeGrabRaycasts/LedgeRay_Vertical
#onready var ledgeRay_Up_Horizontal = $PlayerStructure/ledgeGrabRaycasts/LedgeRay_Up_Horizontal
#onready var ledge_grab_raycast_horizontal = $PlayerStructure/ledgeGrabRaycasts/LedgeRay_Horizontal
#onready var left_wall_raycasts = $WallDetectionRaycasts/Left
#onready var right_wall_raycasts = $WallDetectionRaycasts/Right
onready var wall_slide_sticky_timer = $Timers/WallSlideSticknes
#onready var ivunerability = $PlayerStructure/Timers/Ivunerability
#onready var state_label = $state_label
#onready var playerColisionBox = $PlayerStructure/Colision
#onready var teto_detection = $PlayerStructure/Colision/DetectorDeTeto
#onready var roll_timer = $PlayerStructure/Timers/RollTimer
onready var wall_movement_blocker = $Timers/WallJumpBackMoveBlocker
onready var wall_jump_cooldown = $Timers/WallJumpCooldown
#onready var gunsSprite = $PlayerStructure/Mira/Eixo/Guns/GunsSprites
#onready var gunsProps = $PlayerStructure/Mira/Eixo.gunsProps
#onready var gun_mira = $PlayerStructure/Mira/Eixo
#onready var WallJumpToDoubleJumpDelay = $PlayerStructure/Timers/WallJumpToDoubleJumpDelay
#onready var CoyoteTime = $PlayerStructure/Timers/CoyoteTime
##Pariticles
#onready var DoubleJumpParticlesEmissor = $PlayerStructure/particles/DoubleJumpParticleEmissor
#onready var walkingParticles = $PlayerStructure/particles/WalkingParticles

#################
onready var state_machine = $StateMachine
#################
func _update_input_direction():
	input_direction.x = -int(Input.is_action_pressed("move_LEFT")) + int(Input.is_action_pressed("move_RIGHT"))
	input_direction.y = -int(Input.is_action_pressed("move_UP")) + int(Input.is_action_pressed("move_DOWN"))

func _update_move_direction():
	if velocity.x != 0:
		if velocity.x > 0:
			move_direction = 1
		else:
			move_direction = -1

func _invert_direction():
	player_structure.scale.x = -wall_direction
	facing = -wall_direction
	
func _invert_direction_ledge_grab():
	player_structure.scale.x = -player_structure.scale.x
	facing = -facing

func _update_structure_direction():
	if move_direction != 0:
		player_structure.scale.x = move_direction
		facing = move_direction


func _update_is_grounded():
	var was_grounded = is_grounded
	var count = ground_raycaster.raycast(ground_raycaster.DOWN, collider.shape, collision_mask, [], 3).count
	is_grounded = true if count > 0 else false
	if was_grounded == null || is_grounded != was_grounded:
		emit_signal("GroundedUpdated", is_grounded)

func _check_is_valid_wall(wall_raycaster):
	var count_right = wall_raycaster.raycast(wall_raycaster.LEFT, collider.shape, collision_mask).count
	var is_valid_wall = true if count_right > wall_raycaster.buffer_size-1 else false
	return is_valid_wall

func _update_ledge_direction():
	ledge_direction = -facing

func _update_wall_direction():
	var count_left = left_wall_raycaster.raycast(left_wall_raycaster.LEFT, collider.shape, collision_mask, [], 3).count
	var is_near_wall_left = true if count_left > left_wall_raycaster.buffer_size-1 else false
	
	var count_right = right_wall_raycaster.raycast(right_wall_raycaster.RIGHT, collider.shape, collision_mask, [], 3).count
	var is_near_wall_right = true if count_right > right_wall_raycaster.buffer_size-1 else false
	if is_near_wall_left == true and is_near_wall_right == true:
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int(is_near_wall_right)


func _handle_wall_slide_sticking():
	jump_count = 0
	if input_direction.x != 0 and input_direction.x != wall_direction:
		if wall_slide_sticky_timer.is_stopped():
			wall_slide_sticky_timer.start()
	else:
		wall_slide_sticky_timer.stop()

#func _invert_direction():
#	player_structure.scale.x = -wall_direction
#	facing = -wall_direction

#func _ledge_grab_direction():
#	player_structure.scale.x = -player_structure.scale.x


#func _dead():
#	take_damage(100)
#	is_dead = !is_dead

#func _can_ledge_grab():
#	if !ledgeRay_Up_Horizontal.is_colliding():
#		if ledge_grab_raycast_vertical.is_colliding():
#			if ledge_grab_raycast_horizontal.is_colliding() and input_direction.y != 1:
##				print('can climb up == true')
#				return true
#	else: return false

func _climb_up():
	yield(get_tree().create_timer(0.8), "timeout")
#	velocity.y = climb_jump_velocity #lerp(velocity.x, climb_jump_velocity, 0.2)
	facing = ledge_direction
	is_jumping = true
	is_clibing_up = false

func _climbing_up_action():
	velocity.y = lerp(velocity.x, climb_jump_velocity, 0.2)


#func _set_head_direction():
#	head_direction.x = 1.5
#	head_direction.y = -int(Input.is_action_pressed("move_DOWN")) + int(Input.is_action_pressed("move_UP"))
#	player_head.rotation = -head_direction.angle()


func _apply_gravity(delta):
	if !is_wall_grab and !is_clibing_up:
		velocity.y += GRAVITY * delta

	if is_jumping and velocity.y >=0:
		is_jumping = false

func _cap_gravity_wall_slide():
#	if !Input.is_action_pressed("move_DOWN"):
	var max_velocity = 0 #8
	velocity.y = min(velocity.y, max_velocity)


#func _handle_wall_slide_sticking():
#	jump_count = 0
#	if move_direction !=0 and move_direction != wall_direction:
#		if wall_slide_sticky_timer.is_stopped():
#			wall_slide_sticky_timer.start()
#	else:
#		wall_slide_sticky_timer.stop()
		


func _jump():
	velocity.y = max_jump_velocity
	is_jumping = true
	jump_count = 1

func _double_jump():
	velocity.y = double_jump_velocity
	jump_count = 2
	is_jumping = true
#	_nstanciate_Jump_Particle()

func _toggle_ledge_grab_raycasts(enabled: bool) -> void:
	ledge_grab_raycast_horisontal_up.enabled = enabled
	ledge_grab_raycast_horisontal.enabled = enabled
	ledge_grab_raycast_vertical.enabled = enabled

func _check_for_ledge_grab():

	if !is_grounded and velocity.y > 0:
		ledge_grab_raycast_horisontal_up.force_raycast_update()
		if !ledge_grab_raycast_horisontal_up.is_colliding():
			ledge_grab_raycast_vertical.force_raycast_update()
			if ledge_grab_raycast_vertical.is_colliding(): #"can transition to state ledge_grab"
				ledge_grab_raycast_horisontal.global_position.y = ledge_grab_raycast_vertical.get_collision_point().y
				ledge_grab_raycast_horisontal.force_raycast_update()
				if ledge_grab_raycast_horisontal.is_colliding():
					self.global_position.x = ledge_grab_raycast_horisontal.get_collision_point().x - horizontalDistanceFromLedge * facing
					self.global_position.y = ledge_grab_raycast_vertical.get_collision_point().y - verticalDistanceFromLedge
					state_machine.set_state(state_machine.states.ledge_grab)
					jump_count = 0


func _wall_jump():
	
	is_wall_jumping = true
	var wall_jump_velocity = WALL_JUMP_VELOCITY
	wall_jump_velocity.x *= -wall_direction
	velocity = wall_jump_velocity
	print("wall jumping: ",wall_jump_velocity)
	wall_movement_blocker.start()
	wall_jump_cooldown.start()
	jump_count = 1
	
func _apply_movement():
	var stop_on_slope = false if get_floor_velocity().x != 0 else true
	
	var snap_vector = SNAP_DIRECTION * SNAP_LENGTH if !is_jumping else Vector2.ZERO
	if snap_player_on_the_ground_apply_movement == true:
		velocity.y = move_and_slide_with_snap(velocity, snap_vector, UP, stop_on_slope, 4, FLOOR_MAX_ANGLE ).y
	else:
		velocity = move_and_slide(velocity, UP,SLOPE_STOP, 4 , deg2rad(45))


		
func _handle_move_input():
	if !is_wall_grab and !is_clibing_up:
		move_direction = -int(Input.is_action_pressed("move_LEFT")) + int(Input.is_action_pressed("move_RIGHT"))
#	if is_wall_grab or is_clibing_up :
#		move_direction = -wall_direction
	velocity.x = lerp(velocity.x, move_speed * move_direction, _get_h_weight())
#	_stop_player_slide_on_a_ramp()
	
func _update_direction():
	if move_direction != 0:
		player_structure.scale.x = move_direction
		facing = move_direction
		
#func _stop_player_slide_on_a_ramp():
#	if velocity.x < 0.1 * move_direction:
#		velocity.x = 0
#	pass

func _get_h_weight():
	if is_grounded:
		return 1
#		return 0.6
	else:
		if move_direction == 0:
			return 0.02
		elif move_direction == sign(velocity.x) and abs(velocity.x) > move_speed:
			return 0.0
		else:
			return 0.1

func _roll():
	velocity.x = facing * rolling_speed

#func _rolling_direction():
#	if roll_timer.is_stopped():
#		roll_timer.start()
#		is_rolling = true

func _atack():
	if can_atack:
		if atack_combo == 0 and can_atack and not is_atacking:
			print("atack 0 --> 1")
			atack_combo = 1
			is_atacking = true
			can_atack = false
			$MiliAtack_Timer.start()
		if atack_combo == 1 and can_atack and is_atacking:
			print("atack 1 --> 2")
			atack_combo = 2
			is_atacking = true
			can_atack = false
			$MiliAtack_Timer.start()
	print("atack_combo = ", atack_combo)

#func _update_lebel_state(state, _previous_state):
#	state_label.text = str(state)

func _atack_combo():
	$MiliAtack_Timer.start()
	if is_atacking == true:
		if atack_combo == 1:
			anim_player.play("Atack1")
		elif atack_combo == 2:
			anim_player.play("Atack2")



#func take_damage(damage):
#	if ivunerability.is_stopped() and not is_dead:
#		if !is_rolling:
#			is_stuned = true
#			ivunerability.start()
#			get_parent().get_node("CanvasLayer/Control/Health Bar").take_damage(damage)
#			health -= damage
#			death_detection()

func death_detection():
	if health <= 0 and not is_dead:
		is_dead = true
		emit_signal("OnDeath",self)
		yield(get_tree().create_timer(2.5), "timeout")
		_respawn()

func _respawn():
	yield(get_tree().create_timer(1), "timeout")
	position = checkpoint_position
	health = max_health
	is_dead = false
	emit_signal("OnRespawn",self)
	get_parent().get_node("CanvasLayer/Control/Health Bar").restore_health()

func _atack_finish():
	is_atacking = false




func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "Atack1":
		is_atacking = false


func _on_Ivunerability_timeout() -> void:
	is_stuned = false

func _on_Area2D_body_entered(_body: Node) -> void:
	have_double_jump = true

func _on_tetoDetection_1_body_entered(_body):
	can_stand_up = false
#	print('tem teto aqui caraio')
func _on_tetoDetection_1_body_exited(_body):
	can_stand_up = true
#	print('não tem teto não')
	_verify_if_can_standup()


func _verify_if_can_standup():
	if can_stand_up and !Input.is_action_pressed("ctrl"):
		is_crouched = false
	elif !can_stand_up:
		is_crouched = true
		

func _knockback(directionVector2: Vector2 , Force:int ):
	var knockback: Vector2 = Vector2(0,0)
	knockback.x = directionVector2.x * Force * facing
	knockback.y = directionVector2.y * Force
	
#	print('directionX = ', directionVector2.x , ', DirectionY = ', directionVector2.y, ' -- Value = ',Force,' --')
	velocity = knockback
	
func can_access_inventory(can_access):
#	return true
	if can_access != null :
		can_access_inventory_var = can_access
	else:
		can_access_inventory_var = false
	print("[ _can_access_inventory ] : ", can_access)

func _on_RollTimer_timeout():
	is_rolling = false
	_verify_if_can_standup()

func _on_MiliAtack_timeout():
	can_atack = true

func _on_WallJumpBackMoveBlocker_timeout() -> void:
	is_wall_jumping = false
	
	print("timer end")
