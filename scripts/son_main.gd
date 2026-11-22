extends Control

const Logic = preload("res://scripts/game/son_logic.gd")
const Save = preload("res://scripts/game/son_save.gd")
const Portrait = preload("res://scripts/ui/guest_portrait.gd")
const Sound = preload("res://scripts/game/son_sound.gd")
const Snow = preload("res://scripts/ui/quiet_snow.gd")
const BACKGROUNDS := {
	"hotel-dusk": preload("res://assets/son-yolcu/hotel-dusk.png"),
	"hotel-midnight": preload("res://assets/son-yolcu/hotel-midnight.png"),
	"hotel-dawn": preload("res://assets/son-yolcu/hotel-dawn.png"),
	"hotel-blizzard": preload("res://assets/son-yolcu/hotel-blizzard.png")
}
const INK := Color(0.78,0.77,0.72,1)
const MUTED := Color(0.55,0.56,0.54,1)
const ACCENT := Color(0.73,0.48,0.31,1)
const PANEL := Color(0.065,0.075,0.085,0.96)
const OUTLINE := Color(0.30,0.31,0.30,1)

var logic = Logic.new()
var store = Save.new()
var screen := "menu"
var page: Control
var bg: TextureRect
var shade: ColorRect
var sound_player: AudioStreamPlayer
var sounds: Dictionary = {}
var how_page := 0
var settings_return := "menu"
var notebook_return := "game"
var reset_armed := false
var pointer_start := Vector2.ZERO
var pointer_down := false
var note_line := ""
var ending_points := 0
var selected_night := 1
var search_mode := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var own_theme = Theme.new()
	own_theme.default_font = load("res://assets/son-yolcu/DejaVuSansMono.ttf")
	own_theme.default_font_size = 17
	theme = own_theme
	bg = TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	shade = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02,0.03,0.04,0.22)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_child(Snow.new())
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -6
	add_child(sound_player)
	for id in ["swipe", "knock", "wind", "fire"]:
		sounds[id] = Sound.cue(id)
	I18n.locale_changed.connect(_on_locale_changed)
	if not store.data.run.is_empty():
		logic.state = store.data.run.duplicate(true)
	show_menu()

func _on_locale_changed(_locale: String) -> void:
	render()

func t(key: String, replacements: Dictionary = {}) -> String:
	return I18n.t(key, replacements)

func localized(item: Dictionary, field: String) -> String:
	var translated = field + "_az"
	return str(item.get(translated, item.get(field, ""))) if I18n.get_locale() == "az" else str(item.get(field, ""))

func localized_array(key: String) -> Array:
	var name = key + "_az" if I18n.get_locale() == "az" else key
	return logic.content.get(name, logic.content.get(key, []))

func _sound(id: String) -> void:
	if not bool(store.data.sound) or not sounds.has(id): return
	sound_player.stream = sounds[id]
	sound_player.play()

func _background() -> void:
	var name = "hotel-dusk"
	if not logic.state.is_empty() and screen in ["chapter","game","event","report","notebook","storm","ending"]:
		if logic.state.get("weather", "") == "blizzard":
			name = "hotel-blizzard"
		elif int(logic.state.get("chapter",0)) >= 7:
			name = "hotel-dawn"
		elif int(logic.state.get("chapter",0)) >= 3:
			name = "hotel-midnight"
	bg.texture = BACKGROUNDS[name]
	var dim = 0.40 if screen in ["game","event","notebook"] else 0.25
	if not logic.state.is_empty() and screen in ["game","event","chapter"]:
		dim += 0.16 * (1.0 - float(logic.state.get("wood",100)) / 100.0)
	shade.color = Color(0.02,0.03,0.04,dim)

func _base() -> VBoxContainer:
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	_background()
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)
	page = margin
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	return box

func _text(value: String, size: int = 17, color: Color = INK, center: bool = true) -> Label:
	var label = Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	return label

