class_name BricoSimulation
extends RefCounted
signal changed
signal purchased(action: String, target: String)
signal sale(amount: int, position: Vector2)
var cfg := BricoConfig.new()
var inventory: BricoInventory
var nav := BricoNavigation.new()
var progression: BricoProgression
var rng := RandomNumberGenerator.new()
var money := 200
var opened := {"tools":true,"paint":false,"garden":false}
var levels: Dictionary = {}
var worker_levels := {"speed":1,"carry":1,"restock":1}
var cash_levels := [1,1]
var expansion := 0
var checkouts := 1
var workers: Array = []
var customers: Array = []
var queues := [[],[]]
var slots := {"tools":[-1,-1],"paint":[-1,-1],"garden":[-1,-1]}
var tasks: Dictionary = {}
var last_restock := {"tools":0.0,"paint":0.0,"garden":0.0}
var elapsed := 0.0
var arrival_timer := 5.0
var delivery_timer := 20.0
var tutorial := 0
var restock_count := 0
var empty_departures := 0
var next_id := 0
var sales: Array = []
var total_sales := 0
var total_revenue := 0
var settings := {"sound":true,"reduced_effects":false}
var observed := {"empty":0.0,"queue":0.0,"goods":0.0}
var advice := "Les clients font leurs achats seuls. Observez le magasin."
var advice_timer := 20.0
func _init(seed_value: int = 0):
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	money = cfg.v("initial_money")
	inventory = BricoInventory.new(cfg)
	for f in cfg.families: levels[f.id] = {"capacity":1,"value":1,"service":1}
	inventory.shelves.tools = cfg.v("shelf_capacity")
	inventory.reserve.tools = cfg.v("reserve_capacity")
	inventory.delivered = inventory.total()
	workers.append(BricoWorker.new(0))
	delivery_timer = cfg.v("delivery_interval")
	progression = BricoProgression.new(self)
	nav.rebuild(expansion,opened,cfg)
func capacity(id: String) -> int:
	return cfg.v("shelf_capacity") + (levels[id].capacity-1) * cfg.v("capacity_step") + (cfg.v("expansion_shelf_bonus") if expansion == 2 else 0)
func reserve_capacity() -> int:
	return cfg.v("reserve_capacity") + (cfg.v("expansion_reserve_bonus") if expansion == 2 else 0)
func sale_value(id: String) -> int:
	return int(round(cfg.family(id).price * (1.0 + (levels[id].value-1) * cfg.v("value_step"))))
func pick_time(id: String) -> float:
	return cfg.v("pick_seconds") * pow(cfg.v("speed_factor"),levels[id].service-1)
func worker_speed() -> float:
	return cfg.v("worker_speed") * (1 + (worker_levels.speed-1) * cfg.v("worker_speed_step"))
func carry_capacity() -> int:
	return cfg.v("carry_base") + (worker_levels.carry-1) * cfg.v("carry_step")
func restock_time() -> float:
	return cfg.v("restock_seconds") * pow(cfg.v("speed_factor"),worker_levels.restock-1)
func checkout_time(index: int) -> float:
	return cfg.v("checkout_seconds") * pow(cfg.v("speed_factor"),cash_levels[index]-1)
func choose_checkout() -> int:
	return 1 if checkouts == 2 and queues[1].size() < queues[0].size() else 0
func shortest_queue() -> int:
	return queues[choose_checkout()].size()
func spawn_customer():
	if customers.size() >= cfg.v("max_clients"): return
	customers.append(BricoCustomer.new(next_id,nav.entrance))
	next_id += 1
func record_sale(customer: BricoCustomer):
	money += customer.unit_value
	inventory.sold += 1
	total_sales += 1
	total_revenue += customer.unit_value
	sales.append([elapsed, customer.unit_value])
	if tutorial == 0: tutorial = 1
	sale.emit(customer.unit_value,customer.pos)
