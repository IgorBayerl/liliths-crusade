extends StateMachine

func _ready() -> void:
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("wall_slide")
	add_state("ledge_grab")
	add_state("climb_up")
	call_deferred("set_state", states.idle)
	
func _input(event):
	parent._update_input_direction()
	if state == states.wall_slide:
		parent._cap_gravity_wall_slide()
	if[states.idle, states.run].has(state):
		#JUMP
		if event.is_action_pressed("jump"):
			#Se tiver pressionando para baixo .. descer da plataforma ao invez de pular
			if event.is_action_pressed("move_DOWN"):
				#Verifica se é uma plataforma ou não para não ficar preso no chão solido
				if parent.is_grounded:
					#Faz com que o player atravesse para baixo da plataforma
					parent.set_collision_mask_bit(parent.DROP_THRU_BIT, false)
			else:
				parent._jump()
	elif state == states.wall_slide && parent.wall_jump_cooldown.is_stopped():
		if event.is_action_pressed("jump"):
#			if parent.have_wall_jump:
			parent._wall_jump()
			set_state(states.jump)
	elif[states.fall, states.jump ].has(state) :
			
		if state == states.jump:
			#Pulo variavel
			if event.is_action_released("jump"):
				if parent.velocity.y < parent.min_jump_velocity:
					parent.velocity.y = parent.min_jump_velocity
		if event.is_action_pressed("jump") and parent.jump_count == 1:
			parent._double_jump()
	elif state == states.ledge_grab:
		if event.is_action_pressed("jump"):
			parent.is_clibing_up = true


func _state_logic(delta):
	parent._check_for_ledge_grab()
	parent._update_wall_direction()
	parent._update_is_grounded()
	if state != states.ledge_grab:
		parent._apply_gravity(delta)
	if state == states.ledge_grab:
		parent._update_ledge_direction()
		parent._cap_gravity_wall_slide()
	if state == states.climb_up:
		parent._climbing_up_action()
	if state != states.wall_slide and state != states.ledge_grab:
		if !parent.is_wall_jumping:
			parent._handle_move_input()
			parent._update_direction()
		parent._update_move_direction()
#		parent._update_structure_direction()
	if state == states.wall_slide:
		parent._cap_gravity_wall_slide()
		parent._handle_wall_slide_sticking()
	parent._apply_movement()


#	if parent.can_change_move_direction:
		
#	if !parent.is_wall_jumping:
#		if !parent.is_crouched and !parent.is_wall_grab:
#			parent._handle_move_input()
#		parent._update_direction()
#	if[states.fall, states.wall_slide ].has(state):
#		parent._update_wall_direction()
#		Process ledge grab
	
	parent.label.text = str(state)
	
func _get_transition(_delta):
	match state:
		states.idle:
			if !parent.is_grounded:
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y > 0:
					return states.fall
			elif parent.velocity.x != 0:
				return states.run
		states.run:
			if !parent.is_grounded:
				if parent.velocity.y < 0:
					return states.jump
				elif parent.velocity.y > 0:
					return states.fall
			elif parent.velocity.x == 0:
				return states.idle
			
		states.jump:
			if parent.is_grounded:
				return states.idle
			elif parent.velocity.y >= 0:
				return states.fall
			elif parent.wall_direction != 0 and parent.input_direction.x == parent.wall_direction and parent.have_wall_jump:
				return states.wall_slide
		states.fall:
			if parent.is_grounded:
				return states.idle
			elif parent.velocity.y < 0 :
				return states.jump
			elif parent.wall_direction != 0 and parent.input_direction.x == parent.wall_direction and parent.have_wall_jump:
				return states.wall_slide
		states.wall_slide:
			if parent.is_grounded:
				return states.idle
			if parent.is_wall_jumping:
				return states.jump
#			if parent.input_direction.x == parent.wall_direction * -1:
#				parent._handle_wall_slide_sticking()
			if parent.wall_direction == 0:
				return states.fall
		states.ledge_grab:
			if parent.is_grounded:
				return states.idle
			if parent.is_clibing_up:
				return states.climb_up
		states.climb_up:
			if !parent.is_clibing_up and parent.is_jumping:
				return states.jump
		
		
				
	return null

func _enter_state(new_state, _old_state):
	
	match new_state:
		states.idle:
			parent.anim_player.play("Idle")
			print('Idle')
		states.run:
			parent.anim_player.play("Run")
			print('Run')
		states.jump:
			parent.anim_player.play("Jump")
			print('Jump')
		states.fall:
			parent.anim_player.play("Fall")
			parent._toggle_ledge_grab_raycasts(true)
			print('Fall')
		states.ledge_grab:
			parent.move_direction = parent.facing
			parent.velocity.x = 0
			parent._invert_direction_ledge_grab()
			parent._update_ledge_direction()
			parent.anim_player.play("LedgeGrab")
			print('LedgeGrab')
		states.wall_slide:
			parent.velocity.x = 0
			parent._invert_direction()
			parent.anim_player.play("WallSlide")
		states.climb_up:
			parent.jump_count = 0
			parent.anim_player.play("ClimbUp")
			parent._climb_up()
			print('to subindoooooooooooooooo')

func _exit_state(old_state, _new_state):
	match old_state:
		states.fall:
			parent._toggle_ledge_grab_raycasts(false)


func _on_WallSlideSticknes_timeout() -> void:
	if state == states.wall_slide:
		set_state(states.fall)
