extends Node

signal message_shown(message: String)

var message_data: Dictionary[String, String] = {
    "1": "test test test"
}

func emit_message_by_id(text_id: String) -> void:
    if not message_data.has(text_id):
        return
    var message = message_data[text_id]
    message_shown.emit(message)