func _button(value: String, action: Callable, size: int = 16, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Button:
	var button = Button.new()
	button.text = value
	button.flat = true
	button.alignment = align
	button.custom_minimum_size = Vector2(0, 42)
	button.add_theme_font_size_override("font_size", size)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", ACCENT)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_color_override("font_focus_color", INK)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	return button

func _gap(box: VBoxContainer, min_height: float = 0) -> void:
	var gap = Control.new()
	gap.custom_minimum_size.y = min_height
	if min_height == 0: gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(gap)

func _divider(box: VBoxContainer) -> void:
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(0, 1)
	line.color = Color(0.28,0.29,0.28,0.8)
	box.add_child(line)

func _scroller(parent: VBoxContainer) -> VBoxContainer:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	return box

func _persist() -> void:
	store.data.run = logic.state.duplicate(true)
	store.data.discovered = logic.state.get("discovered", []).duplicate()
	store.save()

func _resolve_screen() -> void:
	if logic.state.is_empty():
		show_menu()
		return
	var phase = str(logic.state.phase)
	if phase == "ending":
		_settle_ending()
		screen = "ending"
	elif phase in ["peephole", "card"]:
		screen = "game"
	else:
		screen = phase
	_persist()
	render()

func render() -> void:
	match screen:
		"menu": _menu()
		"how": _how()
		"nights": _nights()
		"chapter": _chapter()
		"game": _game()
		"notebook": _notebook()
		"event": _event()
		"report": _report()
		"storm": _storm()
		"merchant": _merchant()
		"ending": _ending()
		"shop": _shop()
		"gallery": _gallery()
		"settings": _settings()
		_: _menu()

func show_menu() -> void:
	screen = "menu"
	render()

func _menu() -> void:
	var box = _base()
	_gap(box, 80)
	box.add_child(_text(t("title"), 32, INK))
	box.add_child(_text(t("subtitle"), 14, MUTED))
	_gap(box, 24)
	if not logic.state.is_empty() and not bool(logic.state.get("ended",false)):
		box.add_child(_button(t("continue"), _resolve_screen))
	box.add_child(_button(t("start"), _start_latest, 18))
	box.add_child(_button(t("nights"), func(): screen = "nights"; render()))
	box.add_child(_button(t("how"), func(): how_page = 0; screen = "how"; render()))
	box.add_child(_button(t("shop"), func(): screen = "shop"; render()))
	box.add_child(_button(t("gallery"), func(): screen = "gallery"; render()))
	box.add_child(_button(t("settings"), _open_settings.bind("menu")))
	_gap(box)
	box.add_child(_text("%s  ·  %d" % [t("points"), int(store.data.points)], 12, MUTED))

func _start_latest() -> void:
	_start_night(int(store.data.highestNight))

func _start_night(night: int) -> void:
	selected_night = night
	logic.start_night(night, store.data)
	store.data.awarded = false
	note_line = ""
	_sound("wind")
	_resolve_screen()

func _how() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), show_menu, 14, HORIZONTAL_ALIGNMENT_LEFT))
	_gap(box)
	box.add_child(_text("%02d  /  03" % (how_page + 1), 13, MUTED))
	_gap(box, 18)
	box.add_child(_text(t("intro%d" % (how_page + 1)), 20))
	_gap(box)
	box.add_child(_button(t("next") if how_page < 2 else t("start"), _advance_how, 16))

func _advance_how() -> void:
	if how_page < 2:
		how_page += 1
		render()
	else:
		_start_latest()

func _nights() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), show_menu, 14, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_text(t("nights"), 21))
	var list = _scroller(box)
	for n in range(1,31):
		var night_data = logic.nights[n - 1]
		var caption = "%s %02d   ·   %s" % [t("night"), n, localized(night_data,"title")]
		var button = _button(caption if n <= int(store.data.highestNight) else "%s %02d   ·   —" % [t("night"),n], _start_night.bind(n), 14, HORIZONTAL_ALIGNMENT_LEFT)
		button.disabled = n > int(store.data.highestNight)
		list.add_child(button)

