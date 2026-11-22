class_name SonSave
extends RefCounted

signal changed

const SAVE_PATH := "user://son_yolcu_progress.json"
var data: Dictionary = {}
var had_file := false

func _init() -> void:
	data = defaults()
	had_file = FileAccess.file_exists(SAVE_PATH)
	if had_file:
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				data.merge(parsed, true)

static func defaults() -> Dictionary:
	return {"version":1,"points":0,"highestNight":1,"owned":[],"endings":[],"discovered":[],"sound":true,"timerOff":false,"run":{},"awarded":false}

func save(notify: bool = true) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		had_file = true
		if notify: changed.emit()

func replace_from_cloud(snapshot: Dictionary) -> void:
	if had_file:
		var backup = FileAccess.open("user://son_yolcu_before_cloud.json", FileAccess.WRITE)
		if backup:
			backup.store_string(JSON.stringify(data))
			backup.close()
	data = defaults()
	data.merge(snapshot, true)
	save(false)

func reset() -> void:
	data = defaults()
	save()
