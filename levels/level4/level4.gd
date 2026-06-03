extends Node2D

func _ready() -> void:
    LevelManager.level_changed.connect(_on_level_changed)

func _on_level_changed(level_from: String, level_to: String) -> void:
    if level_to == self.name:
        CursorManager.invert_x = true
        $NoteArea2D.dragged_to_the_end.connect(_on_note_dragged_to_the_end)
        $CarpetArea2D.item_clicked.connect(_on_carpet_clicked)
        print(level_from)
    elif level_from == self.name:
        CursorManager.invert_x = false

func _on_note_dragged_to_the_end() -> void:
    print("Note dragged to the end, some logic happens, good!")

func _on_carpet_clicked() -> void:
    print("Carpet clicked, good!")
