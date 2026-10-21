class_name BricoStoreView
extends Node2D
signal selected(kind: String, id: String)
var sim: BricoSimulation
var font: Font = preload("res://assets/fonts/Fredoka-Regular.ttf")
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
var ui_blocks_point: Callable
const MAP_RECT := Rect2(-220,-150,1100,1500)
const PLAY_RECT := Rect2(0,196,540,586)
var purchase_flash := 0.0
var coins: Array = []
var shelf_flash := {}
var opening_fx := {}
var daylight: CanvasModulate
const INK := Color("174956")
const CREAM := Color("fff4df")
const ORANGE := Color("f2aa56")
func setup(simulation: BricoSimulation):
	sim = simulation
	recenter()
	daylight = CanvasModulate.new(); add_child(daylight)
	# Neighbourhood: static decor behind the store, traffic and lights above it.
	var world_back := BricoWorldView.new(); world_back.setup(sim,false,MAP_RECT); add_child(world_back)
	var floor_layer := BricoStoreFloor.new(); floor_layer.setup(sim); add_child(floor_layer)
	var world_front := BricoWorldView.new(); world_front.setup(sim,true,MAP_RECT); add_child(world_front)
	sim.sale.connect(func(n,p):
		if effects.size() < sim.cfg.v("effect_limit"): effects.append({"p":p,"text":"+%d" % n,"time":0.0})
		if not sim.settings.reduced_effects and coins.size() < 30:
			for i in range(3): coins.append({"p":p+Vector2(0,-40),"v":Vector2(randf_range(-60,60),randf_range(-190,-130)),"time":0.0})
	)
	sim.purchased.connect(func(action,target):
		purchase_flash = 1.0
		if action == "unlock": opening_fx[target] = 0.0
		if action == "expand": opening_fx["wing"] = 0.0
		if not target.is_empty() and not sim.cfg.family(target).is_empty(): shelf_flash[target] = 1.0
		if action == "expand" or action == "franchise": recenter())
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
	for id in opening_fx.keys():
		opening_fx[id] += dt
		if opening_fx[id] > 2.8: opening_fx.erase(id)
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
	# Light catches the front top edge.
	draw_line(d+h,c+h,color.lightened(.3),1.5,true)
