extends Node

signal locale_changed(locale: String)
const CATALOG_PATHS := {"tr":"res://localization/tr.json", "az":"res://localization/az.json"}
var _catalogs: Dictionary = {}
var _locale := "tr"

func _ready() -> void:
	for locale in CATALOG_PATHS:
		var file = FileAccess.open(CATALOG_PATHS[locale], FileAccess.READ)
		if file:
			var value = JSON.parse_string(file.get_as_text())
			_catalogs[locale] = value if value is Dictionary else {}
	var saved = SaveStore.get_locale()
	_locale = saved if saved in ["tr", "az"] else "tr"

static func detect_locale(_os_locale: String) -> String:
	return "tr"

static func resolve_locale(saved: String, _os_locale: String) -> String:
	return saved if saved in ["tr", "az"] else "tr"

func text(key: String, replacements: Dictionary = {}) -> String:
	var catalog: Dictionary = _catalogs.get(_locale, {})
	var fallback: Dictionary = _catalogs.get("tr", {})
	var result = str(catalog.get(key, fallback.get(key, key)))
	for token in replacements:
		result = result.replace("{%s}" % str(token), str(replacements[token]))
	return result

func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)

func get_locale() -> String:
	return _locale

func set_locale(locale: String) -> void:
	if not _catalogs.has(locale): return
	SaveStore.set_locale(locale)
	if locale != _locale:
		_locale = locale
		locale_changed.emit(locale)

func toggle_locale() -> void:
	set_locale("az" if _locale == "tr" else "tr")

func catalog_keys(locale: String) -> Array:
	return (_catalogs.get(locale, {}) as Dictionary).keys()
