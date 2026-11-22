class_name SonSave
extends RefCounted

const SAVE_PATH := "user://son_yolcu_progress.json"
var data: Dictionary = {}

func _init() -> void:
	data = defaults()
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				data.merge(parsed, true)

static func defaults() -> Dictionary:
	return {"version":1,"points":0,"highestNight":1,"owned":[],"endings":[],"discovered":[],"sound":true,"timerOff":false,"run":{},"awarded":false}

func save() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func reset() -> void:
	data = defaults()
	save()