func tick(dt: float):
	elapsed += dt
	arrival_timer -= dt
	delivery_timer -= dt
	if arrival_timer <= 0:
		spawn_customer()
		arrival_timer += rng.randf_range(cfg.v("arrival_min"),cfg.v("arrival_max"))
	if delivery_timer <= 0:
		inventory.deliver(opened,reserve_capacity())
		delivery_timer += cfg.v("delivery_interval")
	for worker in workers: worker.tick(self,dt)
	for c in customers: c.tick(self,dt)
	customers = customers.filter(func(c): return c.state != BricoCustomer.State.DONE)
	while not sales.is_empty() and sales[0][0] < elapsed - 120: sales.pop_front()
	var empty := false
	for id in opened:
		if opened[id] and inventory.shelves[id] == 0: empty = true
	if empty: observed.empty += dt
	if shortest_queue() >= 3: observed.queue += dt
	for w in workers:
		if w.waiting_goods:
			observed.goods += dt
			break
	advice_timer -= dt
	if advice_timer <= 0:
		advice_timer = 20
		if observed.queue > 8: advice = "La file s’allonge : accélérez la caisse ou ouvrez la seconde."
		elif observed.empty > 5: advice = "Un rayon reste vide : augmentez le transport ou recrutez."
		elif observed.goods > 5: advice = "L’équipe attend la livraison : le dépôt agrandi offre plus de marge."
		else: advice = "L’activité est fluide. Épargnez pour votre prochain objectif."
		observed = {"empty":0.0,"queue":0.0,"goods":0.0}
func recent_stats() -> Dictionary:
	var duration := minf(120,elapsed)
	var revenue := 0
	for s in sales: revenue += int(s[1])
	return {"duration":duration,"revenue":revenue,"count":sales.size()}
func measured_rpm() -> float:
	if elapsed < 30 or sales.size() < 2: return -1
	return recent_stats().revenue * 60.0 / minf(120,elapsed)
func stock_audit() -> int:
	var n := inventory.total() + inventory.sold
	for w in workers: n += w.cargo
	for c in customers:
		if c.carrying: n += 1
	return n - inventory.delivered
func snapshot(now: int) -> Dictionary:
	var reserves := inventory.reserve.duplicate(true)
	# Rebuild agents on load: return all unsettled goods to their original family.
	for w in workers:
		if w.cargo > 0: reserves[w.family] += w.cargo
	for c in customers:
		if c.carrying: reserves[c.family] += 1
	return {"version":2,"store_id":cfg.v("store_id"),"money":money,"opened":opened.duplicate(true),"levels":levels.duplicate(true),"worker_levels":worker_levels.duplicate(true),"cash_levels":cash_levels.duplicate(),"worker_count":workers.size(),"expansion":expansion,"checkouts":checkouts,"shelves":inventory.shelves.duplicate(true),"reserve":reserves,"tutorial":tutorial,"settings":settings.duplicate(true),"elapsed":elapsed,"sales":sales.duplicate(true),"total_sales":total_sales,"total_revenue":total_revenue,"last_saved":now,"delivery_timer":delivery_timer,"observed_rate":recent_stats()}
func restore(data: Dictionary):
	money = maxi(0,int(data.get("money",cfg.v("initial_money"))))
	expansion = clampi(int(data.get("expansion",0)),0,2)
	checkouts = clampi(int(data.get("checkouts",1)),1,2)
	for f in cfg.families:
		var id: String = f.id
		opened[id] = bool(data.get("opened",{}).get(id,id == "tools")) and expansion >= f.expansion
		for key in levels[id]: levels[id][key] = clampi(int(data.get("levels",{}).get(id,{}).get(key,1)),1,5)
		inventory.shelves[id] = clampi(int(data.get("shelves",{}).get(id,cfg.v("shelf_capacity") if id == "tools" else 0)),0,capacity(id))
		inventory.reserve[id] = clampi(int(data.get("reserve",{}).get(id,cfg.v("reserve_capacity") if id == "tools" else 0)),0,1000)
	for key in worker_levels: worker_levels[key] = clampi(int(data.get("worker_levels",{}).get(key,1)),1,5)
	var cash: Array = data.get("cash_levels",[1,1])
	for i in range(2): cash_levels[i] = clampi(int(cash[i]) if i < cash.size() else 1,1,5)
	workers.clear()
	for i in range(clampi(int(data.get("worker_count",1)),1,cfg.v("max_workers"))): workers.append(BricoWorker.new(i))
	tutorial = clampi(int(data.get("tutorial",0)),0,5)
	for key in settings: settings[key] = bool(data.get("settings",{}).get(key,settings[key]))
	elapsed = maxf(0,float(data.get("elapsed",0)))
	sales = []
	for s in data.get("sales",[]):
		if s is Array and s.size() == 2 and s[0] is float and s[1] >= 0: sales.append(s)
	total_sales = maxi(0,int(data.get("total_sales",0)))
	total_revenue = maxi(0,int(data.get("total_revenue",0)))
	delivery_timer = clampf(float(data.get("delivery_timer",20)),0.1,cfg.v("delivery_interval"))
	inventory.delivered = inventory.total()
	inventory.sold = 0
	nav.rebuild(expansion,opened,cfg)