func _chapter() -> void:
	var box = _base()
	var ch: Dictionary = logic.content.chapters[logic.state.chapter]
	box.add_child(_text("%s %02d  /  %s" % [t("night"),logic.state.night,t("chapter")], 13, MUTED))
	_gap(box)
	box.add_child(_text(str(ch.clock), 14, MUTED))
	box.add_child(_text(localized(ch,"title").to_upper(), 25))
	box.add_child(_text(localized(ch,"intro"), 15, MUTED))
	if int(logic.state.chapter) == 0:
		box.add_child(_text(localized(logic.nights[int(logic.state.night)-1],"intro"), 13, MUTED))
	_gap(box, 20)
	if int(logic.state.chapter) == 0:
		var rule: Dictionary = logic.content.rules[logic.state.rule]
		box.add_child(_text(t("rule") + ": " + localized(rule,"text"), 14))
		if int(logic.state.rule2) >= 0:
			box.add_child(_text(localized(logic.content.rules[logic.state.rule2],"text"), 14))
		box.add_child(_text(t("weather") + ": " + t(str(logic.state.weather)), 13, MUTED))
	_gap(box)
	box.add_child(_button(t("begin"), _begin_chapter, 16))

func _begin_chapter() -> void:
	logic.begin_chapter()
	_sound("knock")
	_resolve_screen()

func _meter(icon: String, value: float) -> VBoxContainer:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	box.add_child(_text(icon, 17, MUTED))
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(58,3)
	bar.max_value = 100
	bar.value = clampf(value,0,100)
	bar.show_percentage = false
	var back = StyleBoxFlat.new()
	back.bg_color = Color(0.25,0.27,0.27,1)
	var fill = StyleBoxFlat.new()
	fill.bg_color = ACCENT if value < 30 else Color(0.62,0.61,0.57,1)
	bar.add_theme_stylebox_override("background", back)
	bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	return box

func _game() -> void:
	var box = _base()
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 20)
	box.add_child(top)
	top.add_child(_meter("□",logic.state.rooms))
	top.add_child(_meter("♨",logic.state.wood))
	top.add_child(_meter("◇",logic.state.trust))
	var clock = _text(str(logic.content.chapters[logic.state.chapter].clock), 13, MUTED)
	clock.custom_minimum_size.x = 62
	top.add_child(clock)
	_gap(box, 14)
	var body = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	box.add_child(body)
	var left = _button("‹", _decide.bind(false), 30)
	left.custom_minimum_size.x = 32
	body.add_child(left)
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = OUTLINE
	style.set_border_width_all(1)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	body.add_child(panel)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var card = VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_constant_override("separation", 9)
	scroll.add_child(card)
	var guest = logic.current_guest()
	if guest.is_empty(): return
	var peephole = logic.state.phase == "peephole"
	card.add_child(_text(t("listening") if peephole else str(guest.name).to_upper(), 13 if peephole else 21, MUTED if peephole else INK))
	var portrait = Portrait.new()
	portrait.appearance = guest.appearance
	portrait.silhouette = peephole
	card.add_child(portrait)
	card.add_child(_text("“" + localized(guest,"story") + "”", 17))
	if not logic.state.answer.is_empty():
		card.add_child(_text(t("answer") + ": " + str(logic.state.answer), 13, MUTED))
	if logic.state.revealed:
		_divider(card)
		card.add_child(_text(t("clue"), 11, ACCENT))
		card.add_child(_text(localized(guest,"clue"), 14))
	var connected = logic.connection_status(guest)
	if not connected.is_empty():
		card.add_child(_text(t("known_inside") + " " + connected, 12, MUTED))
	if logic.owned("rulehint") and logic.rule_broken(guest, false, logic.state.questionCount):
		card.add_child(_text(t("rule") + " · " + localized(logic.content.rules[logic.state.rule],"text"), 12, ACCENT))
	if logic.owned("dog") and not logic.state.dogUsed and guest.hiddenType == "THIEF":
		logic.state.dogUsed = true
		note_line = t("dog")
	if peephole:
		_gap(card, 2)
		var questions = localized_array("questions")
		var max_questions = 2 if logic.owned("question") else 1
		if logic.state.questionCount < max_questions:
			card.add_child(_text(t("ask"), 11, MUTED))
			for i in range(3):
				card.add_child(_button(str(questions[i]), _question.bind(i), 13))
		card.add_child(_button(t("open"), _open_card, 14))
	if logic.owned("peek"):
		var peek = logic.next_guest()
		if not peek.is_empty(): card.add_child(_text(t("peek") + " " + localized(peek,"story").split(".")[0] + ".", 11, MUTED))
	if logic.owned("undo") and not logic.state.undoUsed and not logic.state.lastSnapshot.is_empty():
		card.add_child(_button(t("undo"), _undo, 11))
	if logic.owned("second") and not logic.state.secondUsed and not str(logic.state.lastGuest).is_empty():
		card.add_child(_button(t("look"), _look_last, 11))
	if logic.owned("radio"):
		card.add_child(_text(t("next_event") + " " + t("event") + " " + str(int(logic.state.chapter) + 1), 11, MUTED))
	if logic.owned("detector") and logic.state.lastTwo.size() == 2:
		var one = logic.guest_by_id(str(logic.state.lastTwo[0]))
		card.add_child(_text(t("related") if logic.state.lastTwo[1] in one.connectionIds else t("unrelated"), 11, MUTED))
	var right = _button("›", _decide.bind(true), 30)
	right.custom_minimum_size.x = 32
	body.add_child(right)
	var narration = note_line
	var wait_limit = 30.0 if logic.owned("wait") else 15.0
	if float(logic.state.clockWait) > wait_limit: narration = t("waiting")
	if narration.is_empty(): narration = t("hint")
	box.add_child(_text(narration, 11, MUTED))
	var tools = HBoxContainer.new()
	tools.alignment = BoxContainer.ALIGNMENT_CENTER
	tools.add_theme_constant_override("separation", 42)
	box.add_child(tools)
	tools.add_child(_button("▤", _open_notebook.bind("game"), 22))
	var dots = ""
	for i in range(int(logic.state.magnifiers)): dots += "·"
	tools.add_child(_button("⌕ " + dots, _reveal, 22))

