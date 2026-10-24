extends SceneTree
var failures := 0
func expect(ok: bool, text: String):
	if not ok: failures += 1; printerr("PROFILE FAIL: "+text)
func _initialize():
	var base := "user://profile_tests"
	DirAccess.make_dir_recursive_absolute(base)
	var dir := DirAccess.open(base)
	for file in dir.get_files(): dir.remove(file)
	var legacy := BricoSaveStore.new(base+"/old.json")
	var original := BricoSimulation.new(44); original.money = 987; original.tutorial = 5
	expect(legacy.write(original.snapshot(1000)),"seed legacy")
	var profiles := BricoProfiles.new(base,base+"/old.json")
	expect(profiles.entries.size() == 1 and profiles.active_id == "p_legacy","legacy adopted once")
	expect(profiles.store_for("p_legacy").load_data().money == 987,"legacy balance preserved")
	expect(FileAccess.file_exists(legacy.path),"legacy original retained")
	var alice := profiles.create_player("Alice",1)
	var bob := profiles.create_player("Bob",2)
	expect(not alice.is_empty() and bob != alice,"unique player ids")
	original.money = 111; profiles.store_for(alice).write(original.snapshot(2000))
	original.money = 222; profiles.store_for(bob).write(original.snapshot(2000))
	expect(profiles.store_for(alice).load_data().money == 111 and profiles.store_for(bob).load_data().money == 222,"balances isolated")
	profiles.store_for(alice).reset()
	expect(profiles.store_for(bob).load_data().money == 222,"reset affects one player")
	expect(not profiles.valid_id("../outside") and not profiles.select_player("p_unknown"),"invalid paths and missing players rejected")
	var reload := BricoProfiles.new(base,base+"/old.json")
	expect(reload.entries.size() == 3,"profile index survives reload without legacy duplication")
	var corrupt := FileAccess.open(base+"/index.json",FileAccess.WRITE); corrupt.store_string("{broken"); corrupt.close()
	reload = BricoProfiles.new(base,base+"/old.json")
	expect(reload.entries.size() >= 2 and reload.store_for(bob).load_data().money == 222,"backup index recovers players")
	for _i in range(10): reload.create_player("Test",0)
	expect(reload.entries.size() == 6,"six player limit")
	# No implicit online claims or credentials: only local files are used.
	for file in dir.get_files(): dir.remove(file)
	print("PROFILE RESULT: ",failures," failures"); quit(1 if failures else 0)
