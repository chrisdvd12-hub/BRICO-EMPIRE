extends SceneTree
func _initialize():
	var results: Array = []
	for seed_value in range(1,11):
		var s := BricoSimulation.new(seed_value)
		var policy := [["shelf_value","tools"],["unlock","paint"],["hire",""],["expand",""],["unlock","garden"],["checkout",""],["expand",""]]
		var next := 0
		var times: Array = []
		var wall_start := Time.get_ticks_msec()
		for step in range(30*60*35):
			s.tick(1.0/30)
			if next < policy.size() and s.progression.reason(policy[next][0],policy[next][1]).is_empty():
				s.progression.buy(policy[next][0],policy[next][1]); times.append(snappedf(s.elapsed/60,.01)); next += 1
			if next == policy.size(): break
		var result := {"seed":seed_value,"milestones_minutes":times,"sales":s.total_sales,"empty_departures":s.empty_departures,"stock_audit":s.stock_audit(),"cpu_ms":Time.get_ticks_msec()-wall_start}
		results.append(result)
		print(JSON.stringify(result))
	var f := FileAccess.open("res://docs/balance-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"policy":["outillage valeur niv2","peinture","employé 2","agrandissement 1","jardinage","caisse 2","agrandissement 2"],"results":results},"  ")); f.close()
	quit()