func _question(which: int) -> void:
	if logic.ask_question(which, I18n.get_locale()):
		_sound("swipe")
		note_line = ""
	else:
		note_line = t("no_magnifier")
	_persist()
	render()

func _open_card() -> void:
	logic.open_card()
	_persist()
	render()

func _reveal() -> void:
	if logic.reveal():
		note_line = ""
		_sound("swipe")
	else: note_line = t("no_magnifier")
	_persist()
	render()

func _decide(admit: bool) -> void:
	if screen != "game": return
	logic.decide(admit, I18n.get_locale())
	note_line = ""
	if int(logic.state.index) > 0 and int(logic.state.index) % 3 == 0:
		var radio_lines = localized_array("radio")
		var radio_index = (int(logic.state.chapter) + int(logic.state.index)) % radio_lines.size()
		note_line = str(radio_lines[radio_index])
		if logic.owned("clear_radio") and radio_index in [3,5]: note_line += " · " + t("old_news")
	_sound("swipe")
	_resolve_screen()
	if screen == "game": _sound("knock")

func _undo() -> void:
	if logic.undo():
		note_line = ""
		_resolve_screen()

func _look_last() -> void:
	var last = logic.guest_by_id(str(logic.state.lastGuest))
	if not last.is_empty(): note_line = str(last.name) + ": " + localized(last,"story")
	logic.state.secondUsed = true
	_persist()
	render()

func _open_notebook(origin: String) -> void:
	notebook_return = origin
	screen = "notebook"
	render()

