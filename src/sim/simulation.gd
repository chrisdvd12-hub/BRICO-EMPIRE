class_name BricoSimulation
extends RefCounted
signal changed
signal purchased(action: String, target: String)
signal sale(amount: int, position: Vector2)
signal event_started(event: Dictionary)
signal event_ended(event: Dictionary)
signal achieved(achievement: Dictionary)
signal daily_completed(daily: Dictionary)
signal new_day(day: int)
signal franchised(level: int)
var cfg := BricoConfig.new()
var inventory: BricoInventory
var nav := BricoNavigation.new()
var progression: BricoProgression
var rng := RandomNumberGenerator.new()
var money := 200
var opened: Dictionary = {}
var levels: Dictionary = {}
var worker_levels := {"speed":1,"carry":1,"restock":1}
var cash_levels := [1,1]
var expansion := 0
var checkouts := 1
var workers: Array = []
var customers: Array = []
var queues := [[],[]]
var slots: Dictionary = {}
var tasks: Dictionary = {}
var last_restock: Dictionary = {}
var elapsed := 0.0
var arrival_timer := 5.0
var delivery_timer := 20.0
var tutorial := 0
var restock_count := 0
var empty_departures := 0
var next_id := 0
var sales: Array = []
# Recent income must describe the current workshop, not the previous franchise.
var revenue_started_at := 0.0
var total_sales := 0
var total_revenue := 0
var settings := {"sound":true,"music":true,"reduced_effects":false,"graphics_low":false,"volume":0.8}
var observed := {"empty":0.0,"queue":0.0,"goods":0.0}
var advice := "Les clients font leurs achats seuls. Observez le magasin."
var advice_timer := 20.0
# Temporary store events; transient, never saved, so a reload cannot extend a bonus.
var event: Dictionary = {}
var event_left := 0.0
var event_timer := 0.0
var events_seen := 0
var achievements: Array = []
var achievement_rewards := 0
var achievement_timer := 1.0
# Customer satisfaction (0-1 per visit) over a sliding window gives the 1-5 store rating.
var outcomes: Array = []
var happy_served := 0
var vip_served := 0
var family_sales: Dictionary = {}
# Revenue per in-game minute for the stats chart, plus per-day records.
var minute_revenue: Array = []
var minute_acc := 0
var minute_timer := 0.0
var day_revenue := 0
var best_day := 0
var last_day := 1
var daily: Dictionary = {}
var dailies_done := 0
var decor: Array = []
var franchise_level := 0
var tips_seen: Array = []
func _init(seed_value: int = 0):
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	money = cfg.v("initial_money")
	for f in cfg.families:
		opened[f.id] = f.id == "tools"
		slots[f.id] = [-1,-1]
		last_restock[f.id] = 0.0
		family_sales[f.id] = 0
	event_timer = cfg.v("event_first")
	inventory = BricoInventory.new(cfg)
	for f in cfg.families: levels[f.id] = {"capacity":1,"value":1,"service":1}
	inventory.shelves.tools = cfg.v("shelf_capacity")
	inventory.reserve.tools = cfg.v("reserve_capacity")
	inventory.delivered = inventory.total()
	workers.append(BricoWorker.new(0))
	delivery_timer = cfg.v("delivery_interval")
	progression = BricoProgression.new(self)
	nav.rebuild(expansion,opened,cfg)
	new_daily()
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
	var c := BricoCustomer.new(next_id,nav.entrance)
	c.hurried = bool(event.get("hurried",false))
	var roll := rng.randf()
	if roll < cfg.v("vip_chance"): c.profile = "vip"
	elif roll < cfg.v("vip_chance") + cfg.v("artisan_chance"): c.profile = "artisan"
	customers.append(c)
	next_id += 1
func value_multiplier() -> float:
	return float(event.get("value",1.0))
func arrival_multiplier() -> float:
	# A well-rated store draws customers faster; a poor rating slows arrivals.
	var k := (rating() - 1.0) / 4.0
	return float(event.get("arrival",1.0)) * lerpf(cfg.v("rating_arrival_slow"),cfg.v("rating_arrival_fast"),k)
func franchise_multiplier() -> float:
	return 1.0 + franchise_level * cfg.v("franchise_step")
func satisfaction_rating() -> float:
	# Few visits weigh little: blend with the starting rating as if 8 average visits came first.
	var prior := (float(cfg.v("rating_start")) - 1.0) / 4.0
	var total := prior * 8.0
	for o in outcomes: total += float(o)
	return 1.0 + 4.0 * total / (outcomes.size() + 8.0)
