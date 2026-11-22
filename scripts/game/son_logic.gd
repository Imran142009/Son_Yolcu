class_name SonLogic
extends RefCounted

const WEATHER := ["calm", "blizzard", "fog", "moon"]
const TIMES := ["18:00", "20:00", "22:00", "00:00", "02:00", "03:30", "05:00", "06:00"]
const STORY_ROLES := {"shepherd":0, "old_guest":1, "coin":2, "radio":3, "nurse":4, "room7":5, "silent":6, "reveal":7}

var guests: Array = []
var content: Dictionary = {}
var nights: Array = []
var state: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _init() -> void:
	guests = _read_json("res://data/guests.json", [])
	content = _read_json("res://data/content.json", {})
	nights = _read_json("res://data/nights.json", [])
	rng.randomize()

static func _read_json(path: String, fallback: Variant) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback
	var value = JSON.parse_string(file.get_as_text())
	return value if value != null else fallback

func owned(id: String) -> bool:
	return id in state.get("owned", [])

func start_night(night: int, progress: Dictionary) -> void:
	var owned_items: Array = progress.get("owned", []).duplicate()
	var weather: String = WEATHER[rng.randi_range(0, WEATHER.size() - 1)]
	var deck: Array = []
	# The first night follows the handwritten chapter order; later nights reshuffle eligible guests.
	for chapter in range(8):
		var candidates: Array = []
		for guest in guests:
			if int(guest.chapter) == chapter + 1:
				candidates.append(guest.id)
		if night > 1:
			_shuffle(candidates)
			if night <= 5:
				candidates.sort_custom(func(a, b): return int(guest_by_id(str(a)).hiddenType in ["LIAR", "THIEF"]) < int(guest_by_id(str(b)).hiddenType in ["LIAR", "THIEF"]))
		else:
			candidates = candidates.slice(0, 7)
		deck.append(candidates.slice(0, 7))
	var wood = 87 + (8 if "wood1" in owned_items else 0) + (8 if "wood2" in owned_items else 0) + (10 if "wood3" in owned_items else 0)
	var trust = 76 + (5 if "trust1" in owned_items else 0) + (8 if "trust2" in owned_items else 0)
	if night >= 26:
		wood -= 15
	state = {
		"night":clampi(night,1,30), "chapter":0, "index":0, "phase":"chapter", "deck":deck,
		"rooms":100, "wood":minf(100, wood), "trust":minf(100, trust), "weather":weather,
		"magnifiers":3, "revealed":false, "questionCount":0, "answer":"", "people":[],
		"decisions":{}, "history":[], "reports":[], "wrongAccusations":0, "thiefEscaped":false,
		"caughtThief":false, "ended":false, "ending":"", "rule":rng.randi_range(0, content.rules.size()-1),
		"rule2":rng.randi_range(0, content.rules.size()-1) if night >= 16 else -1,
		"owned":owned_items, "discovered":progress.get("discovered", []).duplicate(), "foundThisNight":0,
		"secretStorm":false, "shieldUsed":false, "dogUsed":false, "lanternUsed":false,
		"undoUsed":false, "searchUsed":false, "lastSnapshot":{}, "lastGuest":"", "lastTwo":[],
		"secondUsed":false, "roomkeyUsed":false, "merchantResume":"",
		"accepted":0, "rejected":0, "correct":0, "events":0, "sickHelped":false,
		"eventText":"", "merchantMet":false, "radioFixed":false, "clockWait":0.0, "waitingTicks":0
	}
	_refill()

func _shuffle(values: Array) -> void:
	for i in range(values.size()-1, 0, -1):
		var j = rng.randi_range(0, i)
		var t = values[i]
		values[i] = values[j]
		values[j] = t

func _refill() -> void:
	state.magnifiers = 3 + (1 if owned("magnifier1") else 0) + (1 if owned("magnifier2") else 0) + (1 if owned("magnifier3") else 0) + (1 if state.weather == "moon" else 0)

func current_guest() -> Dictionary:
	if state.is_empty() or int(state.chapter) >= 8:
		return {}
	var chapter_deck: Array = state.deck[state.chapter]
	if int(state.index) >= chapter_deck.size():
		return {}
	return guest_by_id(str(chapter_deck[state.index]))

