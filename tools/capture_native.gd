extends SceneTree

# Native-renderer captures exercise the real title, card and notebook interfaces.
func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var main = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("/tmp/son-menu.png")
	main._start_night(1)
	main._begin_chapter()
	await process_frame
	await process_frame
	assert(main.screen == "game")
	main._question(0)
	main._open_card()
	main._reveal()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("/tmp/son-card.png")
	main._decide(true)
	main._open_notebook("game")
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	root.get_texture().get_image().save_png("/tmp/son-notebook.png")
	assert(main.logic.state.people.size() == 1)
	print("[son-ui] PASS")
	quit(0)