func _notebook() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), _return_notebook, 14, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_text(t("notebook"), 21))
	var list = _scroller(box)
	list.add_child(_button(t("story_page"), _story_page, 14, HORIZONTAL_ALIGNMENT_LEFT))
	list.add_child(_button(t("drawer"), _drawer, 14, HORIZONTAL_ALIGNMENT_LEFT))
	if not note_line.is_empty(): list.add_child(_text(note_line, 13, MUTED, false))
	list.add_child(_text(t("room7"), 12, MUTED, false))
	_divider(list)
	if logic.state.people.is_empty(): list.add_child(_text(t("notebook_empty"), 14, MUTED))
	for person in logic.state.people:
		var guest = logic.guest_by_id(str(person.id))
		list.add_child(_text(str(person.name).to_upper(), 16, INK, false))
		list.add_child(_text(t("guest_story") + ": " + localized(guest,"story"), 13, MUTED, false))
		if person.clueRevealed: list.add_child(_text(t("clue") + ": " + localized(guest,"clue"), 13, INK, false))
		if not str(person.answer).is_empty(): list.add_child(_text(t("answer") + ": " + str(person.answer), 13, MUTED, false))
		var note = TextEdit.new()
		note.custom_minimum_size = Vector2(0, 62)
		note.placeholder_text = t("note_placeholder")
		note.text = str(person.note)
		note.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		note.add_theme_font_size_override("font_size", 13)
		note.text_changed.connect(_note_changed.bind(str(person.id),note))
		list.add_child(note)
		list.add_child(_button(t("tag") + ": " + t(str(person.tag) if person.tag != "trust" else "trust_tag"), _cycle_tag.bind(str(person.id)), 13, HORIZONTAL_ALIGNMENT_LEFT))
		_divider(list)
	list.add_child(_button(t("menu"), show_menu, 13))

func _return_notebook() -> void:
	note_line = ""
	screen = notebook_return
	render()

func _story_page() -> void:
	var pieces = localized_array("storyPieces")
	var lines: Array = []
	for index in logic.state.discovered:
		if int(index) < pieces.size(): lines.append(str(pieces[index]))
	note_line = "\n".join(lines) if not lines.is_empty() else t("no_story")
	render()

func _drawer() -> void:
	note_line = t("drawer_text")
	if 2 not in logic.state.discovered and logic.state.foundThisNight < 2:
		logic.state.discovered.append(2)
		logic.state.foundThisNight += 1
	_persist()
	render()

func _note_changed(id: String, edit: TextEdit) -> void:
	for person in logic.state.people:
		if person.id == id:
			person.note = edit.text.left(500)
			break
	_persist()

func _cycle_tag(id: String) -> void:
	for person in logic.state.people:
		if person.id == id:
			var tags = ["unknown","trust","suspect"]
			person.tag = tags[(tags.find(person.tag)+1)%tags.size()]
			break
	_persist()
	render()

func _event() -> void:
	var box = _base()
	box.add_child(_text(t("event"), 13, MUTED))
	_gap(box, 12)
	var index = int(logic.state.chapter)
	box.add_child(_text(t("event%d" % index), 18))
	if index == 6 and logic.has_role("doctor"): box.add_child(_text(t("doctor_inside"), 13, MUTED))
	if not note_line.is_empty(): box.add_child(_text(note_line, 13, ACCENT))
	var list = _scroller(box)
	_gap(list, 12)
	if index in [1,2,5]:
		for person in logic.state.people:
			if search_mode:
				list.add_child(_button(str(person.name), _search_person.bind(str(person.id)), 15))
			else:
				list.add_child(_button(str(person.name), _event_select.bind("suspect",str(person.id)), 15))
		if not search_mode: list.add_child(_button(t("none"), _event_select.bind("suspect","none"), 14))
		if logic.owned("masterkey") and not logic.state.searchUsed and not logic.state.people.is_empty():
			list.add_child(_button(t("cancel") if search_mode else t("search"), _toggle_search, 12))
	elif index == 0:
		list.add_child(_button(t("share"), _event_select.bind("share","")))
		list.add_child(_button(t("keep"), _event_select.bind("keep","")))
	elif index == 3:
		list.add_child(_button(t("wait"), _event_select.bind("wait","")))
		list.add_child(_button(t("check"), _event_select.bind("check","")))
	elif index == 4:
		list.add_child(_button(t("chairs"), _event_select.bind("chairs","")))
		list.add_child(_button(t("blankets"), _event_select.bind("blankets","")))
	elif index == 6:
		list.add_child(_button(t("help"), _event_select.bind("help","")))
		list.add_child(_button(t("do_nothing"), _event_select.bind("wait","")))
	else:
		list.add_child(_button(t("sign"), _event_select.bind("sign","")))
		list.add_child(_button(t("secret"), _event_select.bind("secret","")))
		list.add_child(_button(t("page"), _event_select.bind("page","")))
		if logic.state.discovered.size() >= 5: list.add_child(_button(t("saved"), _event_select.bind("saved",""), 13))
		list.add_child(_button(t("morning"), _event_select.bind("morning","")))
	if logic.owned("undo") and not logic.state.undoUsed and not logic.state.lastSnapshot.is_empty():
		list.add_child(_button(t("undo"), _undo, 11))
	box.add_child(_button("▤  " + t("notebook"), _open_notebook.bind("event"), 14))

