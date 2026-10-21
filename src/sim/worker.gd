class_name BricoWorker
extends RefCounted
enum State {IDLE, TO_RESERVE, LOADING, CARRYING, RESTOCKING}
var id: int
var state := State.IDLE
var pos: Vector2
var direction := Vector2.DOWN
var route := PackedVector2Array()
var family := ""
var cargo := 0
var timer := 0.0
var waiting_goods := false
# Each employee has a stable name and specialty derived from their slot.
const NAMES := ["Léa","Karim","Inès","Tom","Sofia","Malik"]
const TRAITS := ["Rapide","Costaud","Minutieux"]
var name := ""
var specialty := ""
func _init(number: int):
	id = number
	pos = Vector2(130 + number * 26, 580)
	name = NAMES[number % NAMES.size()]
	specialty = TRAITS[number % TRAITS.size()]
func speed(sim) -> float:
	return sim.worker_speed() * (1.2 if specialty == "Rapide" else 1.0)
func carry(sim) -> int:
	return sim.carry_capacity() + (2 if specialty == "Costaud" else 0)
func restock_duration(sim) -> float:
	return sim.restock_time() * (0.75 if specialty == "Minutieux" else 1.0)
static func specialty_text(value: String) -> String:
	match value:
		"Rapide": return "se déplace 20 % plus vite"
		"Costaud": return "porte 2 unités de plus"
		"Minutieux": return "remplit le rayon 25 % plus vite"
	return ""
func cancel(sim):
	if cargo > 0:
		sim.inventory.reserve[family] += cargo
		cargo = 0
	if not family.is_empty(): sim.tasks.erase(family)
	family = ""
	state = State.IDLE
func tick(sim, dt: float):
	timer += dt
	match state:
		State.IDLE:
			waiting_goods = false
			var best := ""
			var best_score := INF
			for f in sim.cfg.families:
				var key: String = f.id
				if not sim.opened[key] or sim.tasks.has(key): continue
				var stock: int = sim.inventory.shelves[key]
				if stock >= sim.capacity(key): continue
				if sim.inventory.reserve[key] <= 0:
					waiting_goods = true
					continue
				var score: float = float(stock) / sim.capacity(key) - minf(0.3, (sim.elapsed - sim.last_restock[key]) / 200.0)
				if score < best_score:
					best_score = score
					best = key
			if not best.is_empty():
				family = best
				sim.tasks[family] = id
				route = sim.nav.path(pos, sim.nav.stock_point + Vector2(0,id * 22))
				if route.is_empty(): cancel(sim)
				else: state = State.TO_RESERVE
		State.TO_RESERVE:
			if BricoNavigation.move_agent(self, dt, speed(sim)):
				state = State.LOADING
				timer = 0
		State.LOADING:
			if timer >= sim.cfg.v("loading_seconds"):
				var space: int = sim.capacity(family) - sim.inventory.shelves[family]
				cargo = sim.inventory.take_reserve(family, mini(carry(sim),space))
				if cargo == 0:
					cancel(sim)
					return
				var p: Array = sim.cfg.family(family).worker
				route = sim.nav.path(pos, Vector2(p[0],p[1]))
				if route.is_empty(): cancel(sim)
				else: state = State.CARRYING
		State.CARRYING:
			if BricoNavigation.move_agent(self, dt, speed(sim)):
				state = State.RESTOCKING
				timer = 0
		State.RESTOCKING:
			if timer >= restock_duration(sim):
				sim.inventory.put_shelf(family, cargo)
				cargo = 0
				sim.last_restock[family] = sim.elapsed
				sim.restock_count += 1
				if sim.tutorial == 3: sim.tutorial = 4
				sim.tasks.erase(family)
				state = State.IDLE
				family = ""
