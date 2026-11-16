extends SceneTree
# Deterministic, progressed art-review fixture. Never loaded by the normal game.
func _initialize():
	var sim := BricoSimulation.new(20261026)
	sim.money = 100000
	for purchase in [["unlock","paint"],["expand",""],["unlock","garden"],["checkout",""],["hire",""]]: assert(sim.progression.buy(purchase[0],purchase[1]))
	for i in range(30*150): sim.tick(1.0/30)
	assert(sim.stock_audit() == 0)
	sim.tutorial = 5; sim.money = 1250; sim.tips_seen = ["world","rating","franchise","events","achievements"]
	var file := FileAccess.open("res://tests/fixtures/brico_fun_visual.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(sim.snapshot(int(Time.get_unix_time_from_system())))); file.close()
	print("VISUAL FIXTURE: three departments, two workers, two checkouts; stock audit=0"); quit()
