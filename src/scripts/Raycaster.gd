extends Node2D
class_name RayCaster2D, "res://src/CustomNodes/Raycaster.svg"

const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)
const SKIN_WIDTH = 1

var red_color = Color(1.0, .329, .298)

export (int) var buffer_size = 3 setget _set_buffer_size
export (bool) var raycast_visible = false

var buffer = []

var draw_lines_array = [[Vector2(0, 0), Vector2(0, -2)],[Vector2(1, 0), Vector2(1, -2)]]
var draw_pos1 = Vector2()
var draw_pos2 = Vector2()

func _ready():
	_set_buffer_size(buffer_size)


func raycast(direction:Vector2, rect:Shape2D, mask:int, exceptions := [], ray_length := 16, buffer: Array = self.buffer):
	if raycast_visible: draw_lines_array = []
	if not [UP,DOWN,LEFT,RIGHT].has(direction): return 0;
	
	var space_state = get_world_2d().direct_space_state
	var extents = rect.extents - Vector2( SKIN_WIDTH , SKIN_WIDTH )
	var count = 0
	var ray_count = buffer.size()
	var cast_to = (ray_length + SKIN_WIDTH) * direction
	var origin
	var spacing
	
	if direction == UP || direction == DOWN:
		spacing = extents.x * 2 / (ray_count -1)
	else:
		spacing = extents.y * 2 / (ray_count -1)
	
	for i in range(ray_count):
		if direction == UP || direction == DOWN:
			origin = Vector2(-extents.x + spacing * i, extents.y)
			if direction == UP:
				origin.y = -origin.y
		else:
			origin = Vector2(extents.x , -extents.y + spacing * i)
			if direction == LEFT:
				origin.x = -origin.x
		var result = space_state.intersect_ray(global_position + origin, global_position + origin + cast_to, exceptions, mask)
		if result:
			buffer[count] = result
			count += 1
		
		if raycast_visible: draw_lines_array.append([origin, origin + cast_to])
	if raycast_visible: update()

	return {buffer = buffer, count = count}

func _draw():
	if raycast_visible:
		for i in range (draw_lines_array.size()):
			draw_line(draw_lines_array[i][0],draw_lines_array[i][1],red_color)

func _set_buffer_size(value):
	buffer_size = max(value, 2)
	buffer.resize(buffer_size)


