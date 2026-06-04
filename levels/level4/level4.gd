extends Node2D

func _ready() -> void:
    CursorManager.invert_x = true
    $NoteArea2D.dragged_to_the_end.connect(_on_note_dragged_to_the_end)
    $CarpetArea2D.item_clicked.connect(_on_carpet_clicked)

    $CarpetArea2D/CarpetOpenedSprite.visible = false
    $CarpetArea2D/CarpetOpenedCollision.disabled = true

func _exit_tree() -> void:
    CursorManager.invert_x = false

func _on_note_dragged_to_the_end() -> void:
    print("Note dragged to the end, some logic happens, good!")

func _on_carpet_clicked(_item: ClickableArea2D, _pos: Vector2) -> void:
    $CarpetArea2D/CarpetOpenedSprite.visible = !$CarpetArea2D/CarpetOpenedSprite.visible
    $CarpetArea2D/CarpetClosedSprite.visible = !$CarpetArea2D/CarpetClosedSprite.visible
    $CarpetArea2D/CarpetOpenedCollision.disabled = !$CarpetArea2D/CarpetOpenedCollision.disabled
    $CarpetArea2D/CarpetClosedCollision.disabled = !$CarpetArea2D/CarpetClosedCollision.disabled
