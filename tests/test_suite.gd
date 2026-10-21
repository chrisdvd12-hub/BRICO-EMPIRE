extends SceneTree
var failures := 0
var checks := 0
const DT := 1.0/30
func expect(condition: bool, message: String):
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)
func run_for(sim: BricoSimulation, seconds: float, audit := true):
	for tick in range(int(seconds*30)):
		sim.tick(DT)
		if audit and sim.stock_audit() != 0:
			expect(false,"stock conservation at %.2f" % sim.elapsed)
			return
func _initialize():
	call_deferred("run_all")
func run_all():
	test_loop()
	test_workers()
	test_queue()
	test_progression()
	test_save()
	test_tutorial()
	test_navigation()
	print("RESULT: %d assertions, %d failures" % [checks,failures])
	quit(1 if failures else 0)
func test_loop():
	var s := BricoSimulation.new(17)
	var initial := s.money
	run_for(s,180)
	expect(s.total_sales > 15,"end-to-end customers pay")
	expect(s.money == initial+s.total_revenue,"only settlements create revenue")
	expect(s.restock_count > 0,"workers actually restock")
	expect(s.inventory.delivered > 32,"delivery adds goods")
	expect(s.stock_audit() == 0,"conservation includes reserve shelf cargo baskets and sold goods")
	var empty := BricoSimulation.new(7)
	empty.inventory.shelves.tools = 0
	empty.inventory.reserve.tools = 0
	empty.inventory.delivered = 0
	empty.delivery_timer = 45
	run_for(empty,30)
	expect(empty.money == 200,"empty store generates no money")
	expect(empty.empty_departures > 0,"empty shelf patience expires")
	run_for(empty,120)
	expect(empty.total_sales > 0,"empty store recovers via automatic delivery")
func test_workers():
	var s := BricoSimulation.new(10)
	s.workers.append(BricoWorker.new(1))
	s.inventory.shelves.tools = 0
	s.inventory.delivered = s.inventory.total()
	s.tick(DT)
	var assigned := 0
	for w in s.workers:
		if w.family == "tools": assigned += 1
	expect(assigned == 1,"two workers cannot reserve same shelf")
	s.expansion = 1; s.opened.paint = true; s.opened.garden = true
	s.nav.rebuild(s.expansion,s.opened,s.cfg)
	s.inventory.reserve.paint = 24; s.inventory.reserve.garden = 24
	s.inventory.delivered = s.inventory.total()
	run_for(s,300)
	expect(s.last_restock.tools > 0 and s.last_restock.paint > 0 and s.last_restock.garden > 0,"no family starved by worker scheduler")
	expect(s.stock_audit() == 0,"concurrent workers preserve inventory")
func test_queue():
	var s := BricoSimulation.new(5)
	s.cfg.values.arrival_min = 1.0; s.cfg.values.arrival_max = 1.0
	s.cfg.values.checkout_seconds = 8.0
	s.cfg.values.empty_patience = 45.0
	var maximum := 0
	var previous_paid := -1
	var paid_ids: Array = []
	s.sale.connect(func(_amount,_position):
		for c in s.customers:
			if c.state == BricoCustomer.State.PAYING:
				expect(s.queues[0][0] == c.id,"FIFO service only first customer pays")
				expect(not paid_ids.has(c.id),"a customer pays once")
				paid_ids.append(c.id))
	for i in range(6000):
		s.tick(DT)
		maximum = maxi(maximum,s.queues[0].size())
		expect(s.customers.size() <= s.cfg.v("max_clients"),"population cap")
		if s.stock_audit() != 0: expect(false,"queue stock audit"); break
	expect(maximum >= 3,"multi-customer ordered queue exercised")
	expect(paid_ids.size() >= 10,"congested queue continues settling")
func test_progression():
	var s := BricoSimulation.new(9)
	s.money = 0
	expect(not s.progression.buy("unlock","paint"),"unaffordable purchase rejected")
	expect(s.money == 0 and not s.opened.paint,"rejected purchase has no side effects")
	s.money = 100
	var bought := 0
	for i in range(20):
		if s.progression.buy("shelf_value","tools"): bought += 1
	expect(bought == 1 and s.money == 0 and s.levels.tools.value == 2,"rapid presses cannot spend same funds twice")
	s.money = 100000
	expect(not s.progression.buy("unlock","garden"),"garden requires first expansion")
	expect(not s.progression.buy("expand"),"expansion requires paint")
	expect(s.progression.buy("unlock","paint"),"paint unlock")
	expect(s.progression.buy("hire"),"second employee")
	expect(s.progression.buy("expand") and s.expansion == 1,"first expansion")
	expect(s.progression.buy("unlock","garden"),"garden unlock")
	expect(s.progression.buy("checkout") and s.checkouts == 2,"second register with cashier")
	var before := s.capacity("tools")
	expect(s.progression.buy("expand") and s.expansion == 2,"second expansion")
	expect(s.reserve_capacity() == 48 and s.capacity("tools") == before+4,"second expansion actual capacity bonus")
	for action in ["shelf_capacity","shelf_value","shelf_service"]:
		for i in range(10): s.progression.buy(action,"tools")
		expect(s.levels.tools[action.trim_prefix("shelf_")] == 5,"shelf level capped")
	for action in ["worker_speed","worker_carry","worker_restock"]:
		for i in range(10): s.progression.buy(action)
		expect(s.worker_levels[action.trim_prefix("worker_")] == 5,"worker level capped")
	run_for(s,600)
	expect(s.total_sales > 50 and s.stock_audit() == 0,"fully expanded store runs reliably")