func _event_select(action: String, id: String) -> void:
	logic.event_choice(action,id)
	note_line = ""
	search_mode = false
	_sound("fire" if int(logic.state.chapter) in [0,4] else "swipe")
	_resolve_screen()

func _toggle_search() -> void:
	search_mode = not search_mode
	render()

func _search_person(id: String) -> void:
	var guest = logic.guest_by_id(id)
	if guest.is_empty(): return
	note_line = t("searched") + " " + str(guest.name) + ": " + localized(guest,"clue")
	logic.state.searchUsed = true
	search_mode = false
	_persist()
	render()

func _merchant() -> void:
	var box = _base()
	_gap(box)
	box.add_child(_text(t("merchant_title"), 21))
	box.add_child(_text(t("merchant_text"), 16, MUTED))
	_gap(box, 25)
	box.add_child(_button(t("merchant_trade"), _merchant_choice.bind(true)))
	box.add_child(_button(t("merchant_decline"), _merchant_choice.bind(false)))
	_gap(box)

func _merchant_choice(trade: bool) -> void:
	logic.merchant_choice(trade)
	_resolve_screen()

func _report() -> void:
	var box = _base()
	box.add_child(_text(t("report"), 14, MUTED))
	_gap(box, 15)
	var list = _scroller(box)
	for entry in logic.state.reports:
		var suffix = t("admitted_report") if entry.admitted else t("rejected_report")
		list.add_child(_text(str(entry.name) + " " + suffix, 14, INK, false))
	box.add_child(_button(t("next"), _next_chapter))

func _next_chapter() -> void:
	logic.next_chapter()
	_resolve_screen()

func _storm() -> void:
	var box = _base()
	_gap(box)
	box.add_child(_text(t("storm_title"), 24))
	box.add_child(_text(t("storm_text"), 17, MUTED))
	_gap(box, 30)
	box.add_child(_button(t("storm_open"), _storm_choice.bind(true)))
	box.add_child(_button(t("storm_close"), _storm_choice.bind(false)))
	_gap(box)

func _storm_choice(open_doors: bool) -> void:
	logic.storm_choice(open_doors)
	_resolve_screen()

func _settle_ending() -> void:
	if bool(store.data.awarded):
		ending_points = int(store.data.get("lastPoints",0))
		return
	ending_points = logic.points()
	store.data.points += ending_points
	if logic.state.ending not in store.data.endings: store.data.endings.append(logic.state.ending)
	store.data.discovered = logic.state.discovered.duplicate()
	if logic.state.ending not in ["full","cold","trust","empty","spoon","wrong"]:
		store.data.highestNight = mini(30,maxi(int(store.data.highestNight),int(logic.state.night)+1))
	store.data.lastPoints = ending_points
	store.data.awarded = true
	store.save()

func _ending() -> void:
	var box = _base()
	var ending = logic.ending_data(str(logic.state.ending))
	_gap(box)
	if str(logic.state.ending) != "perfect": box.add_child(_text(localized(ending,"title").to_upper(), 22))
	box.add_child(_text(localized(ending,"text"), 17))
	if str(logic.state.ending) != "perfect":
		_gap(box, 12)
		box.add_child(_text(t("stats", {"accepted":logic.state.accepted,"rejected":logic.state.rejected,"correct":logic.state.correct}), 12, MUTED))
		box.add_child(_text(t("earned") + "  ·  " + str(ending_points), 12, MUTED))
	_gap(box)
	box.add_child(_button(t("again"), _start_latest))
	box.add_child(_button(t("menu"), show_menu, 14))

