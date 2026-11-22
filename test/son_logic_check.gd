extends SceneTree

const Logic = preload("res://scripts/game/son_logic.gd")

func _initialize() -> void:
	var game = Logic.new()
	assert(game.guests.size() >= 60)
	game.start_night(1,{"owned":[],"discovered":[]})
	assert(game.state.deck.size() == 8)
	for chapter in game.state.deck:
		assert(chapter.size() == 7)
	game.state.rooms = 0
	assert(game._check_failure() and game.state.ending == "full")
	game.start_night(1,{"owned":[],"discovered":[]})
	game.state.wood = 0
	assert(game._check_failure() and game.state.ending == "cold")
	game.start_night(1,{"owned":[],"discovered":[]})
	game.state.trust = 0
	assert(game._check_failure() and game.state.ending == "trust")
	game.start_night(18,{"owned":["roomkey"],"discovered":[]})
	assert(game.state.rule2 >= 0)
	game.state.weather = "calm"
	game.state.deck[0][0] = "guest_17"
	game.begin_chapter()
	game.decide(true)
	assert(game.state.phase == "merchant" and game.state.roomkeyUsed)
	var before_trade = game.state.wood
	game.merchant_choice(true)
	assert(game.state.phase == "peephole" and game.state.wood > before_trade)
	game.start_night(1,{"owned":["wood1"],"discovered":[]})
	game.state.weather = "calm"
	game.state.rule = 0
	var initial_magnifiers = game.state.magnifiers
	game.begin_chapter()
	assert(game.reveal())
	assert(game.state.magnifiers < initial_magnifiers)
	var completed = 0
	for ch in range(8):
		if game.state.phase == "chapter": game.begin_chapter()
		while game.state.phase in ["peephole","card"]:
			var guest = game.current_guest()
			var accept = game.state.accepted < 12 and guest.hiddenType not in ["THIEF","LIAR"]
			game.decide(accept)
		if game.state.phase == "ending": break
		assert(game.state.phase == "event")
		if ch in [1,2,5]: game.event_choice("suspect","none")
		elif ch == 0: game.event_choice("share")
		elif ch == 3: game.event_choice("wait")
		elif ch == 4: game.event_choice("chairs")
		elif ch == 6: game.event_choice("help")
		else: game.event_choice("morning")
		completed += 1
		if game.state.phase == "report": game.next_chapter()
	assert(completed == 8, "A full night should reach all eight events")
	assert(game.state.phase == "ending")
	assert(game.points() > 0)
	assert(game.content.endings.size() == 20)
	assert(game.content.upgrades.size() >= 25)
	assert(game.content.rules.size() >= 40)
	print("[son-yolcu] PASS")
	quit(0)
