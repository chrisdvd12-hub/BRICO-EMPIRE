class_name BricoStoreView
extends Node2D
signal selected(kind: String, id: String)
var sim: BricoSimulation
var font := ThemeDB.fallback_font
var effects: Array = []
var phase := 0.0
var debug_states := false
var camera_offset := Vector2(-3, 130)
var camera_zoom := 0.69
var press := Vector2.ZERO
var last_pointer := Vector2.ZERO
var dragged := false
var held := false
var fingers: Dictionary = {}
var pinch_distance := 0.0
var purchase_flash := 0.0
var coins: Array = []
var shelf_flash := {}
var daylight: CanvasModulate
const INK := Color("174956")
const CREAM := Color("fff4df")
const ORANGE := Color("f2aa56")
func setup(simulation: BricoSimulation):
	sim = simulation
	recenter()
	daylight = CanvasModulate.new(); add_child(daylight)
	# Neighbourhood: static decor behind the store, traffic and lights above it.
	var world_back := BricoWorldView.new(); world_back.setup(sim,false); add_child(world_back)
	var world_front := BricoWorldView.new(); world_front.setup(sim,true); add_child(world_front)
	sim.sale.connect(func(n,p):
		if effects.size() < sim.cfg.v("effect_limit"): effects.append({"p":p,"text":"+%d" % n,"time":0.0})
		if not sim.settings.reduced_effects and coins.size() < 30:
			for i in range(3): coins.append({"p":p+Vector2(0,-40),"v":Vector2(randf_range(-60,60),randf_range(-190,-130)),"time":0.0})
	)
	sim.purchased.connect(func(action,target):
		purchase_flash = 1.0
		if not target.is_empty() and not sim.cfg.family(target).is_empty(): shelf_flash[target] = 1.0
		if action == "expand": recenter())
func p(v: Vector2) -> Vector2:
	return Vector2(v.x + v.y * 0.17,v.y * 0.9)
func unproject(v: Vector2) -> Vector2:
	var world := (v-camera_offset) / camera_zoom
	return Vector2(world.x-world.y/0.9*0.17,world.y/0.9)
func _process(dt: float):
	phase += minf(dt,0.1)
	purchase_flash = maxf(0,purchase_flash-dt)
	for e in effects: e.time += dt
	effects = effects.filter(func(e): return e.time < 1.5)
	for c in coins:
		c.time += dt; c.v.y += 420*dt; c.p += c.v*dt
	coins = coins.filter(func(c): return c.time < 0.9)
	for id in shelf_flash.keys():
		shelf_flash[id] -= dt
		if shelf_flash[id] <= 0: shelf_flash.erase(id)
	daylight.color = daylight_color()
	position = camera_offset
	scale = Vector2.ONE * camera_zoom
	queue_redraw()
func poly(points: Array, color: Color):
	var packed := PackedVector2Array()
	for point in points: packed.append(p(point))
	draw_colored_polygon(packed,color)
func floor_rect(r: Rect2, color: Color):
	poly([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)],color)
