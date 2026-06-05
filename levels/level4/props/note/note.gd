extends DraggableArea2D

enum Phase { HIDDEN, STUCK, DRAGGABLE, AT_END }

signal tug_requested()
signal reached_end()

@export var start_pos: Vector2 = Vector2(1239.0, 1016.0)
@export var end_pos: Vector2 = Vector2(1439.0, 1016.0)

var phase: Phase = Phase.HIDDEN


func _ready() -> void:
	can_drag = true
	drag_started.connect(_on_drag_started)
	set_phase(Phase.HIDDEN)


func _on_drag_started(_item: DraggableArea2D, _pos: Vector2) -> void:
	if phase == Phase.STUCK:
		tug_requested.emit()


func set_phase(new_phase: Phase) -> void:
	phase = new_phase
	visible = phase != Phase.HIDDEN
	input_pickable = visible
	monitorable = visible
	if phase == Phase.STUCK or phase == Phase.DRAGGABLE:
		position = start_pos


func reset_to_start() -> void:
	position = start_pos
	if visible:
		phase = Phase.STUCK


func update_drag_position(new_world_pos: Vector2) -> void:
	if phase != Phase.DRAGGABLE:
		return

	var old_pos := position
	var local_pos := new_world_pos
	var parent_2d := get_parent() as Node2D
	if parent_2d:
		local_pos = parent_2d.to_local(new_world_pos)

	var axis := end_pos - start_pos
	if axis.length_squared() < 0.01:
		return

	var t := (local_pos - start_pos).dot(axis) / axis.length_squared()
	t = clampf(t, 0.0, 1.0)
	var new_local := start_pos + axis * t
	dragged.emit(self, old_pos, new_local)
	position = new_local

	if position.distance_to(end_pos) < 2.0:
		phase = Phase.AT_END
		reached_end.emit()
