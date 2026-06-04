extends CanvasLayer

signal info_closed()

func _on_button_button_up() -> void:
    info_closed.emit()
    queue_free()
