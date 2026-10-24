class_name BricoProfiles
extends RefCounted
const LIMIT := 6
var directory: String
var index_path: String
var legacy_path: String
var entries: Array = []
var active_id := ""
var warning := ""
func _init(base := "user://players", legacy := "user://brico_save.json"):
	directory = base; index_path = base+"/index.json"; legacy_path = legacy
	DirAccess.make_dir_recursive_absolute(directory)
	load_index()
func valid_id(id: String) -> bool:
	return id.begins_with("p_") and id.is_valid_identifier() and id.length() <= 48
func store_for(id: String) -> BricoSaveStore:
	assert(valid_id(id))
	return BricoSaveStore.new(directory+"/"+id+".json")
func read_index(path: String) -> Dictionary:
	if OS.has_feature("web"):
		var local := BricoBrowserStore.read("brico.index.v1:"+path)
		if local.get("version",0) == 1 and local.get("profiles") is Array: return local
	if not FileAccess.file_exists(path): return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return {}
	var data = parser.data
	if not data is Dictionary or data.get("version",0) != 1 or not data.get("profiles") is Array: return {}
	return data
func load_index():
	var data := read_index(index_path)
	if data.is_empty(): data = read_index(index_path+".bak")
	entries.clear()
	for p in data.get("profiles",[]):
		if p is Dictionary and p.get("id") is String and valid_id(p.id) and p.get("name") is String:
			if not entries.any(func(e): return e.id == p.id): entries.append({"id":p.id,"name":p.name.left(20),"avatar":clampi(int(p.get("avatar",0)),0,5)})
	active_id = str(data.get("active_id",""))
	# Recover actual save files if the index is missing/corrupt, rather than hiding players.
	var dir := DirAccess.open(directory)
	if dir != null:
		for file in dir.get_files():
			var id := file.trim_suffix(".json")
			if file.ends_with(".json") and valid_id(id) and not entries.any(func(e): return e.id == id):
				if not store_for(id).load_data().is_empty(): entries.append({"id":id,"name":"Profil récupéré","avatar":entries.size()%6}); warning = "Des profils ont été récupérés depuis leurs sauvegardes."
	if OS.has_feature("web"):
		var prefix := "brico.save.v2:"+directory+"/"
		for key in BricoBrowserStore.keys(prefix):
			if not key.ends_with(".json"): continue
			var id: String = key.trim_prefix(prefix).trim_suffix(".json")
			if valid_id(id) and not entries.any(func(e): return e.id == id):
				if not store_for(id).load_data().is_empty(): entries.append({"id":id,"name":"Profil récupéré","avatar":entries.size()%6})
	if entries.is_empty():
		var old := BricoSaveStore.new(legacy_path).load_data()
		if not old.is_empty():
			# Copy only. Keep the original and its backup so migration never deletes progress.
			if store_for("p_legacy").write(old):
				entries.append({"id":"p_legacy","name":"Joueur 1","avatar":0}); active_id = "p_legacy"
			else: warning = "L’ancienne partie est conservée ; son transfert a échoué."
	if not entries.is_empty(): save_index()
func save_index() -> bool:
	if OS.has_feature("web"):
		return BricoBrowserStore.write("brico.index.v1:"+index_path,{"version":1,"active_id":active_id,"profiles":entries})
	var f := FileAccess.open(index_path+".tmp",FileAccess.WRITE)
	if f == null: warning = "Impossible d’enregistrer les profils."; return false
	f.store_string(JSON.stringify({"version":1,"active_id":active_id,"profiles":entries})); f.flush(); f.close()
	if read_index(index_path+".tmp").is_empty(): return false
	if not read_index(index_path).is_empty():
		if DirAccess.copy_absolute(index_path,index_path+".bak") != OK: return false
	var ok := DirAccess.rename_absolute(index_path+".tmp",index_path) == OK
	return ok
func create_player(player_name: String, avatar := 0) -> String:
	var clean := player_name.strip_edges().left(20)
	if clean.is_empty() or entries.size() >= LIMIT: return ""
	var id := "p_"+Crypto.new().generate_random_bytes(8).hex_encode()
	var old_active := active_id
	entries.append({"id":id,"name":clean,"avatar":avatar%6}); active_id = id
	if not save_index(): entries.pop_back(); active_id = old_active; return ""
	return id
func select_player(id: String) -> bool:
	if not entries.any(func(p): return p.id == id): return false
	var previous := active_id; active_id = id
	if not save_index(): active_id = previous; return false
	return true
func player_name() -> String:
	for p in entries:
		if p.id == active_id: return p.name
	return "Joueur"