func next_guest() -> Dictionary:
	if state.is_empty() or int(state.chapter) >= 8:
		return {}
	var chapter_deck: Array = state.deck[state.chapter]
	if int(state.index) + 1 >= chapter_deck.size():
		return {}
	return guest_by_id(str(chapter_deck[state.index + 1]))

func guest_by_id(id: String) -> Dictionary:
	for guest in guests:
		if str(guest.id) == id:
			return guest
	return {}

func person_inside(id: String) -> bool:
	for person in state.people:
		if str(person.id) == id:
			return true
	return false

func has_role(role: String) -> bool:
	for person in state.people:
		if str(person.role) == role:
			return true
	return false

func connection_status(guest: Dictionary) -> String:
	for id in guest.get("connectionIds", []):
		if person_inside(str(id)):
			return str(guest_by_id(str(id)).get("name", ""))
	return ""

func begin_chapter() -> void:
	state.phase = "peephole"
	state.revealed = false
	state.questionCount = 0
	state.answer = ""
	state.clockWait = 0.0
	state.waitingTicks = 0

func open_card() -> void:
	if state.phase == "peephole":
		state.phase = "card"

func reveal() -> bool:
	if state.phase not in ["card", "peephole"] or state.revealed:
		return false
	var guest = current_guest()
	var price = 2 if state.weather == "fog" else 1
	if owned("lantern") and not state.lanternUsed and guest.hiddenType in ["LIAR", "THIEF"]:
		price = 0
		state.lanternUsed = true
	if state.magnifiers < price:
		return false
	state.magnifiers -= price
	state.revealed = true
	_discover(guest)
	return true

func ask_question(which: int, language: String) -> bool:
	var maximum = 2 if owned("question") else 1
	if state.phase != "peephole" or state.questionCount >= maximum or state.magnifiers < 1:
		return false
	var guest = current_guest()
	state.magnifiers -= 1
	state.questionCount += 1
	var story = str(guest.get("story_az", guest.story)) if language == "az" else str(guest.story)
	var clue = str(guest.get("clue_az", guest.clue)) if language == "az" else str(guest.clue)
	if which == 0:
		state.answer = story
	elif which == 1:
		state.answer = ("Məni tanıyan biri ola bilər." if language == "az" else "Beni tanıyan biri olabilir.") if not guest.connectionIds.is_empty() else ("Heç kim göndərməyib. Özüm gəldim." if language == "az" else "Kimse göndermedi. Kendim geldim.")
	else:
		state.answer = clue
		_discover(guest)
	return true

func _discover(guest: Dictionary) -> void:
	var role = str(guest.get("role", ""))
	if STORY_ROLES.has(role) and state.foundThisNight < 2:
		var piece = int(STORY_ROLES[role])
		if piece not in state.discovered:
			state.discovered.append(piece)
			state.foundThisNight += 1

func rule_broken(guest: Dictionary, admit: bool, questions: int) -> bool:
	if _breaks_rule(str(content.rules[state.rule].kind), guest, admit, questions): return true
	if int(state.rule2) >= 0:
		return _breaks_rule(str(content.rules[state.rule2].kind), guest, admit, questions)
	return false

func _breaks_rule(rule: String, guest: Dictionary, admit: bool, questions: int) -> bool:
	if rule == "question":
		return admit and questions == 0
	if admit:
		return false
	var role = str(guest.role)
	if rule == "child": return role == "child"
	if rule == "sick": return role == "sick" or guest.hiddenType == "SICK"
	if rule == "teacher": return role in ["teacher", "student", "teacher_old"]
	if rule == "doctor": return role in ["doctor", "nurse"]
	if rule == "guide": return role in ["guide", "shepherd"]
	if rule == "family": return role in ["family", "couple", "twins"]
	return false

func _lose_trust(amount: float) -> void:
	if owned("shield") and not state.shieldUsed and amount >= 6:
		amount *= 0.5
		state.shieldUsed = true
	state.trust = clampf(state.trust - amount, 0, 100)