func decor_bonus() -> float:
	var bonus := 0.0
	for item in cfg.v("decor"):
		if decor.has(item.id): bonus += float(item.rating)
	return bonus
func rating() -> float:
	return clampf(satisfaction_rating() + decor_bonus(),1.0,5.0)
func record_outcome(c: BricoCustomer, score: float):
	outcomes.append(score)
	while outcomes.size() > cfg.v("rating_window"): outcomes.pop_front()
	c.bubble = "happy" if score >= 0.7 else ("meh" if score > 0.0 else "sad")
	c.bubble_time = 2.2
	if score >= 0.7:
		happy_served += 1
		progress_daily("happy",1,"")
func new_daily():
	var open: Array = []
	for f in cfg.families:
		if opened[f.id]: open.append(f.id)
	var kinds: Array = cfg.v("daily_kinds")
	var kind: String = kinds[rng.randi_range(0,kinds.size()-1)]
	var n := open.size()
	var target_family: String = open[rng.randi_range(0,n-1)]
	var goal := 0
	var reward := 0
	match kind:
		"family": goal = 12 + 4*n; reward = 50 + 60*n
		"revenue": goal = int(round(250*n*franchise_multiplier()/50.0))*50; reward = goal/5
		"happy": goal = 12 + 4*n; reward = 60 + 60*n
		"vip": goal = 2 + n; reward = 80 + 70*n
	daily = {"day":day_number(),"kind":kind,"family":target_family,"goal":goal,"progress":0,"reward":reward,"done":false}
func daily_text() -> String:
	if daily.is_empty(): return ""
	var what := ""
	match daily.kind:
		"family": what = "Vendre %d articles %s" % [daily.goal,cfg.family(daily.family).get("name","").to_lower()]
		"revenue": what = "Encaisser %d billets" % daily.goal
		"happy": what = "Satisfaire %d clients" % daily.goal
		"vip": what = "Servir %d clients VIP" % daily.goal
	return what
func progress_daily(kind: String, amount: int, family_id: String):
	if daily.is_empty() or daily.done or daily.kind != kind: return
	if kind == "family" and family_id != daily.family: return
	daily.progress = mini(daily.goal,int(daily.progress) + amount)
	if daily.progress >= daily.goal:
		daily.done = true
		dailies_done += 1
		money += int(daily.reward)
		achievement_rewards += int(daily.reward)
		daily_completed.emit(daily)
func update_day():
	var d := day_number()
	if d == last_day: return
	best_day = maxi(best_day,day_revenue)
	day_revenue = 0
	last_day = d
	new_daily()
	new_day.emit(d)
func franchise_ready() -> bool:
	if expansion < 2: return false
	for id in opened:
		if not opened[id]: return false
	return true
# Prestige: open a new workshop with a permanent sales bonus; history and achievements stay.
func start_franchise():
	franchise_level += 1
	sales.clear()
	revenue_started_at = elapsed
	money = cfg.v("initial_money") + franchise_level * cfg.v("franchise_start_bonus")
	expansion = 0; checkouts = 1
	for f in cfg.families:
		opened[f.id] = f.id == "tools"
		levels[f.id] = {"capacity":1,"value":1,"service":1}
		slots[f.id] = [-1,-1]
		last_restock[f.id] = 0.0
		inventory.shelves[f.id] = 0; inventory.reserve[f.id] = 0
	worker_levels = {"speed":1,"carry":1,"restock":1}
	cash_levels = [1,1]
	workers = [BricoWorker.new(0)]
	customers = []
	queues = [[],[]]
	tasks = {}
	decor = []
	event = {}; event_timer = cfg.v("event_first")
	inventory.shelves.tools = cfg.v("shelf_capacity")
	inventory.reserve.tools = cfg.v("reserve_capacity")
	inventory.delivered = inventory.total(); inventory.sold = 0
	delivery_timer = cfg.v("delivery_interval")
	nav.rebuild(expansion,opened,cfg)
	new_daily()
	franchised.emit(franchise_level)
func update_event(dt: float):
	if event.is_empty():
		event_timer -= dt
		if event_timer <= 0:
			var list: Array = cfg.v("events")
			event = list[rng.randi_range(0,list.size()-1)]
			event_left = event.duration
			events_seen += 1
			event_started.emit(event)
	else:
		event_left -= dt
		if event_left <= 0:
			var finished := event
			event = {}
			var interval: Array = cfg.v("event_interval")
			event_timer = rng.randf_range(interval[0],interval[1])
			event_ended.emit(finished)