func product(at: Vector2, kind: String, shade: Color, variant: int, lift := 0.0):
	var q := p(at)-Vector2(0,lift)
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
	# Furniture, products and hit regions share the configured footprint.
	if sim.opened[f.id]: floor_rect(Rect2(r.position-Vector2(7,7),r.size+Vector2(14,16)),Color(f.color).lerp(CREAM,.80))
	floor_rect(Rect2(r.position+Vector2(5,8),r.size+Vector2(8,4)),Color(0.08,.2,.22,.13))
	if not sim.opened[f.id]:
		floor_rect(r,Color("e2e8da"))
		for x in range(0,int(r.size.x),28):
			draw_line(p(r.position+Vector2(x,0)),p(r.position+Vector2(x+14,r.size.y)),Color("c5d1c0"),5,true)
		box(Rect2(r.position+Vector2(35,25),Vector2(60,40)),Color("d6b387"),30)
		var q := p(r.position)+Vector2(-4,-44)
		round_rect(q,Vector2(154,34),CREAM,9)
		draw_string(font,q+Vector2(8,23),"+ " + f.name,HORIZONTAL_ALIGNMENT_LEFT,-1,19,INK)
		text_at(r.position+Vector2(6,r.size.y+17),"EMPLACEMENT LIBRE",12)
		return
	var level: int = maxi(sim.levels[f.id].capacity,sim.levels[f.id].value)
	var body := Color("236575") if level < 3 else Color("287d83")
	if level >= 5: body = Color("368c76")
	var accent := Color(f.color)
	box(r,body,32)
	# Backboard and two product decks, polished edging and reinforced uprights.
	box(Rect2(r.position,Vector2(r.size.x,8)),body.lightened(.12),60)
	department_details(f,r,level)
	for row in range(2):
		var row_y := 28.0+row*(r.size.y-42)
		box(Rect2(r.position+Vector2(-2,row_y+7),Vector2(r.size.x+4,7)),Color("abcac4"),28)
		for col in range(4):
			var i := row*4+col
			if i >= ceili(float(sim.inventory.shelves[f.id]) / sim.capacity(f.id)*8): continue
			product(r.position+Vector2(19+col*34,row_y),f.id,accent.lightened(col*.06),i,30)
	for corner in [Vector2.ZERO,Vector2(r.size.x,0),Vector2(0,r.size.y),r.size]:
		var post := p(r.position+corner)
		draw_line(post,post+Vector2(0,-58),body.darkened(.18),5,true)
		draw_line(post+Vector2(-1,-56),post+Vector2(-1,-9),body.lightened(.35),1.5,true)
	var label := p(r.position)+Vector2(-5,-80)
	round_rect(label+Vector2(2,3),Vector2(154,30),Color(0,.1,.13,.14),8)
	round_rect(label,Vector2(154,30),INK,8)
	draw_circle(label+Vector2(14,15),5,accent)
	draw_string(font,label+Vector2(26,22),f.name,HORIZONTAL_ALIGNMENT_LEFT,-1,19,CREAM)
	var front := p(r.position+Vector2(0,r.size.y))+Vector2(0,-18)
	round_rect(front,Vector2(140,24),CREAM,5)
	draw_string(font,front+Vector2(8,17),"%d / %d  en rayon" % [sim.inventory.shelves[f.id],sim.capacity(f.id)],HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)
	if level >= 3:
		draw_line(p(r.position)+Vector2(0,-61),p(r.position+Vector2(r.size.x,0))+Vector2(0,-61),ORANGE,4,true)
	if level >= 5:
		for x in [12,r.size.x-12]: draw_circle(p(r.position+Vector2(x,0))+Vector2(0,-67),3,Color("ffe2a0"))
	if opening_fx.has(f.id): construction_effect(r,opening_fx[f.id])
	if shelf_flash.has(f.id) and not sim.settings.reduced_effects:
		var k: float = shelf_flash[f.id]
		var center := p(r.get_center())+Vector2(0,-30)
		draw_arc(center,40+(1-k)*45,0,TAU,32,Color(1,.85,.35,k),4,true)
		for i in range(6):
			var a := i*TAU/6+phase*2
			draw_circle(center+Vector2(cos(a),sin(a))*(30+(1-k)*60),4*k,Color("ffe08a"))
	if sim.inventory.shelves[f.id] <= 2:
		round_rect(front+Vector2(0,29),Vector2(126,24),Color("f5c786"),5)
		draw_string(font,front+Vector2(7,46),"VIDE" if sim.inventory.shelves[f.id] == 0 else "STOCK FAIBLE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK)
func department_details(f: Dictionary, r: Rect2, level: int):
	var at := p(r.position)+Vector2(0,-58)
	var accent := Color(f.color)
	match f.id:
		"tools":
			round_rect(at+Vector2(5,2),Vector2(130,25),Color("c49b70"),3)
			for y in range(2):
				for x in range(12): draw_circle(at+Vector2(11+x*10,8+y*10),1.3,Color("8b7051"))
			if level >= 3:
				for x in [14,118]: draw_line(at+Vector2(x,3),at+Vector2(x,25),ORANGE,3,true)
		"paint":
			round_rect(at+Vector2(6,1),Vector2(128,26),CREAM,3)
			for i in range(7):
				var colors := ["d96e61","e4a24b","e7ce6c","81ac7b","6dabae","849aca","be93b2"]
				draw_rect(Rect2(at+Vector2(12+i*17,5),Vector2(14,16)),Color(colors[i]))
			if level >= 3: draw_line(at+Vector2(5,28),at+Vector2(135,28),CREAM,4,true)
		"garden":
			round_rect(at+Vector2(5,-7),Vector2(130,33),Color("e4cf9f"),3)
			for x in range(12,135,17): draw_line(at+Vector2(x,-5),at+Vector2(x,24),Color("ae9366"),2,true)
			for y in [3,14]: draw_line(at+Vector2(6,y),at+Vector2(134,y),Color("ae9366"),2,true)
			for x in [12,128]:
				draw_line(at+Vector2(x,22),at+Vector2(x,-15),Color("5e945f"),3,true)
				for y in [0,12]: ellipse_shape(at+Vector2(x+4,y),Vector2(8,4),accent)
			if level >= 3:
				draw_polyline(PackedVector2Array([at+Vector2(0,-10),at+Vector2(70,-32),at+Vector2(140,-10)]),Color("8ab79b"),5,true)
		"electric":
			for x in [25,70,115]:
				draw_arc(at+Vector2(x,11),10,0,TAU,20,accent.darkened(.15),3,true)
				draw_line(at+Vector2(x,21),at+Vector2(x+8,27),accent,3,true)
		"plumbing":
			draw_polyline(PackedVector2Array([at+Vector2(12,24),at+Vector2(12,6),at+Vector2(128,6),at+Vector2(128,24)]),Color("9ac7d3"),7,true)
			for x in [22,65,112]: draw_circle(at+Vector2(x,6),5,Color("d1e3dd"))
func construction_effect(r: Rect2, elapsed: float):
	if sim.settings.reduced_effects: return
	var alpha := clampf((2.8-elapsed)*1.5,0,1)
	var center := p(r.get_center())
	for i in range(7):
		var t := fposmod(elapsed*.7+i*.17,1.0)
		var spark := center+Vector2((i-3)*23,-t*110)
		draw_circle(spark,3*(1-t),Color(1,.83,.45,alpha*(1-t)))
	var from := p(r.position+Vector2(0,r.size.y))+Vector2(0,11)
	round_rect(from,Vector2(r.size.x,24),Color(1,.93,.74,alpha),6)
	draw_string(font,from+Vector2(0,18),"OUVERTURE !",HORIZONTAL_ALIGNMENT_CENTER,r.size.x,16,Color(.09,.29,.34,alpha))
func character(agent, worker: bool):
	var q := p(agent.pos)
	var moving: bool = not agent.route.is_empty()
	var bounce := sin(phase*13+agent.id)*2 if moving and not sim.settings.reduced_effects else 0.0
	ellipse_shape(q+Vector2(0,2),Vector2(12,5),Color(0.12,0.22,0.23,.17))
	var colors := [Color("d98771"),Color("8d9abb"),Color("7eaf8e"),Color("d2ac66"),Color("ae8bbb"),Color("6ea5ac")]
	var skin: Color = [Color("efbb8c"),Color("bc855f"),Color("8c5b44")][agent.id % 3]
	var shirt: Color = [ORANGE,Color("6995aa"),Color("77ac91")][agent.id % 3] if worker else colors[agent.appearance]
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
	# Face, fabric and shoes remain readable at the normal phone zoom.
	draw_circle(q+Vector2(-3,-39),1.15,INK)
	draw_circle(q+Vector2(3,-39),1.15,INK)
	draw_arc(q+Vector2(0,-36),3,0.1,PI-0.1,8,skin.darkened(.28),1.1,true)
	draw_line(q+Vector2(-5,-27),q+Vector2(5,-27),shirt.lightened(.25),2,true)
	draw_line(q+Vector2(-6,-10),q+Vector2(6,-10),shirt.darkened(.2),2,true)
	if worker:
		match agent.specialty:
			"Rapide":
				round_rect(q+Vector2(-11,-47),Vector2(22,8),ORANGE.lightened(.2),4)
				draw_line(q+Vector2(-11,-40),q+Vector2(14,-40),ORANGE,3,true)
				draw_line(q+Vector2(-9,-1),q+Vector2(-1,-1),CREAM,3,true)
			"Costaud":
				draw_arc(q+Vector2(0,-41),10,PI,TAU,14,Color("f3ce6a"),6,true)
				draw_line(q+Vector2(-13,-40),q+Vector2(13,-40),Color("d3a657"),3,true)
				draw_line(q+Vector2(-10,-26),q+Vector2(-10,-14),shirt.darkened(.15),5,true)
			"Minutieux":
				draw_circle(q+Vector2(9,-39),6,Color("624a3e"))
				draw_line(q+Vector2(-9,-43),q+Vector2(8,-43),Color("7bc8b3"),4,true)
				draw_line(q+Vector2(9,-25),q+Vector2(9,-15),Color("f4d281"),3,true)
		draw_rect(Rect2(q+Vector2(-6,-23),Vector2(12,14)),INK)
	elif agent.profile == "vip":
		# Gold cap and lapel badge for big spenders.
		round_rect(q+Vector2(-10,-49),Vector2(20,8),Color("f2c14e"),4)
		draw_line(q+Vector2(-10,-42),q+Vector2(13,-42),Color("c9952a"),3,true)
		draw_circle(q+Vector2(4,-24),2.5,Color("f2c14e"))
	elif agent.profile == "artisan":
		# Yellow hard hat for tradespeople buying in bulk.
		draw_arc(q+Vector2(0,-40),10,PI,TAU,14,Color("f2c14e"),6,true)
		draw_line(q+Vector2(-13,-40),q+Vector2(13,-40),Color("d9a72c"),3,true)
	else:
		draw_arc(q+Vector2(0,-39),9,PI,TAU,12,INK.lightened(.05),4,true)
	if worker:
		round_rect(q+Vector2(-27,-64),Vector2(54,17),INK,6)
		draw_string(font,q+Vector2(-25,-51),agent.name,HORIZONTAL_ALIGNMENT_CENTER,50,12,CREAM)
		if agent.waiting_goods:
			round_rect(q+Vector2(-44,-87),Vector2(88,19),CREAM,5)
			draw_string(font,q+Vector2(-43,-73),"LIVRAISON…",HORIZONTAL_ALIGNMENT_CENTER,86,11,INK)
	if not worker and agent.hurried and moving and not sim.settings.reduced_effects:
		for i in range(3): draw_line(q+Vector2(-14,-34+i*9)-agent.direction*4,q+Vector2(-14,-34+i*9)-agent.direction*16,Color(1,1,1,.75),2,true)
	if (worker and agent.cargo > 0) or (not worker and agent.carrying):
		round_rect(q+Vector2(-9,-22),Vector2(21,16),Color("cda16d"),2)
		draw_line(q+Vector2(1,-22),q+Vector2(1,-6),Color("f3d2a5"),3)
		if not worker and agent.items > 1:
			round_rect(q+Vector2(-7,-34),Vector2(17,13),Color("d9b27f"),2)
	if not worker and agent.bubble_time > 0: mood_bubble(q+Vector2(14,-62),agent.bubble,minf(1,agent.bubble_time*2))
	if worker and agent.state == BricoWorker.State.RESTOCKING:
		draw_arc(q+Vector2(0,-30),24,-PI/2,-PI/2+TAU*fmod(phase,1),20,Color("8ac29d"),3,true)
	if debug_states:
		var state_name: String = BricoWorker.State.keys()[agent.state] if worker else BricoCustomer.State.keys()[agent.state]
		draw_string(font,q+Vector2(-25,-58),state_name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,CREAM)
func mood_bubble(at: Vector2, mood: String, alpha: float):
	var rise := Vector2(0,-6*(1-alpha))
	at += rise
	draw_circle(at,13,Color(1,1,1,.95*alpha))
	draw_colored_polygon(PackedVector2Array([at+Vector2(-6,10),at+Vector2(0,11),at+Vector2(-10,18)]),Color(1,1,1,.95*alpha))
	var face := {"happy":Color("2f9e6a"),"meh":Color("d9a72c"),"sad":Color("d9634c")}[mood] as Color
	face.a = alpha
	draw_circle(at+Vector2(-4,-3),1.8,face); draw_circle(at+Vector2(4,-3),1.8,face)
	if mood == "happy": draw_arc(at+Vector2(0,1),5,0.2,PI-0.2,10,face,2,true)
	elif mood == "sad": draw_arc(at+Vector2(0,8),5,PI+0.3,TAU-0.3,10,face,2,true)
	else: draw_line(at+Vector2(-4,4),at+Vector2(4,4),face,2)
func decorations(top: int):
	if sim.decor.has("posters"):
		var colors := [Color("d9634c"),Color("3f7fb5"),Color("2f9e6a"),Color("e8893a")]
		for i in range(4):
			var w := p(Vector2(118+i*130,top+12))
			draw_rect(Rect2(w+Vector2(0,-50),Vector2(34,24)),colors[i])
			draw_rect(Rect2(w+Vector2(4,-46),Vector2(26,6)),CREAM)
			draw_string(font,w+Vector2(2,-30),"-20%",HORIZONTAL_ALIGNMENT_LEFT,-1,10,CREAM)
	if sim.decor.has("plants"):
		for at in [Vector2(578,330),Vector2(578,640),Vector2(30,745),Vector2(578,880)]:
			if at.y < top + 20: continue
			var q := p(at)
			ellipse_shape(q+Vector2(2,2),Vector2(13,5),Color(0,0,0,.15))
			draw_colored_polygon(PackedVector2Array([q+Vector2(-9,-14),q+Vector2(9,-14),q+Vector2(6,0),q+Vector2(-6,0)]),Color("c97a4e"))
			for k in range(5):
				var a := -PI/2 + (k-2)*0.45
				draw_line(q+Vector2(0,-14),q+Vector2(0,-14)+Vector2(cos(a),sin(a))*18,Color("4e8a4b"),5,true)
	if sim.decor.has("coffee"):
		box(Rect2(520,828,40,26),Color("5b6f7a"),34)
		draw_circle(p(Vector2(530,835))+Vector2(0,-40),4,Color("f3e3c8"))
		for st in [Vector2(495,870),Vector2(530,880)]:
			var q := p(st); draw_line(q,q+Vector2(0,-14),INK,3); ellipse_shape(q+Vector2(0,-15),Vector2(9,4),Color("d9634c"))
		text_at(Vector2(496,822),"CAFÉ",12)
func neon_signs():
	if not sim.decor.has("neon"): return
	# Neon letters on the front facade, either side of the entrance.
	var night := sim.day_hour() >= 19 or sim.day_hour() < 7
	var flicker := 1.0 if sim.settings.reduced_effects else 0.85+0.15*sin(phase*9)
	for sign in [[Vector2(55,907),"BRICO",Color(1,.45,.7)],[Vector2(425,907),"OUVERT",Color(.45,.95,1)]]:
		var at := p(sign[0])+Vector2(0,-4)
		var tint: Color = sign[2]
		round_rect(at+Vector2(-6,-24),Vector2(126,28),Color(0.08,.1,.14,.92),7)
		var glow := tint; glow.a = (0.45 if night else 0.15)*flicker
		draw_string(font,at+Vector2(0,1),sign[1],HORIZONTAL_ALIGNMENT_CENTER,114,24,glow)
		draw_string(font,at,sign[1],HORIZONTAL_ALIGNMENT_CENTER,114,22,tint.lightened(.35) if night else tint.lightened(.55))
func cashier(index: int):
	var x := 150 if index == 0 else 370
	if index >= sim.checkouts:
		floor_rect(Rect2(x,760,100,55),Color("c8c9b5"))
		text_at(Vector2(x,792),"+ CAISSE 2",17)
		return
	var body := INK if sim.cash_levels[index] < 3 else Color("388578")
	box(Rect2(x,760,100,55),body,28)
	box(Rect2(x+7,766,44,30),Color("a3bbb4"),31)
	for y in [775,784,793]: draw_line(p(Vector2(x+10,y))+Vector2(0,-31),p(Vector2(x+47,y))+Vector2(0,-31),Color("7b9b98"),2,true)
	var monitor := p(Vector2(x+70,781))
	round_rect(monitor+Vector2(-12,-52),Vector2(29,21),Color("102f3b"),4)
	round_rect(monitor+Vector2(-8,-48),Vector2(21,12),Color("a9e5cf"),2)
	draw_line(monitor+Vector2(2,-30),monitor+Vector2(2,-18),INK,4,true)
	for y in [690,650,610]:
		var mark := p(Vector2(x+50,y))
		draw_arc(mark,9,0,PI,10,Color("9aaf9c"),2,true)
	var q := p(Vector2(x+60,833))
	ellipse_shape(q+Vector2(0,3),Vector2(12,5),Color(0,0,0,.15))
	round_rect(q+Vector2(-9,-30),Vector2(18,24),Color("76aa96"),5)
	draw_circle(q+Vector2(0,-39),9,Color("c78d66"))
	draw_arc(q+Vector2(0,-40),9,PI,TAU,10,INK,4,true)
	text_at(Vector2(x+3,857),"CAISSE %d" % (index+1),15)
	if sim.queues[index].size() >= 4:
		var sign := p(Vector2(x-3,749))+Vector2(0,-66)
		round_rect(sign,Vector2(115,24),Color("f5cf92"),6)
		draw_string(font,sign+Vector2(7,18),"FILE : %d CLIENTS" % sim.queues[index].size(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,INK)
	if not sim.queues[index].is_empty():
		var customer = sim.customers.filter(func(c): return c.id == sim.queues[index][0])
		if not customer.is_empty() and customer[0].state == BricoCustomer.State.PAYING:
			var at := p(Vector2(x,750))
			round_rect(at+Vector2(0,-12),Vector2(100,7),Color("acc4b8"),3)
			round_rect(at+Vector2(0,-12),Vector2(100*clampf(customer[0].timer/sim.checkout_time(index),0,1),7),ORANGE,3)
func _draw():
	if sim == null: return
	# Original three-quarter artwork; coordinates also drive navigation and selection.
	# Floor tiles are cached in BricoStoreFloor, drawn behind this node.
	var top := 300 if sim.expansion == 0 else (140 if sim.expansion == 1 else 0)
	# Back and left walls with visible height, panels, high windows and a brand stripe.
	var walls := sim.decor.has("walls")
	box(Rect2(0,top,600,12),Color("e3b98d") if walls else Color("96bbad"),54)
	var seams := PackedVector2Array()
	for x in range(50,600,50):
		var base := p(Vector2(x,top+12)); seams.append(base); seams.append(base+Vector2(0,-54))
	draw_multiline(seams,Color("c99d72") if walls else Color("7fa597"),1.5)
	for x in range(40,560,130):
		var w := p(Vector2(x,top+12))
		draw_rect(Rect2(w+Vector2(0,-46),Vector2(70,14)),Color("cfe6ea"))
		draw_line(w+Vector2(0,-46),w+Vector2(70,-46),Color(1,1,1,.8),2)
	draw_line(p(Vector2(0,top+12))+Vector2(0,-20),p(Vector2(600,top+12))+Vector2(0,-20),ORANGE,4)
	box(Rect2(0,top,12,900-top),Color("efd3b1") if walls else Color("c5d3bd"),48)
	var side := PackedVector2Array()
	for y in range(top+60,900,60):
		var base := p(Vector2(12,y)); side.append(base); side.append(base+Vector2(0,-48))
	draw_multiline(side,Color("a9b9a2"),1.5)
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
	if opening_fx.has("wing"):
		construction_effect(Rect2(160,140 if sim.expansion == 1 else 0,360,140),opening_fx.wing)
	decorations(top)
	for f in sim.cfg.families:
		if f.expansion <= sim.expansion: shelf(f)
	for index in range(2): cashier(index)
	# Agents are sorted by depth, without scanning scene nodes.
	var agents: Array = sim.workers.duplicate()
	agents.append_array(sim.customers)
	agents.sort_custom(func(a,b): return a.pos.y < b.pos.y)
	for a in agents: character(a,a is BricoWorker)
	storefront()
	neon_signs()
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
func storefront():
	# Original boutique facade: cutaway shopfront, illuminated glazing and timber canopy.
	floor_rect(Rect2(16,904,568,54),Color("d7d4c1"))
	for x in [20,390]:
		box(Rect2(x,900,190,14),INK,65)
		var at := p(Vector2(x+13,914))+Vector2(0,-57)
		round_rect(at,Vector2(164,43),Color("86bfb8"),5)
		round_rect(at+Vector2(4,4),Vector2(156,34),Color("bee0d5"),3)
		for dx in [54,110]: draw_line(at+Vector2(dx,1),at+Vector2(dx,42),INK,4,true)
		for dx in [14,70,126]: draw_line(at+Vector2(dx,7),at+Vector2(dx+15,28),Color(1,1,1,.55),4,true)
		box(Rect2(x,914,190,5),Color("d3a46f"),12)
	for x in [219,376]:
		box(Rect2(x,890,10,27),Color("2c6d76"),84)
		draw_line(p(Vector2(x+5,917))+Vector2(0,-76),p(Vector2(x+5,917))+Vector2(0,-19),Color("8eb8b0"),2,true)
	floor_rect(Rect2(239,873,122,34),Color("73a68d"))
	text_at(Vector2(249,895),"BIENVENUE",15,CREAM)
	for i in range(6):
		box(Rect2(216+i*28,915,28,34),ORANGE if i%2 == 0 else CREAM,82)
		var edge := p(Vector2(216+i*28,949))+Vector2(0,-82)
		round_rect(edge,Vector2(28,8),ORANGE.darkened(.07) if i%2 == 0 else CREAM.darkened(.05),3)
	var sign := p(Vector2(190,916))+Vector2(0,-125)
	round_rect(sign+Vector2(3,4),Vector2(222,39),Color(0,.1,.12,.2),11)
	round_rect(sign,Vector2(222,39),INK,11)
	draw_string(font,sign+Vector2(12,28),"BRICO EMPIRE",HORIZONTAL_ALIGNMENT_CENTER,198,27,CREAM)
	# Permanent facade planters and a basket stack, distinct from purchased interior plants.
	for x in [35,550]:
		box(Rect2(x,933,26,20),Color("c88359"),18)
		for dx in [5,13,21]:
			var leaf := p(Vector2(x+dx,940))+Vector2(0,-29)
			ellipse_shape(leaf,Vector2(8,12),Color("6b9a68"))
	box(Rect2(412,870,33,28),Color("d58b57"),18)
	for i in range(3):
		var basket := p(Vector2(417,883))+Vector2(0,-21-i*6)
		round_rect(basket,Vector2(24,9),Color("6ea79f"),3)
		draw_line(basket+Vector2(4,2),basket+Vector2(20,2),CREAM,1.5,true)
func daylight_color() -> Color:
	# Soft cycle: day 7h-18h, golden dusk, blue night; reduced effects keep a lighter night.
	var h := sim.day_hour()
	var night := Color(.76,.81,.96) if not sim.settings.reduced_effects else Color(.85,.88,.96)
	var dusk := Color(1,.88,.76)
	if h >= 7 and h < 18: return Color.WHITE
	if h >= 18 and h < 20: return Color.WHITE.lerp(dusk,(h-18)/2)
	if h >= 20 and h < 21: return dusk.lerp(night,h-20)
	if h >= 6 and h < 7: return night.lerp(Color.WHITE,h-6)
	return night
func recenter():
	var top := 125.0 if sim == null or sim.expansion == 0 else (0.0 if sim.expansion == 1 else -75.0)
	var focus := Rect2(Vector2(0,top),Vector2(765,905-top))
	camera_zoom = minf(PLAY_RECT.size.x/(focus.size.x+30),PLAY_RECT.size.y/(focus.size.y+30))
	camera_offset = PLAY_RECT.get_center()-focus.get_center()*camera_zoom
	clamp_camera()
func zoom_at(factor: float, at: Vector2):
	var before := (at-camera_offset)/camera_zoom
	camera_zoom = clampf(camera_zoom*factor,.50,1.3)
	camera_offset = at-before*camera_zoom
	clamp_camera()
func clamp_camera():
	# A finite projected rectangle. At minimum zoom a narrow dimension is centred.
	var bounds := projected_map_bounds()
	for axis in range(2):
		var low: float = PLAY_RECT.end[axis]-bounds.end[axis]*camera_zoom
		var high: float = PLAY_RECT.position[axis]-bounds.position[axis]*camera_zoom
		camera_offset[axis] = clampf(camera_offset[axis],low,high) if low <= high else PLAY_RECT.get_center()[axis]-bounds.get_center()[axis]*camera_zoom
func projected_map_bounds() -> Rect2:
	var bounds := Rect2(p(MAP_RECT.position),Vector2.ZERO)
	for corner in [MAP_RECT.position+Vector2(MAP_RECT.size.x,0),MAP_RECT.end,MAP_RECT.position+Vector2(0,MAP_RECT.size.y)]:
		bounds = bounds.expand(p(corner))
	return bounds
func _input(event: InputEvent):
	# GUI can consume the release before _unhandled_input: clear pending world gestures.
	if ui_blocks_point.is_valid() and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion):
		if ui_blocks_point.call(event.position): cancel_gestures()
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
	# Touch-to-mouse is necessary for Controls; only genuine touch drives the world.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if ui_blocks_point.is_valid() and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion):
		if ui_blocks_point.call(event.position): return
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
			if fingers.has(event.index) and fingers.size() == 1 and not dragged and not event.canceled: tap(event.position)
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
	pinch_distance = 0
	dragged = true