func decide(admit: bool, language: String = "tr") -> void:
	if state.phase != "card" and state.phase != "peephole":
		return
	var guest = current_guest()
	if guest.is_empty():
		return
	# Keep a complete pre-decision snapshot so the one-use undo restores all consequences.
	var snapshot: Dictionary = state.duplicate(true)
	snapshot.lastSnapshot = {}
	state.lastSnapshot = snapshot
	state.lastGuest = guest.id
	state.lastTwo.append(guest.id)
	if state.lastTwo.size() > 2:
		state.lastTwo.pop_front()
	state.decisions[guest.id] = "in" if admit else "out"
	if rule_broken(guest, admit, state.questionCount):
		_lose_trust(3)
	var bad = guest.hiddenType in ["LIAR", "THIEF"]
	if admit:
		state.accepted += 1
		if owned("roomkey") and not state.roomkeyUsed:
			state.roomkeyUsed = true
		else:
			state.rooms = clampf(state.rooms - 4.5, 0, 100)
		if guest.hiddenType == "THIEF":
			_lose_trust(1.5)
		elif guest.hiddenType == "LIAR":
			_lose_trust(1.0)
		else:
			state.trust = clampf(state.trust + 1.0, 0, 100)
		var clue_text = str(guest.get("clue_az", guest.clue)) if language == "az" else str(guest.clue)
		var note = clue_text if state.revealed and owned("notebook") else ""
		state.people.append({"id":guest.id,"name":guest.name,"role":guest.role,"type":guest.hiddenType,"clueRevealed":state.revealed,"answer":state.answer,"note":note,"tag":"unknown"})
		if guest.role == "doctor": state.wood = minf(100, state.wood + 13)
		if guest.role == "radio": state.radioFixed = true
		if guest.id == "guest_11":
			if has_role("doctor"): state.trust = minf(100, state.trust + 3)
			else: state.wood = maxf(0, state.wood - 3)
		if guest.role == "merchant":
			state.merchantMet = true
		if not bad: state.correct += 1
	else:
		state.rejected += 1
		if bad:
			state.correct += 1
			state.trust = minf(100, state.trust + 0.5)
		else:
			_lose_trust(1.0)
		if guest.role == "child" or guest.role == "pregnant":
			_lose_trust(6)
	var burn = 0.55 + minf(float(state.people.size()), 16.0) * 0.035
	if state.weather == "blizzard": burn *= 1.35 if owned("blanket") else 1.8
	state.wood = clampf(state.wood - burn, 0, 100)
	state.history.append({"id":guest.id,"name":guest.name,"admitted":admit,"chapter":state.chapter})
	state.reports.append({"name":guest.name,"admitted":admit,"role":guest.role})
	state.index += 1
	state.revealed = false
	state.questionCount = 0
	state.answer = ""
	state.clockWait = 0.0
	state.waitingTicks = 0
	if _check_failure():
		return
	if state.index >= state.deck[state.chapter].size():
		state.phase = "event"
	else:
		state.phase = "peephole"
	if admit and guest.role == "merchant":
		state.merchantResume = state.phase
		state.phase = "merchant"

func merchant_choice(trade: bool) -> void:
	if state.phase != "merchant": return
	if trade:
		state.wood = minf(100, state.wood + 12)
		state.rooms = maxf(0, state.rooms - 4.5)
	if _check_failure(): return
	state.phase = state.merchantResume

func undo() -> bool:
	if not owned("undo") or state.undoUsed or state.lastSnapshot.is_empty() or state.phase == "ending":
		return false
	var previous: Dictionary = state.lastSnapshot.duplicate(true)
	previous.undoUsed = true
	previous.lastSnapshot = {}
	state = previous
	return true

func tick_wait(delta: float, disabled: bool) -> bool:
	if disabled or state.night <= 5 or state.phase not in ["peephole", "card"]:
		return false
	state.clockWait += delta
	var limit = 30.0 if owned("wait") else 15.0
	if state.clockWait <= limit:
		return false
	var ticks = int((state.clockWait - limit) / 8.0)
	if ticks > state.waitingTicks:
		state.waitingTicks = ticks
		_lose_trust(1)
		_check_failure()
		return true
	return false