func stat(name: String) -> int:
	match name:
		"sales": return total_sales
		"revenue": return total_revenue
		"workers": return workers.size()
		"events": return events_seen
		"rating10": return int(floor(rating()*10)) if outcomes.size() >= cfg.v("rating_window") else 0
		"dailies": return dailies_done
		"franchise": return franchise_level
		"families":
			var n := 0
			for id in opened:
				if opened[id]: n += 1
			return n
		"max_level":
			var best := 1
			for id in levels:
				if opened[id]:
					for key in levels[id]: best = maxi(best,levels[id][key])
			for key in worker_levels: best = maxi(best,worker_levels[key])
			for i in range(checkouts): best = maxi(best,cash_levels[i])
			return best
	return 0
func check_achievements():
	for a in cfg.v("achievements"):
		if achievements.has(a.id) or stat(a.stat) < a.goal: continue
		achievements.append(a.id)
		money += int(a.reward)
		achievement_rewards += int(a.reward)
		achieved.emit(a)
# Hour of the in-game day (0-24), purely cosmetic and derived from saved elapsed time.
func day_hour() -> float:
	return fmod(8.0 + elapsed / cfg.v("day_seconds") * 24.0, 24.0)
func day_number() -> int:
	return int((elapsed / cfg.v("day_seconds") * 24.0 + 8.0) / 24.0) + 1
func record_sale(customer: BricoCustomer):
	money += customer.unit_value
	inventory.sold += customer.items
	family_sales[customer.family] = int(family_sales.get(customer.family,0)) + customer.items
	total_sales += 1
	total_revenue += customer.unit_value
	day_revenue += customer.unit_value
	minute_acc += customer.unit_value
	if customer.profile == "vip":
		vip_served += 1
		progress_daily("vip",1,"")
	progress_daily("family",customer.items,customer.family)
	progress_daily("revenue",customer.unit_value,"")
	sales.append([elapsed, customer.unit_value])
	if tutorial == 0: tutorial = 1
	sale.emit(customer.unit_value,customer.pos)
func tick(dt: float):
	elapsed += dt
	arrival_timer -= dt
	delivery_timer -= dt
	if arrival_timer <= 0:
		spawn_customer()
		arrival_timer += rng.randf_range(cfg.v("arrival_min"),cfg.v("arrival_max")) * arrival_multiplier()
	if delivery_timer <= 0:
		inventory.deliver(opened,reserve_capacity())
		delivery_timer += cfg.v("delivery_interval")
	update_event(dt)
	achievement_timer -= dt
	if achievement_timer <= 0:
		achievement_timer = 1.0
		check_achievements()
		update_day()
	minute_timer += dt
	if minute_timer >= 60:
		minute_timer -= 60
		minute_revenue.append(minute_acc); minute_acc = 0
		while minute_revenue.size() > 15: minute_revenue.pop_front()
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
	var duration := minf(120, maxf(0, elapsed-revenue_started_at))
	var revenue := 0
	for s in sales: revenue += int(s[1])
	return {"duration":duration,"revenue":revenue,"count":sales.size()}
func measured_rpm() -> float:
	var stats := recent_stats()
	if stats.duration < 30 or sales.size() < 2: return -1
	return stats.revenue * 60.0 / stats.duration
func stock_audit() -> int:
	var n := inventory.total() + inventory.sold
	for w in workers: n += w.cargo
	for c in customers:
		n += c.items
	return n - inventory.delivered
