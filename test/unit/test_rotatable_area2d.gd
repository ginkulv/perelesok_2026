extends GutTest

## Documents expected knob behaviour: rotation_ended must fire when the player releases.


func test_end_rotation_emits_rotation_ended() -> void:
	var knob := RotatableArea2D.new()
	add_child_autofree(knob)
	watch_signals(knob)

	knob.update_rotation(Vector2(0, -5))
	knob.end_rotation()

	assert_signal_emitted(knob, "rotation_ended")
	assert_false(knob._is_being_rotated)
