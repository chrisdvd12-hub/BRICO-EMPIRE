class_name BricoSaveStore
extends RefCounted
const VERSION := 2
var path: String
var warning := ""
func _init(save_path: String = "user://brico_save.json"):
	path = save_path
func valid(data) -> bool:
	if not data is Dictionary: return false
	if int(data.get("version",0)) not in [1,2]: return false
	if not data.get("money",null) is float and not data.get("money",null) is int: return false
	for key in ["opened","levels","worker_levels","shelves","reserve","settings","observed_rate"]:
		if data.has(key) and not data[key] is Dictionary: return false
	for key in ["cash_levels","sales"]:
		if data.has(key) and not data[key] is Array: return false
	for key in data.get("levels",{}):
		if not data.levels[key] is Dictionary: return false
	return true
func read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK: return {}
	var parsed = parser.data
	if not valid(parsed): return {}
	# v1 had no observed settlement history: migration grants no offline estimate.
	if int(parsed.version) == 1:
		parsed.version = VERSION
		parsed.observed_rate = {}
	return parsed
func load_data() -> Dictionary:
	var result := read_file(path)
	if not result.is_empty(): return result
	if FileAccess.file_exists(path):
		warning = "Sauvegarde principale illisible : récupération de la copie de secours."
		result = read_file(path + ".bak")
		if result.is_empty(): warning = "Sauvegardes illisibles : nouvelle partie démarrée."
	return result
func write(data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp,FileAccess.WRITE)
	if f == null:
		warning = "Impossible d’écrire la sauvegarde."
		return false
	f.store_string(JSON.stringify(data))
	f.flush()
	f.close()
	if read_file(tmp).is_empty(): return false
	if not read_file(path).is_empty():
		if DirAccess.copy_absolute(path,path+".bak") != OK: return false
	# Rename inside the same directory/filesystem is atomic.
	var err := DirAccess.rename_absolute(tmp,path)
	if err != OK: warning = "Sauvegarde impossible (code %d)." % err
	return err == OK
func offline_amount(data: Dictionary, now: int, cfg: BricoConfig) -> Dictionary:
	var gap := now - int(data.get("last_saved",now))
	var stats: Dictionary = data.get("observed_rate",{})
	var duration := float(stats.get("duration",0))
	var result := {"seconds":0,"amount":0,"rate":0.0}
	if gap < cfg.v("offline_min_absence") or gap > 366 * 86400: return result
	if duration < cfg.v("offline_min_observation") or int(stats.get("count",0)) < cfg.v("offline_min_sales"): return result
	result.seconds = mini(gap,cfg.v("offline_cap"))
	result.rate = maxf(0,float(stats.get("revenue",0))) / duration * cfg.v("offline_factor")
	result.amount = int(floor(result.rate * result.seconds))
	return result
func reset():
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