func snapshot(now: int) -> Dictionary:
	var reserves := inventory.reserve.duplicate(true)
	# Rebuild agents on load: return all unsettled goods to their original family.
	for w in workers:
		if w.cargo > 0: reserves[w.family] += w.cargo
	for c in customers:
		if c.items > 0: reserves[c.family] += c.items
	return {"version":2,"store_id":cfg.v("store_id"),"money":money,"opened":opened.duplicate(true),"levels":levels.duplicate(true),"worker_levels":worker_levels.duplicate(true),"cash_levels":cash_levels.duplicate(),"worker_count":workers.size(),"expansion":expansion,"checkouts":checkouts,"shelves":inventory.shelves.duplicate(true),"reserve":reserves,"tutorial":tutorial,"settings":settings.duplicate(true),"elapsed":elapsed,"revenue_started_at":revenue_started_at,"sales":sales.duplicate(true),"total_sales":total_sales,"total_revenue":total_revenue,"achievements":achievements.duplicate(),"achievement_rewards":achievement_rewards,"events_seen":events_seen,"outcomes":outcomes.duplicate(),"happy_served":happy_served,"vip_served":vip_served,"family_sales":family_sales.duplicate(),"minute_revenue":minute_revenue.duplicate(),"day_revenue":day_revenue,"best_day":best_day,"last_day":last_day,"daily":daily.duplicate(),"dailies_done":dailies_done,"decor":decor.duplicate(),"franchise_level":franchise_level,"tips_seen":tips_seen.duplicate(),"last_saved":now,"delivery_timer":delivery_timer,"observed_rate":recent_stats()}
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
	var saved_settings = data.get("settings",{})
	for key in settings:
		if key == "volume": settings[key] = clampf(float(saved_settings.get(key,settings[key])),0.0,1.0)
		else: settings[key] = bool(saved_settings.get(key,settings[key]))
	elapsed = maxf(0,float(data.get("elapsed",0)))
	revenue_started_at = clampf(float(data.get("revenue_started_at",0)),0,elapsed)
	sales = []
	for s in data.get("sales",[]):
		if s is Array and s.size() == 2 and s[0] is float and s[1] >= 0: sales.append(s)
	total_sales = maxi(0,int(data.get("total_sales",0)))
	total_revenue = maxi(0,int(data.get("total_revenue",0)))
	achievements = []
	var known: Array = cfg.v("achievements").map(func(a): return a.id)
	var saved_achievements = data.get("achievements",[])
	if saved_achievements is Array:
		for id in saved_achievements:
			if id is String and known.has(id) and not achievements.has(id): achievements.append(id)
	achievement_rewards = maxi(0,int(data.get("achievement_rewards",0)))
	events_seen = maxi(0,int(data.get("events_seen",0)))
	outcomes = []
	var saved_outcomes = data.get("outcomes",[])
	if saved_outcomes is Array:
		for o in saved_outcomes:
			if (o is float or o is int) and o >= 0 and o <= 1: outcomes.append(float(o))
	while outcomes.size() > cfg.v("rating_window"): outcomes.pop_front()
	happy_served = maxi(0,int(data.get("happy_served",0)))
	vip_served = maxi(0,int(data.get("vip_served",0)))
	var saved_family = data.get("family_sales",{})
	for f in cfg.families: family_sales[f.id] = maxi(0,int(saved_family.get(f.id,0))) if saved_family is Dictionary else 0
	minute_revenue = []
	var saved_minutes = data.get("minute_revenue",[])
	if saved_minutes is Array:
		for m in saved_minutes.slice(-15): minute_revenue.append(maxi(0,int(m)))
	day_revenue = maxi(0,int(data.get("day_revenue",0)))
	best_day = maxi(0,int(data.get("best_day",0)))
	last_day = maxi(1,int(data.get("last_day",day_number())))
	dailies_done = maxi(0,int(data.get("dailies_done",0)))
	franchise_level = clampi(int(data.get("franchise_level",0)),0,99)
	decor = []
	var saved_decor = data.get("decor",[])
	var decor_ids: Array = cfg.v("decor").map(func(item): return item.id)
	if saved_decor is Array:
		for id in saved_decor:
			if id is String and decor_ids.has(id) and not decor.has(id): decor.append(id)
	tips_seen = []
	var saved_tips = data.get("tips_seen",[])
	if saved_tips is Array:
		for id in saved_tips:
			if id is String and not tips_seen.has(id): tips_seen.append(id)
	var saved_daily = data.get("daily",{})
	var kinds: Array = cfg.v("daily_kinds")
	if saved_daily is Dictionary and kinds.has(saved_daily.get("kind","")) and int(saved_daily.get("goal",0)) > 0 and opened.get(str(saved_daily.get("family","")),false):
		daily = {"day":int(saved_daily.get("day",day_number())),"kind":str(saved_daily.kind),"family":str(saved_daily.family),"goal":int(saved_daily.goal),"progress":clampi(int(saved_daily.get("progress",0)),0,int(saved_daily.goal)),"reward":maxi(0,int(saved_daily.get("reward",0))),"done":bool(saved_daily.get("done",false))}
	else:
		new_daily()
	delivery_timer = clampf(float(data.get("delivery_timer",20)),0.1,cfg.v("delivery_interval"))
	inventory.delivered = inventory.total()
	inventory.sold = 0
	nav.rebuild(expansion,opened,cfg)
