extends Node

signal status_changed
signal save_restored

const META_PATH := "user://son_yolcu_cloud.json"
var store
var status := "offline"
var user_id := 0
var user_name := ""
var meta := {"owner": 0, "revision": 0, "dirty": false}
var _bridge
var _callback
var _busy := false
var _operation := ""
var _request_user := 0
var _generation := 0
var _request_generation := 0
var _retry_in := 0.0
var _remote: Dictionary = {}

func configure(local_store) -> void:
	store = local_store
	_load_meta()
	store.changed.connect(_local_changed)
	ManusAuth.auth_state_changed.connect(_auth_changed)
	ManusAuth.auth_error.connect(_auth_error)
	if OS.has_feature("web"):
		_bridge = JavaScriptBridge.get_interface("SonCloud")
		_callback = JavaScriptBridge.create_callback(_response)
	_auth_changed(ManusAuth.get_session())

func _load_meta() -> void:
	if not FileAccess.file_exists(META_PATH): return
	var file = FileAccess.open(META_PATH, FileAccess.READ)
	if not file: return
	var loaded = JSON.parse_string(file.get_as_text())
	file.close()
	if loaded is Dictionary:
		meta.owner = maxi(0, int(loaded.get("owner", 0)))
		meta.revision = maxi(0, int(loaded.get("revision", 0)))
		meta.dirty = bool(loaded.get("dirty", false))

func _save_meta() -> void:
	var file = FileAccess.open(META_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(meta))
		file.close()

func _set_status(value: String) -> void:
	status = value
	status_changed.emit()

func _auth_changed(session: Dictionary) -> void:
	var previous = user_id
	var state = str(session.get("status", "offline"))
	var player = session.get("user")
	if state == "authenticated" and player is Dictionary:
		user_id = int(player.get("id", 0))
		user_name = str(player.get("name", ""))
		if user_id <= 0:
			user_id = 0
			_set_status("offline")
			return
		if previous != user_id:
			_remote = {}
			_set_status("checking")
		if not _busy and (previous != user_id or status != "conflict"):
			_read()
	else:
		user_id = 0
		user_name = ""
		_remote = {}
		_retry_in = 0.0
		_set_status("logged_out" if state == "logged_out" else "offline")

func _auth_error(_error: String) -> void:
	if user_id == 0: _set_status("offline")

func _local_changed() -> void:
	_generation += 1
	meta.dirty = true
	_save_meta()
	if user_id > 0 and status != "conflict":
		if not _busy:
			_set_status("pending")
			_retry_in = 1.5

func _process(delta: float) -> void:
	if _retry_in <= 0 or _busy or user_id <= 0 or status == "conflict": return
	_retry_in -= delta
	if _retry_in <= 0:
		_read()

func _send(operation: String, input: Dictionary = {}) -> void:
	if _busy or _bridge == null or _callback == null:
		if _bridge == null: _set_status("offline")
		return
	_busy = true
	_operation = operation
	_request_user = user_id
	_request_generation = _generation
	_bridge.invoke(operation, JSON.stringify(input), _callback)

func _read() -> void:
	if user_id <= 0 or _busy: return
	_retry_in = 0.0
	_set_status("checking")
	_send("read")

func _write() -> void:
	if user_id <= 0 or _busy: return
	_set_status("saving")
	_send("write", {"expectedRevision": int(meta.revision), "snapshot": JSON.stringify(store.data)})

func retry() -> void:
	if _busy: return
	if user_id > 0:
		_read()
	else:
		_set_status("checking")
		_send("refresh")

func _response(args: Array) -> void:
	var operation = _operation
	var request_user = _request_user
	var request_generation = _request_generation
	_busy = false
	_operation = ""
	if operation != "refresh" and request_user != user_id:
		if user_id > 0: _read()
		return
	var payload = JSON.parse_string(str(args[0])) if not args.is_empty() else null
	if not payload is Dictionary or not bool(payload.get("ok", false)):
		_set_status("error" if user_id > 0 else "offline")
		if user_id > 0: _retry_in = 15.0
		return
	if operation == "refresh":
		if user_id > 0: _read()
		return
	var result = payload.get("result", {})
	if not result is Dictionary:
		_set_status("error")
		_retry_in = 15.0
		return
	if operation == "read":
		_reconcile(result, request_generation)
	elif operation == "write":
		if bool(result.get("saved", false)):
			meta.owner = user_id
			meta.revision = int(result.get("revision", 0))
			meta.dirty = _generation != request_generation
			_save_meta()
			_set_status("pending" if meta.dirty else "synced")
			if meta.dirty: _retry_in = 1.5
		elif bool(result.get("conflict", false)):
			_read()
		else:
			_set_status("error")
			_retry_in = 15.0

func _reconcile(result: Dictionary, request_generation: int) -> void:
	var exists = bool(result.get("exists", false))
	var revision = int(result.get("revision", 0))
	var changed_during_read = _generation != request_generation
	if not exists:
		if (int(meta.owner) != 0 and int(meta.owner) != user_id and store.had_file) or (int(meta.owner) == user_id and int(meta.revision) > 0):
			_remote = {"exists": false, "revision": 0}
			_set_status("conflict")
			return
		meta.owner = user_id
		meta.revision = 0
		meta.dirty = true
		_save_meta()
		_write()
		return
	var parsed = JSON.parse_string(str(result.get("snapshot", "")))
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1 or revision < 1:
		_set_status("error")
		return
	var remote: Dictionary = parsed
	if JSON.stringify(remote) == JSON.stringify(store.data):
		meta = {"owner": user_id, "revision": revision, "dirty": false}
		_save_meta()
		_set_status("synced")
		return
	if not store.had_file and not changed_during_read:
		_restore(remote, revision)
		return
	if int(meta.owner) == user_id and revision == int(meta.revision) and bool(meta.dirty):
		_write()
		return
	if int(meta.owner) == user_id and revision > int(meta.revision) and not bool(meta.dirty) and not changed_during_read:
		_restore(remote, revision)
		return
	_remote = {"exists": true, "revision": revision, "snapshot": remote}
	_set_status("conflict")

func _restore(snapshot: Dictionary, revision: int) -> void:
	store.replace_from_cloud(snapshot)
	meta = {"owner": user_id, "revision": revision, "dirty": false}
	_save_meta()
	_remote = {}
	_set_status("synced")
	save_restored.emit()

func choose_local() -> void:
	if status != "conflict" or user_id <= 0 or _busy: return
	meta.owner = user_id
	meta.revision = int(_remote.get("revision", 0))
	meta.dirty = true
	_save_meta()
	_remote = {}
	_write()

func choose_cloud() -> void:
	if status != "conflict" or user_id <= 0 or _busy: return
	if bool(_remote.get("exists", false)):
		_restore(_remote.snapshot, int(_remote.revision))
	else:
		store.replace_from_cloud({})
		meta = {"owner": user_id, "revision": 0, "dirty": true}
		_save_meta()
		_remote = {}
		save_restored.emit()
		_write()