func _shop() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), show_menu, 14, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_text(t("shop"), 21))
	box.add_child(_text("%s  ·  %d" % [t("points"),store.data.points], 13, ACCENT))
	if not note_line.is_empty(): box.add_child(_text(note_line, 13, MUTED))
	var list = _scroller(box)
	list.add_child(_text(t("shop_info"), 13, MUTED, false))
	for item in logic.content.upgrades:
		var already = item.id in store.data.owned
		var label = ("● " if already else "○ ") + localized(item,"title") + ("  ·  " + t("owned") if already else "  ·  " + str(item.cost))
		var button = _button(label, _buy.bind(str(item.id)), 14, HORIZONTAL_ALIGNMENT_LEFT)
		button.disabled = already
		list.add_child(button)
		list.add_child(_text(localized(item,"desc"), 12, MUTED, false))
		_divider(list)

func _buy(id: String) -> void:
	for item in logic.content.upgrades:
		if item.id == id and id not in store.data.owned:
			if int(store.data.points) >= int(item.cost):
				store.data.points -= int(item.cost)
				store.data.owned.append(id)
				store.save()
				note_line = ""
				_sound("swipe")
			else: note_line = t("not_enough")
			break
	render()

func _gallery() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), show_menu, 14, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_text(t("collected"), 21))
	var list = _scroller(box)
	for i in range(logic.content.endings.size()):
		var item: Dictionary = logic.content.endings[i]
		if item.id in store.data.endings:
			list.add_child(_text("%02d  %s" % [i+1, localized(item,"title")], 14, INK, false))
			list.add_child(_text(localized(item,"text"), 12, MUTED, false))
		else:
			list.add_child(_text("%02d  ──────────" % (i+1), 14, MUTED, false))
		_divider(list)

func _open_settings(origin: String) -> void:
	settings_return = origin
	reset_armed = false
	screen = "settings"
	render()

func _settings() -> void:
	var box = _base()
	box.add_child(_button("←  " + t("back"), _settings_back, 14, HORIZONTAL_ALIGNMENT_LEFT))
	box.add_child(_text(t("settings"), 21))
	_gap(box, 26)
	box.add_child(_button(t("sound") + "  ·  " + t("sound_on" if store.data.sound else "sound_off"), _toggle_sound))
	box.add_child(_button(t("language") + "  ·  " + ("TÜRKÇE" if I18n.get_locale() == "tr" else "AZƏRBAYCANCA"), _toggle_language))
	box.add_child(_button(t("timer") + "  ·  " + t("timer_off" if store.data.timerOff else "timer_on"), _toggle_timer))
	_gap(box, 18)
	if reset_armed:
		box.add_child(_text(t("confirm_reset"), 14, MUTED))
		box.add_child(_button(t("yes"), _reset))
		box.add_child(_button(t("cancel"), func(): reset_armed = false; render()))
	else: box.add_child(_button(t("reset"), func(): reset_armed = true; render(), 14))
	_gap(box)
	box.add_child(_text(t("save_info"), 12, MUTED))

func _settings_back() -> void:
	screen = settings_return
	render()

func _toggle_sound() -> void:
	store.data.sound = not bool(store.data.sound)
	store.save()
	render()

func _toggle_language() -> void:
	I18n.toggle_locale()

func _toggle_timer() -> void:
	store.data.timerOff = not bool(store.data.timerOff)
	store.save()
	render()

func _reset() -> void:
	store.reset()
	logic.state = {}
	note_line = ""
	show_menu()

func _process(delta: float) -> void:
	if screen == "game" and not logic.state.is_empty():
		if logic.tick_wait(delta, bool(store.data.timerOff)):
			_resolve_screen()

func _input(event: InputEvent) -> void:
	if screen != "game": return
	if event is InputEventScreenTouch:
		if event.pressed:
			pointer_start = event.position
			pointer_down = true
		elif pointer_down:
			var difference = event.position - pointer_start
			pointer_down = false
			if absf(difference.x) > 90 and absf(difference.x) > absf(difference.y) * 1.3:
				_decide(difference.x > 0)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_start = event.position
			pointer_down = true
		elif pointer_down:
			var difference = event.position - pointer_start
			pointer_down = false
			if absf(difference.x) > 90 and absf(difference.x) > absf(difference.y) * 1.3:
				_decide(difference.x > 0)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT: _decide(false)
		if event.keycode == KEY_RIGHT: _decide(true)
