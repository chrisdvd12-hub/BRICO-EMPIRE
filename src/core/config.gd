class_name BricoConfig
extends RefCounted
var values: Dictionary
var families: Array
func _init():
	values = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance.json"))
	families = values.families
func v(key: String):
	return values[key]
func family(id: String) -> Dictionary:
	for f in families:
		if f.id == id: return f
	return {}
func upgrade_cost(level: int) -> int:
	return int(round(v("upgrade_base") * pow(v("upgrade_growth"), level - 1)))