func text_at(at: Vector2, text: String, size: int, color := INK):
	draw_string(font,p(at),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func round_rect(at: Vector2, size: Vector2, color: Color, radius := 6):
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	draw_style_box(box,Rect2(at,size))
func box(r: Rect2, color: Color, height := 24.0):
	var a := p(r.position)
	var b := p(r.position+Vector2(r.size.x,0))
	var c := p(r.end)
	var d := p(r.position+Vector2(0,r.size.y))
	var h := Vector2(0,-height)
	draw_colored_polygon(PackedVector2Array([a,b,c,d]),color.darkened(.25))
	draw_colored_polygon(PackedVector2Array([d,c,c+h,d+h]),color.darkened(.12))
	draw_colored_polygon(PackedVector2Array([b,c,c+h,b+h]),color.darkened(.25))
	draw_colored_polygon(PackedVector2Array([a+h,b+h,c+h,d+h]),color)
func product(at: Vector2, kind: String, shade: Color, variant: int):
	var q := p(at)
	match kind:
		"paint":
			round_rect(q+Vector2(-9,-19),Vector2(18,20),Color("fff9ed"),3)
			round_rect(q+Vector2(-9,-13),Vector2(18,10),shade,2)
			ellipse_shape(q+Vector2(0,-19),Vector2(10,3),INK)
			draw_arc(q+Vector2(0,-16),8,PI,TAU,12,INK,1.6,true)
		"garden":
			if variant % 2 == 0:
				round_rect(q+Vector2(-10,-22),Vector2(20,25),Color("ded0a1"),5)
				round_rect(q+Vector2(-9,-16),Vector2(18,13),shade,3)
				draw_line(q+Vector2(0,-4),q+Vector2(0,-13),CREAM,2)
			else:
				draw_colored_polygon(PackedVector2Array([q+Vector2(-9,-8),q+Vector2(9,-8),q+Vector2(6,5),q+Vector2(-6,5)]),Color("d18a61"))
				draw_line(q+Vector2(0,-7),q+Vector2(0,-25),Color("5c925f"),3)
				ellipse_shape(q+Vector2(-5,-22),Vector2(8,4),shade)
				ellipse_shape(q+Vector2(5,-17),Vector2(8,4),shade)
		"tools":
			if variant % 3 == 0:
				round_rect(q+Vector2(-12,-16),Vector2(24,19),shade,4)
				draw_rect(Rect2(q+Vector2(-5,-21),Vector2(10,5)),INK,false,2)
				draw_line(q+Vector2(-11,-8),q+Vector2(11,-8),INK,2)
				draw_rect(Rect2(q+Vector2(-2,-10),Vector2(4,6)),CREAM)
			elif variant % 3 == 1:
				draw_line(q+Vector2(0,2),q+Vector2(4,-21),Color("af774b"),5,true)
				round_rect(q+Vector2(-6,-25),Vector2(24,8),Color("8fa9ab"),3)
			else:
				round_rect(q+Vector2(-10,-20),Vector2(21,12),shade,3)
				draw_line(q+Vector2(-2,-9),q+Vector2(-2,1),INK,7)
				draw_line(q+Vector2(11,-15),q+Vector2(19,-15),Color("a8b5ae"),3)
		"electric":
			if variant % 2 == 0:
				draw_circle(q+Vector2(0,-15),8,shade.lightened(.25))
				draw_circle(q+Vector2(-2,-17),3,Color(1,1,1,.7))
				round_rect(q+Vector2(-4,-8),Vector2(8,8),Color("a8b5ae"),2)
			else:
				draw_circle(q+Vector2(0,-10),10,Color("d9634c"))
				draw_circle(q+Vector2(0,-10),4,INK)
				draw_arc(q+Vector2(0,-10),7,0,TAU,16,Color("f08a6c"),2,true)
		"plumbing":
			if variant % 2 == 0:
				draw_line(q+Vector2(-9,-4),q+Vector2(-9,-18),shade,6,true)
				draw_line(q+Vector2(-9,-18),q+Vector2(9,-18),shade,6,true)
				draw_circle(q+Vector2(-9,-18),4,shade.darkened(.2))
			else:
				round_rect(q+Vector2(-8,-22),Vector2(16,7),Color("c6cfd3"),3)
				draw_line(q+Vector2(0,-16),q+Vector2(0,-6),Color("c6cfd3"),5)
				draw_line(q+Vector2(0,-6),q+Vector2(8,-6),Color("c6cfd3"),5)
				draw_circle(q+Vector2(9,-1),2.5,shade)
func ellipse_shape(center: Vector2, radii: Vector2, color: Color):
	var points := PackedVector2Array()
	for i in range(24): points.append(center+Vector2(cos(i*TAU/24)*radii.x,sin(i*TAU/24)*radii.y))
	draw_colored_polygon(points,color)
func shelf(f: Dictionary):
	var r := Rect2(f.rect[0],f.rect[1],f.rect[2],f.rect[3])
	if not sim.opened[f.id]:
		floor_rect(r,Color("d6d6bb"))
		for i in range(4):
			var a := r.position+Vector2(i*24,0)
			draw_line(p(a),p(a+Vector2(0,r.size.y)),Color("b7bba2"),3)
		text_at(r.position+Vector2(-4,35),"+ " + f.name,17)
		text_at(r.position+Vector2(5,60),"À CONSTRUIRE",12)
		return
	var level: int = maxi(sim.levels[f.id].capacity,sim.levels[f.id].value)
	var body := INK.lightened(.08 if level < 3 else .2)
	if level >= 5: body = Color("3f887f")
	box(r,body,38)
	box(Rect2(r.position+Vector2(-3,3),Vector2(r.size.x+6,9)),ORANGE if level >= 3 else Color("84abb0"),50)
	for row in range(2):
		for col in range(4):
			var i := row*4+col
			if i >= ceili(float(sim.inventory.shelves[f.id]) / sim.capacity(f.id)*8): continue
			product(r.position+Vector2(14+col*23,30+row*35),f.id,Color(f.color).lightened(col*.05),i)
	var label := p(r.position+Vector2(-5,r.size.y+19))
	round_rect(label+Vector2(-4,-18),Vector2(126,26),CREAM,7)
	draw_string(font,label+Vector2(2,1),"%s · %d/%d" % [f.name,sim.inventory.shelves[f.id],sim.capacity(f.id)],HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)
	if shelf_flash.has(f.id) and not sim.settings.reduced_effects:
		var k: float = shelf_flash[f.id]
		var center := p(r.get_center())+Vector2(0,-30)
		draw_arc(center,40+(1-k)*45,0,TAU,32,Color(1,.85,.35,k),4,true)
		for i in range(6):
			var a := i*TAU/6+phase*2
			draw_circle(center+Vector2(cos(a),sin(a))*(30+(1-k)*60),4*k,Color("ffe08a"))
	if sim.inventory.shelves[f.id] <= 2:
		round_rect(label+Vector2(-4,12),Vector2(126,24),Color("f5c786"),5)
		draw_string(font,label+Vector2(3,29),"VIDE" if sim.inventory.shelves[f.id] == 0 else "STOCK FAIBLE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK)
func character(agent, worker: bool):
	var q := p(agent.pos)
	var moving: bool = not agent.route.is_empty()
	var bounce := sin(phase*13+agent.id)*2 if moving and not sim.settings.reduced_effects else 0.0
	ellipse_shape(q+Vector2(0,2),Vector2(12,5),Color(0.12,0.22,0.23,.17))
	var colors := [Color("d98771"),Color("8d9abb"),Color("7eaf8e"),Color("d2ac66"),Color("ae8bbb"),Color("6ea5ac")]
	var skin: Color = [Color("efbb8c"),Color("bc855f"),Color("8c5b44")][agent.id % 3]
	var shirt: Color = ORANGE if worker else colors[agent.appearance]
	var stride := sin(phase*13+agent.id)*4 if moving else 0.0
	# Picking or restocking: feet stay planted, only the arms reach up to the shelf.
	var reach := 0.0
	if not moving and not sim.settings.reduced_effects and ((worker and agent.state == BricoWorker.State.RESTOCKING) or (not worker and agent.state == BricoCustomer.State.PICKING)):
		reach = 0.5+0.5*sin(phase*5+agent.id)
	draw_line(q+Vector2(-4,-10),q+Vector2(-5+stride,1),INK,5,true)
	draw_line(q+Vector2(4,-10),q+Vector2(5-stride,1),INK,5,true)
	q.y += bounce
	round_rect(q+Vector2(-9,-30),Vector2(18,22),shirt,6)
	draw_line(q+Vector2(-10,-25),q+Vector2(-12-stride,-14-reach*16),skin,4,true)
	draw_line(q+Vector2(10,-25),q+Vector2(12+stride,-14-(1-reach)*16 if reach > 0 else -14),skin,4,true)
	draw_circle(q+Vector2(0,-38),9,skin)
	if worker:
		round_rect(q+Vector2(-11,-47),Vector2(22,8),ORANGE.lightened(.2),4)
		draw_rect(Rect2(q+Vector2(-6,-23),Vector2(12,14)),INK)
	else:
		draw_arc(q+Vector2(0,-39),9,PI,TAU,12,INK.lightened(.05),4,true)
	if not worker and agent.hurried and moving and not sim.settings.reduced_effects:
		for i in range(3): draw_line(q+Vector2(-14,-34+i*9)-agent.direction*4,q+Vector2(-14,-34+i*9)-agent.direction*16,Color(1,1,1,.75),2,true)
	if (worker and agent.cargo > 0) or (not worker and agent.carrying):
		round_rect(q+Vector2(-9,-22),Vector2(21,16),Color("cda16d"),2)
		draw_line(q+Vector2(1,-22),q+Vector2(1,-6),Color("f3d2a5"),3)
	if worker and agent.state == BricoWorker.State.RESTOCKING:
		draw_arc(q+Vector2(0,-30),24,-PI/2,-PI/2+TAU*fmod(phase,1),20,Color("8ac29d"),3,true)
	if debug_states:
		var state_name: String = BricoWorker.State.keys()[agent.state] if worker else BricoCustomer.State.keys()[agent.state]
		draw_string(font,q+Vector2(-25,-58),state_name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,CREAM)
func cashier(index: int):
	var x := 150 if index == 0 else 370
	if index >= sim.checkouts:
		floor_rect(Rect2(x,760,100,55),Color("c8c9b5"))
		text_at(Vector2(x,792),"+ CAISSE 2",17)
		return
	var body := INK if sim.cash_levels[index] < 3 else Color("388578")
	box(Rect2(x,760,100,55),body,28)
	box(Rect2(x+12,765,28,20),Color("b4c9bc"),43)
	var q := p(Vector2(x+60,833))
	ellipse_shape(q+Vector2(0,3),Vector2(12,5),Color(0,0,0,.15))
	round_rect(q+Vector2(-9,-30),Vector2(18,24),Color("76aa96"),5)
	draw_circle(q+Vector2(0,-39),9,Color("c78d66"))
	draw_arc(q+Vector2(0,-40),9,PI,TAU,10,INK,4,true)
	text_at(Vector2(x+3,857),"CAISSE %d" % (index+1),15)
	if not sim.queues[index].is_empty():
		var customer = sim.customers.filter(func(c): return c.id == sim.queues[index][0])
		if not customer.is_empty() and customer[0].state == BricoCustomer.State.PAYING:
			var at := p(Vector2(x,750))
			round_rect(at+Vector2(0,-12),Vector2(100,7),Color("acc4b8"),3)
			round_rect(at+Vector2(0,-12),Vector2(100*clampf(customer[0].timer/sim.checkout_time(index),0,1),7),ORANGE,3)
func _draw():
	if sim == null: return
	# Original three-quarter artwork; coordinates also drive navigation and selection.
	floor_rect(Rect2(-30,-30,660,1000),Color("a39d88"))
	var top := 300 if sim.expansion == 0 else (140 if sim.expansion == 1 else 0)
	floor_rect(Rect2(0,top,600,900-top),Color("f2e6cc"))
	for y in range(top,901,60): draw_line(p(Vector2(0,y)),p(Vector2(600,y)),Color("dfd5be"),1,true)
	for x in range(0,601,60): draw_line(p(Vector2(x,top)),p(Vector2(x,900)),Color("dfd5be"),1,true)
	# Back and left walls with visible height.
	box(Rect2(0,top,600,12),Color("96bbad"),54)
	box(Rect2(0,top,12,900-top),Color("c5d3bd"),48)
	if sim.expansion < 2:
		var closed_top := 140 if sim.expansion == 0 else 0
		floor_rect(Rect2(15,closed_top,570,top-closed_top-12),Color("b7c4af"))
		for x in range(45,570,65):
			draw_line(p(Vector2(x,closed_top+20)),p(Vector2(x+25,top-30)),Color("9dab98"),9,true)
		var label := "01  NOUVELLE AILE" if sim.expansion == 0 else "02  GRAND DÉPÔT"
		text_at(Vector2(165,closed_top+55),label,24)
		text_at(Vector2(190,closed_top+90),"TOUCHER POUR AGRANDIR",15)
	# Reserve, reception and timed delivery vehicle.
	floor_rect(Rect2(20,300,115,100),Color("d0d0ae"))
	# Reception bay exists from the first store; the rear expansion adds a larger dock.
	floor_rect(Rect2(25,580,100,90),Color("d4d8bb"))
	text_at(Vector2(25,690),"LIVRAISON",18)
	for i in range(3): draw_line(p(Vector2(25+i*35,580)),p(Vector2(35+i*35,605)),ORANGE,5,true)
	if sim.delivery_timer < 3:
		box(Rect2(35,615,70,38),CREAM,28)
		box(Rect2(90,620,24,32),ORANGE,20)
		for x in [50,98]: draw_circle(p(Vector2(x,660)),7,INK)
		text_at(Vector2(39,647),"BRICO",13)
	else:
		box(Rect2(38,622,28,25),Color("c49a6a"),25)
		box(Rect2(76,620,25,28),Color("d3ae7e"),20)
	for i in range(3):
		box(Rect2(30+i*28,308,24,25),Color("c49a6a"),22+5*(i%2))
	text_at(Vector2(25,289),"RÉSERVE",20)
	if sim.expansion >= 1:
		floor_rect(Rect2(25,165,125,90),Color("d1d6b7"))
		box(Rect2(35,185,85,36),Color("c09364"),30)
		text_at(Vector2(25,255),"RÉCEPTION",17)
	if sim.expansion == 2:
		for i in range(2): box(Rect2(30+i*62,30,50,40),Color("cfa577"),32)
		box(Rect2(500,30,70,40),Color("cfa577"),32)
		text_at(Vector2(28,108),"GRAND DÉPÔT",15)
	if sim.delivery_timer < 3 and sim.expansion >= 1:
		box(Rect2(160,170,80,45),CREAM,32)
		text_at(Vector2(166,207),"BRICO",16)
	for f in sim.cfg.families:
		if f.expansion <= sim.expansion: shelf(f)
	for index in range(2): cashier(index)
	# Agents are sorted by depth, without scanning scene nodes.
	var agents: Array = sim.workers.duplicate()
	agents.append_array(sim.customers)
	agents.sort_custom(func(a,b): return a.pos.y < b.pos.y)
	for a in agents: character(a,a is BricoWorker)
	# Entrance awning and welcome mat.
	floor_rect(Rect2(238,862,125,35),Color("7cab96"))
	text_at(Vector2(251,884),"BIENVENUE",14,CREAM)
	box(Rect2(20,897,190,10),INK,20)
	box(Rect2(390,897,190,10),INK,20)
	for i in range(6): box(Rect2(220+i*27,916,27,26),ORANGE if i%2 == 0 else CREAM,70)
	text_at(Vector2(226,959),"BRICO EMPIRE",23,CREAM)
	for c in coins:
		var cq := p(c.p)
		draw_circle(cq,6,Color("e3a72f",1-c.time/0.9))
		draw_circle(cq,4,Color("ffd75e",1-c.time/0.9))
	if not sim.event.is_empty():
		var sign := p(Vector2(300,845))+Vector2(-95,-10)
		var blink := 0.85+0.15*sin(phase*6) if not sim.settings.reduced_effects else 1.0
		round_rect(sign,Vector2(190,30),Color("d9634c",blink),8)
		draw_string(font,sign+Vector2(0,21),sim.event.name.to_upper(),HORIZONTAL_ALIGNMENT_CENTER,190,15,CREAM)
	for e in effects:
		var q := p(e.p)+Vector2(5,-55-e.time*28)
		draw_string(font,q,e.text,HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color(0.1,.38,.25,1-e.time/1.5))
	if purchase_flash > 0 and not sim.settings.reduced_effects:
		for i in range(8):
			var at := p(Vector2(300,550))+Vector2(cos(i*TAU/8),sin(i*TAU/8))*(1-purchase_flash)*140
			draw_circle(at,4*purchase_flash,ORANGE)
func daylight_color() -> Color:
	# Soft cycle: day 7h-18h, golden dusk, blue night; reduced effects keep a lighter night.
	var h := sim.day_hour()
	var night := Color(.62,.7,.92) if not sim.settings.reduced_effects else Color(.85,.88,.96)
	var dusk := Color(1,.88,.76)
	if h >= 7 and h < 18: return Color.WHITE
	if h >= 18 and h < 20: return Color.WHITE.lerp(dusk,(h-18)/2)
	if h >= 20 and h < 21: return dusk.lerp(night,h-20)
	if h >= 6 and h < 7: return night.lerp(Color.WHITE,h-6)
	return night
func recenter():
	camera_offset = Vector2(-3,130)
	camera_zoom = .69
	if sim != null and sim.expansion == 1:
		camera_zoom = .66; camera_offset = Vector2(10,170)
	elif sim != null and sim.expansion == 2:
		camera_zoom = .59; camera_offset = Vector2(45,235)
func zoom_at(factor: float, at: Vector2):
	var before := (at-camera_offset)/camera_zoom
	camera_zoom = clampf(camera_zoom*factor,.45,1.3)
	camera_offset = at-before*camera_zoom
	clamp_camera()
func clamp_camera():
	# Wide enough to stroll around the neighbourhood; Recentrer brings the store back.
	camera_offset.x = clampf(camera_offset.x,-1400,1000)
	camera_offset.y = clampf(camera_offset.y,-1700,900)
func tap(at: Vector2):
	var w := unproject(at)
	for worker in sim.workers:
		if w.distance_to(worker.pos-Vector2(0,20)) < 30:
			selected.emit("workers",str(worker.id)); return
	for i in range(2):
		if Rect2(140 if i == 0 else 360,720,130,145).has_point(w):
			selected.emit("checkout",str(i)); return
	if Rect2(15,280,125,130).has_point(w) or Rect2(20,580,110,125).has_point(w) or (sim.expansion >= 1 and Rect2(20,150,130,110).has_point(w)):
		selected.emit("reserve",""); return
	var top := 300 if sim.expansion == 0 else 140
	if sim.expansion < 2 and w.y < top and w.y >= 0 and w.x >= 0 and w.x <= 600:
		selected.emit("expand",""); return
	for f in sim.cfg.families:
		if f.expansion <= sim.expansion and Rect2(f.rect[0]-12,f.rect[1]-65,f.rect[2]+24,f.rect[3]+110).has_point(w):
			selected.emit("shelf",f.id); return
func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_at(1.1,event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_at(1/1.1,event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				held = true; press = event.position; last_pointer = press; dragged = false
			elif held:
				held = false
				if not dragged: tap(event.position)
	if event is InputEventMouseMotion and held:
		if event.position.distance_to(press) > 12: dragged = true
		if dragged:
			camera_offset += event.position-last_pointer
			clamp_camera()
		last_pointer = event.position
	if event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			if fingers.size() == 1: press = event.position; dragged = false
			else:
				dragged = true
				var points := fingers.values()
				pinch_distance = points[0].distance_to(points[1])
		else:
			if fingers.has(event.index) and fingers.size() == 1 and not dragged: tap(event.position)
			fingers.erase(event.index)
			pinch_distance = 0
	if event is InputEventScreenDrag and fingers.has(event.index):
		fingers[event.index] = event.position
		if fingers.size() == 2:
			var points := fingers.values()
			var distance: float = points[0].distance_to(points[1])
			if pinch_distance > 0: zoom_at(distance/pinch_distance,(points[0]+points[1])/2)
			pinch_distance = distance
			dragged = true
		elif fingers.size() == 1:
			if event.position.distance_to(press) > 12: dragged = true
			if dragged: camera_offset += event.relative; clamp_camera()
func cancel_gestures():
	held = false
	fingers.clear()
	dragged = true