func test_save():
	var store := BricoSaveStore.new("user://test_save.json")
	store.reset()
	expect(store.load_data().is_empty(),"missing file starts new game")
	var s := BricoSimulation.new(3)
	run_for(s,155)
	# Ensure unsettled baskets/cargo are included in the recovery rule.
	var before := s.inventory.total()
	for w in s.workers: before += w.cargo
	for c in s.customers:
		if c.carrying: before += 1
	var snapshot := s.snapshot(10000)
	expect(store.write(snapshot),"atomic snapshot write")
	var restored := BricoSimulation.new(2); restored.restore(store.load_data())
	expect(restored.money == s.money,"money restored")
	expect(restored.inventory.total() == before,"unsettled goods recovered without duplication or loss")
	expect(restored.tutorial == s.tutorial,"tutorial restored")
	var reward := store.offline_amount(snapshot,20000,s.cfg)
	expect(reward.seconds == 7200 and reward.amount > 0,"offline estimate capped at two hours")
	expect(store.offline_amount(snapshot,10010,s.cfg).amount == 0,"short absence no offline grant")
	expect(store.offline_amount(snapshot,9000,s.cfg).amount == 0,"negative clock change rejected")
	expect(store.offline_amount(snapshot,10000+400*86400,s.cfg).amount == 0,"aberrant absence rejected")
	var fresh := BricoSimulation.new(4)
	expect(store.offline_amount(fresh.snapshot(10000),20000,fresh.cfg).amount == 0,"insufficient observations grant nothing")
	restored.money += reward.amount
	expect(store.write(restored.snapshot(20000)),"offline grant committed")
	expect(store.offline_amount(store.load_data(),20000,s.cfg).amount == 0,"offline reload cannot double grant")
	# Backup after at least two writes, then corrupt main.
	var f := FileAccess.open(store.path,FileAccess.WRITE); f.store_string("{corrupt"); f.close()
	expect(not store.load_data().is_empty(),"corrupt main recovers backup")
	f = FileAccess.open(store.path+".bak",FileAccess.WRITE); f.store_string("null"); f.close()
	expect(store.load_data().is_empty(),"both corrupt handled as fresh start")
	expect(not store.valid({"version":2,"money":200,"levels":{"tools":4}}),"malformed nested schema rejected")
	var old := snapshot.duplicate(true); old.version = 1
	f = FileAccess.open(store.path,FileAccess.WRITE); f.store_string(JSON.stringify(old)); f.close()
	var migrated := store.load_data()
	expect(migrated.version == 2 and migrated.observed_rate.is_empty(),"v1 migration disables unsupported offline history")
	store.reset()
func test_tutorial():
	var s := BricoSimulation.new(22)
	run_for(s,60)
	expect(s.tutorial == 1,"first paid sale advances tutorial")
	s.tutorial = 2
	s.progression.buy("shelf_value","tools")
	expect(s.tutorial == 3,"first improvement advances tutorial")
	run_for(s,90)
	expect(s.tutorial == 4,"real restock advances tutorial")
	s.tutorial = 5
	var r := BricoSimulation.new(1); r.restore(s.snapshot(1000))
	expect(r.tutorial == 5,"skipped or completed tutorial stays complete")
	s.tutorial = 2; r.restore(s.snapshot(1000))
	expect(r.tutorial == 2,"unfinished tutorial resumes")
func test_navigation():
	var s := BricoSimulation.new(4)
	for expansion in range(3):
		s.expansion = expansion
		s.nav.rebuild(expansion,s.opened,s.cfg)
		for f in s.cfg.families:
			if f.expansion > expansion: continue
			for point in f.customer:
				expect(not s.nav.path(s.nav.entrance,Vector2(point[0],point[1])).is_empty(),"customer path: %s expansion %d" % [f.id,expansion])
			var point: Array = f.worker
			expect(not s.nav.path(s.nav.stock_point,Vector2(point[0],point[1])).is_empty(),"worker path: %s" % f.id)
	var c := BricoCustomer.new(3,s.nav.entrance)
	c.pos = Vector2(170,410) # deliberately invalid starting cell
	c.leave(s)
	expect(c.state == BricoCustomer.State.DONE,"invalid route controlled recovery")