func _check_failure() -> bool:
	if state.rooms <= 0:
		finish("full")
		return true
	if state.wood <= 0:
		finish("cold")
		return true
	if state.trust <= 0:
		finish("trust")
		return true
	return false

func event_choice(action: String, person_id: String = "") -> void:
	if state.phase != "event":
		return
	var chapter = int(state.chapter)
	state.events += 1
	if chapter == 0:
		state.wood = maxf(0, state.wood - 10)
		if action == "share":
			state.rooms = minf(100, state.rooms + 3)
			state.wood = minf(100, state.wood + 7)
			_lose_trust(2)
	elif chapter in [1, 2, 5]:
		var accused = guest_by_id(person_id)
		var any_thief = false
		for person in state.people:
			if person.type == "THIEF": any_thief = true
		var correct = (person_id == "none" and not any_thief) or (not accused.is_empty() and accused.hiddenType == "THIEF")
		if correct:
			state.trust = minf(100, state.trust + (7 if has_role("police") else 5))
			state.caughtThief = any_thief or state.caughtThief
		else:
			state.wrongAccusations += 1
			_lose_trust(10)
			if chapter == 2 and any_thief: state.thiefEscaped = true
	elif chapter == 3:
		if action == "wait": state.trust = minf(100, state.trust + 2)
		else: state.wood = minf(100, state.wood + 2)
	elif chapter == 4:
		if action == "chairs":
			state.wood = minf(100, state.wood + 17)
			_lose_trust(5)
		else:
			state.rooms = minf(100, state.rooms + 4)
			state.trust = minf(100, state.trust + 4)
	elif chapter == 6:
		if has_role("doctor"):
			state.sickHelped = true
			state.trust = minf(100, state.trust + 6)
		elif action == "help":
			state.sickHelped = true
			state.wood = maxf(0, state.wood - 8)
			state.rooms = maxf(0, state.rooms - 4)
		else:
			_lose_trust(6)
		var threshold = 65 if owned("storm") else 70
		state.secretStorm = state.trust > threshold and has_role("doctor") and has_role("shepherd") and has_role("murad")
	elif chapter == 7:
		_end_from_choice(action)
		return
	if _check_failure():
		return
	state.phase = "report"

func next_chapter() -> void:
	if state.phase != "report": return
	state.chapter += 1
	state.index = 0
	state.reports = []
	_refill()
	state.phase = "chapter"

func _end_from_choice(choice: String) -> void:
	if state.secretStorm:
		state.phase = "storm"
		return
	if choice == "saved" and state.discovered.size() >= 5:
		finish("saved")
	elif choice in ["sign", "secret", "page"]:
		finish(choice)
	else:
		finish(survival_ending())

func storm_choice(open_doors: bool) -> void:
	if state.phase != "storm": return
	finish("storm" if open_doors else "secret")

func survival_ending() -> String:
	if state.wrongAccusations == 0 and not state.thiefEscaped and state.rooms > 50 and state.wood > 50 and state.trust > 50 and state.discovered.size() >= 5:
		return "perfect"
	if state.accepted <= 1: return "empty"
	if state.thiefEscaped: return "spoon"
	if state.wrongAccusations >= 2: return "wrong"
	if has_role("doctor") and state.sickHelped: return "doctor"
	if has_role("child"): return "child"
	if state.merchantMet: return "merchant"
	if state.radioFixed: return "radio"
	if state.caughtThief: return "letter"
	if state.accepted >= 14 and state.trust >= 65: return "book"
	if owned("lantern") and state.lanternUsed: return "lamp"
	return "quiet"

func finish(id: String) -> void:
	if state.ended: return
	state.ended = true
	state.ending = id
	state.phase = "ending"

func ending_data(id: String) -> Dictionary:
	for item in content.endings:
		if item.id == id: return item
	return {}

func points() -> int:
	var ending = ending_data(str(state.ending))
	var rarity = str(ending.get("rarity", "failure"))
	var bonus = {"failure":1, "normal":4, "story":7, "rare":10}.get(rarity,1)
	var score = int(bonus) + int(state.correct / 8) + int((state.rooms + state.wood + state.trust) / 100)
	if state.ending == "perfect" and owned("morning"): score *= 2
	return maxi(1,score)
