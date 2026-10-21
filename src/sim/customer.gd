class_name BricoCustomer
extends RefCounted
enum State {ARRIVING, CHOOSING, WALKING_SHELF, WAITING_SLOT, WAITING_STOCK, PICKING, CHOOSING_CHECKOUT, QUEUING, PAYING, LEAVING, DONE}
var id: int
var state := State.ARRIVING
var pos: Vector2
var direction := Vector2.DOWN
var route := PackedVector2Array()
var family := ""
var slot := -1
var checkout := -1
var timer := 0.0
var age := 0.0
var carrying := false
var unit_value := 0
var appearance := 0
var failures := 0
var queue_target := Vector2.INF
var hurried := false
func _init(number: int, entrance: Vector2):
	id = number
	pos = entrance + Vector2((number % 3 - 1) * 12, 0)
	appearance = number % 6
func go(sim, target: Vector2) -> bool:
	route = sim.nav.path(pos, target)
	if route.is_empty():
		failures += 1
		return false
	return true
func speed(sim) -> float:
	return sim.cfg.v("customer_speed") * (sim.cfg.v("hurried_speed") if hurried else 1.0)
func release_slot(sim):
	if slot >= 0:
		sim.slots[family][slot] = -1
		slot = -1
func leave(sim):
	release_slot(sim)
	state = State.LEAVING
	if not go(sim, sim.nav.entrance):
		pos = sim.nav.entrance
		state = State.DONE
func tick(sim, dt: float):
	age += dt
	timer += dt
	match state:
		State.ARRIVING:
			state = State.CHOOSING
		State.CHOOSING:
			var choices: Array = []
			for f in sim.cfg.families:
				if sim.opened[f.id]: choices.append(f.id)
			if choices.is_empty() or sim.shortest_queue() >= sim.cfg.v("queue_tolerance"):
				leave(sim)
				return
			family = choices[sim.rng.randi_range(0, choices.size()-1)]
			state = State.WAITING_SLOT
			timer = 0
			go(sim, Vector2(290 + (id % 4) * 22, 560 + (id % 3) * 25))
		State.WAITING_SLOT:
			BricoNavigation.move_agent(self, dt, speed(sim))
			for i in range(2):
				if sim.slots[family][i] == -1:
					slot = i
					sim.slots[family][i] = id
					var point: Array = sim.cfg.family(family).customer[i]
					if go(sim, Vector2(point[0], point[1])): state = State.WALKING_SHELF
					else: leave(sim)
					return
			if timer > sim.cfg.v("slot_patience"): leave(sim)
		State.WALKING_SHELF:
			if BricoNavigation.move_agent(self, dt, speed(sim)):
				state = State.WAITING_STOCK
				timer = 0
		State.WAITING_STOCK:
			if sim.inventory.shelves[family] > 0:
				state = State.PICKING
				timer = 0
			elif timer > sim.cfg.v("empty_patience"):
				sim.empty_departures += 1
				leave(sim)
		State.PICKING:
			if timer >= sim.pick_time(family):
				if sim.inventory.pick(family):
					carrying = true
					unit_value = int(round(sim.sale_value(family) * sim.value_multiplier()))
					release_slot(sim)
					state = State.CHOOSING_CHECKOUT
				else:
					state = State.WAITING_STOCK
					timer = 0
		State.CHOOSING_CHECKOUT:
			checkout = sim.choose_checkout()
			sim.queues[checkout].append(id)
			state = State.QUEUING
			queue_target = Vector2.INF
		State.QUEUING:
			var index: int = sim.queues[checkout].find(id)
			var target := Vector2((210 if checkout == 0 else 430) + (index / 6) * (-30 if checkout == 0 else 30), 730 - (index % 6) * 28)
			if target != queue_target:
				queue_target = target
				if not go(sim, target):
					# Keep a taken product; controlled recovery to the legal queue point.
					pos = target
			var arrived := BricoNavigation.move_agent(self, dt, speed(sim))
			if index == 0 and arrived:
				state = State.PAYING
				timer = 0
		State.PAYING:
			if timer >= sim.checkout_time(checkout):
				sim.record_sale(self)
				sim.queues[checkout].erase(id)
				carrying = false
				leave(sim)
		State.LEAVING:
			if BricoNavigation.move_agent(self, dt, speed(sim)): state = State.DONE
	# No customer can stay indefinitely due to a navigation failure before taking a product.
	if age > 180 and not carrying and state != State.LEAVING: leave(sim)
