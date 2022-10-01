extends Area

enum TriggerType {
	PausedText,
	OverlayText
}

export (String, MULTILINE) var message = "TEST MESSAGE"
export (TriggerType) var type = TriggerType.PausedText

var _triggered = false

func _ready():
	connect("body_entered", self, "_trigger_text")

func _trigger_text(body):
	if not _triggered:
		_triggered = true
		if body is Player:
			if type == TriggerType.PausedText:
				body.trigger_paused_text(message)
			elif type == TriggerType.OverlayText:
				body.trigger_overlay_text(message)
