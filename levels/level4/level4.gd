extends Node2D

@export var prev_level_location: Vector2 = Vector2(1500.0, 130.0)

func _ready() -> void:
    # CursorManager.invert_x = true
    $NoteArea2D.dragged_to_the_end.connect(_on_note_dragged_to_the_end)
    $CarpetArea2D.item_clicked.connect(_on_carpet_clicked)
    
func _exit_tree() -> void:
    CursorManager.invert_x = false

func _on_note_dragged_to_the_end() -> void:
    print("Note dragged to the end, some logic happens, good!")

func _on_carpet_clicked() -> void:
    print("Carpet clicked, good!")
