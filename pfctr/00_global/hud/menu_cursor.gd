extends Sprite2D

@export var menu_parent_path : NodePath
@export var cursor_offset : Vector2

@onready var menu_parent := get_node(menu_parent_path)

var cursor_index : int = 0

func _ready() -> void:
	# Place the cursor on the first item at start
	set_cursor_from_index(cursor_index)

func _process(_delta: float) -> void:
	var input := Vector2i.ZERO
	
	if Input.is_action_just_pressed("ui_up"):
		input.y -= 1
	if Input.is_action_just_pressed("ui_down"):
		input.y += 1
	if Input.is_action_just_pressed("ui_left"):
		input.x -= 1
	if Input.is_action_just_pressed("ui_right"):
		input.x += 1
	
	if menu_parent is VBoxContainer:
		set_cursor_from_index(cursor_index + input.y)
	elif menu_parent is HBoxContainer:
		set_cursor_from_index(cursor_index + input.x)
	elif menu_parent is GridContainer:
		set_cursor_from_index(cursor_index + input.x + input.y * menu_parent.columns)
	
	if Input.is_action_just_pressed("ui_accept"):
		var current_menu_item := get_menu_item_at_index(cursor_index)
		
		if current_menu_item != null:
			if current_menu_item.has_method("cursor_select"):
				current_menu_item.cursor_select()

func get_menu_item_at_index(index: int) -> Control:
	if menu_parent == null:
		return null
	
	if index >= menu_parent.get_child_count() or index < 0:
		return null
	
	return menu_parent.get_child(index) as Control

func set_cursor_from_index(index: int) -> void:
	var menu_item := get_menu_item_at_index(index)
	
	if menu_item == null:
		return
	
	var item_position := menu_item.global_position
	var item_size := menu_item.size
	
	# Sprite2D is centered by default, so its position is already its center.
	# If you turn off "Centered" in the inspector, add texture.get_size() / 2.0 offset.
	global_position = Vector2(item_position.x, item_position.y + item_size.y / 2.0) - cursor_offset
	
	cursor_index = index
