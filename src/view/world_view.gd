class_name BricoWorldView
extends Node2D
# Neighbourhood around the store, in the same three-quarter projection.
# The static layer draws once behind the store; the animated layer redraws traffic,
# passers-by, cloud shadows and night lights every frame above it.
var sim: BricoSimulation
var animated := false
var phase := 0.0
var font := ThemeDB.fallback_font
var trees: Array = []
var patches: Array = []
var cars: Array = []
var walkers: Array = []
var clouds: Array = []
const WORLD := Rect2(-2600,-2300,5800,5800)
const SPAN_X := Vector2(-1700,2300)
const INK := Color("174956")
const CREAM := Color("fff4df")
const GRASS := Color("8dbb74")
const ASPHALT := Color("50575b")
const SIDEWALK := Color("d8d1bf")
const ROAD_Y := 1150.0
const LANES := [1185.0,1235.0]
const WALKWAYS := [1136.0,1276.0]
const CAR_COLORS := ["d9634c","3f7fb5","f2c14e","eeeeee","6c9a5b","9a6bb0","2f3b45"]
const SHIRTS := ["d98771","8d9abb","7eaf8e","d2ac66","ae8bbb","6ea5ac"]
# Areas kept free of random trees: store and parking, road band, house row, park pond, café.
const FREE := [Rect2(-110,-110,820,1240),Rect2(-2600,1080,5800,250),Rect2(-2600,1320,5800,190),Rect2(-640,330,400,300),Rect2(730,380,420,320),Rect2(760,760,300,220)]
func setup(simulation: BricoSimulation, is_animated: bool):
	sim = simulation
	animated = is_animated
	var rng := RandomNumberGenerator.new(); rng.seed = 4242
	if not animated:
		show_behind_parent = true
		for i in range(420):
			var at := Vector2(rng.randf_range(-1700,2300),rng.randf_range(-1500,2500))
			if is_free(at): trees.append({"p":at,"s":rng.randf_range(.75,1.35),"v":rng.randi_range(0,2)})
		trees.sort_custom(func(a,b): return a.p.y < b.p.y)
		for i in range(70):
			var at := Vector2(rng.randf_range(-1700,2300),rng.randf_range(-1500,2500))
			if is_free(at): patches.append({"p":at,"r":Vector2(rng.randf_range(50,130),rng.randf_range(25,60))})
	else:
		for i in range(9):
			cars.append({"x":rng.randf_range(SPAN_X.x,SPAN_X.y),"lane":i % 2,"speed":rng.randf_range(90,150),"color":Color(CAR_COLORS[i % CAR_COLORS.size()])})
		for i in range(10):
			walkers.append({"x":rng.randf_range(SPAN_X.x,SPAN_X.y),"side":i % 2,"speed":rng.randf_range(22,38)*(1 if i % 3 else -1),"shirt":Color(SHIRTS[i % SHIRTS.size()]),"id":i})
		for i in range(4):
			clouds.append({"p":Vector2(rng.randf_range(SPAN_X.x,SPAN_X.y),rng.randf_range(-1200,2200)),"r":rng.randf_range(170,300)})
func is_free(at: Vector2) -> bool:
	for r in FREE:
		if r.has_point(at): return false
	return true
func _process(dt: float):
	if not animated: return
	phase += minf(dt,0.1)
	var span := SPAN_X.y - SPAN_X.x
	for c in cars:
		c.x = wrapf(c.x + c.speed*dt*(1 if c.lane == 0 else -1),SPAN_X.x,SPAN_X.y)
		# Slow down at the pedestrian crossing in front of the store.
		var to_cross: float = (300 - c.x)*(1 if c.lane == 0 else -1)
		c.speed = lerpf(c.speed,45.0 if to_cross > 0 and to_cross < 140 else 125.0,dt*0.8)
	for w in walkers: w.x = wrapf(w.x + w.speed*dt,SPAN_X.x,SPAN_X.y)
	if not sim.settings.reduced_effects:
		for c in clouds: c.p.x = wrapf(c.p.x + 18*dt,SPAN_X.x-400,SPAN_X.x-400+span+800)
	queue_redraw()
# ---------- Projection helpers (same as the store view) ----------
func p(v: Vector2) -> Vector2:
	return Vector2(v.x + v.y * 0.17,v.y * 0.9)
func poly(points: Array, color: Color):
	var packed := PackedVector2Array()
	for point in points: packed.append(p(point))
	draw_colored_polygon(packed,color)
func floor_rect(r: Rect2, color: Color):
	poly([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)],color)
func box(r: Rect2, color: Color, height := 24.0, base := 0.0):
	var lift := Vector2(0,-base)
	var a := p(r.position)+lift
	var b := p(r.position+Vector2(r.size.x,0))+lift
	var c := p(r.end)+lift
	var d := p(r.position+Vector2(0,r.size.y))+lift
	var h := Vector2(0,-height)
	draw_colored_polygon(PackedVector2Array([d,c,c+h,d+h]),color.darkened(.12))
	draw_colored_polygon(PackedVector2Array([b,c,c+h,b+h]),color.darkened(.25))
	draw_colored_polygon(PackedVector2Array([a+h,b+h,c+h,d+h]),color)
func ellipse(center: Vector2, radii: Vector2, color: Color):
	var points := PackedVector2Array()
	for i in range(28): points.append(center+Vector2(cos(i*TAU/28)*radii.x,sin(i*TAU/28)*radii.y))
	draw_colored_polygon(points,color)
func lamp_points() -> Array:
	var points: Array = []
	for x in range(-1600,2300,230):
		points.append(Vector2(x,1122))
		points.append(Vector2(x+115,1292))
	return points
func is_night() -> bool:
	var h := sim.day_hour()
	return h >= 19.5 or h < 6.5
# ---------- Static layer ----------
func _draw():
	if sim == null: return
	if animated: draw_animated()
	else: draw_static()
func draw_static():
	floor_rect(WORLD,GRASS)
	for patch in patches: ellipse(p(patch.p),patch.r,GRASS.darkened(.06))
	# Gravel ring hugging the store walls.
	floor_rect(Rect2(-70,-70,740,1050),Color("b9b39f"))
	# Customer parking with stalls and a few parked cars.
	floor_rect(Rect2(-40,975,680,140),Color("626a6e"))
	for i in range(12):
		var x := -10+i*55
		draw_line(p(Vector2(x,985)),p(Vector2(x,1045)),Color(1,1,1,.7),2,true)
	for i in [0,2,3,6,8,10]:
		car(Vector2(17+i*55,1015),Color(CAR_COLORS[(i*3) % CAR_COLORS.size()]),0,true)
	floor_rect(Rect2(250,940,100,35),Color("b9b39f"))
	# Sidewalks, road, lane markings and pedestrian crossing.
	floor_rect(Rect2(-2600,1115,5800,35),SIDEWALK)
	floor_rect(Rect2(-2600,ROAD_Y,5800,110),ASPHALT)
	floor_rect(Rect2(-2600,1260,5800,35),SIDEWALK)
	for x in range(-2600,3200,90):
		if x > 230 and x < 370: continue
		draw_line(p(Vector2(x,1208)),p(Vector2(x+45,1208)),Color("f1e8c8"),3,true)
	for i in range(6):
		floor_rect(Rect2(256+i*16,ROAD_Y+6,9,98),Color(1,1,1,.85))
	# Houses across the road.
	var walls := [Color("f1d9b5"),Color("d8e2e6"),Color("f0c6a8"),Color("e2e8cf"),Color("f5e6c4")]
	var roofs := [Color("c25b48"),Color("5f7f9a"),Color("8b5a44"),Color("4f7a5c")]
	var i := 0
	for x in range(-1700,2300,240):
		house(Rect2(x,1360,170,110),walls[i % walls.size()],roofs[i % roofs.size()],i)
		i += 1
	# Park with a pond and benches on the left.
	floor_rect(Rect2(-700,300,520,360),GRASS.lightened(.06))
	ellipse(p(Vector2(-440,480)),Vector2(150,72),Color("6aa9c9"))
	ellipse(p(Vector2(-450,472)),Vector2(110,48),Color("86c0da"))
	for b in [Vector2(-620,380),Vector2(-300,600)]:
		box(Rect2(b.x,b.y,50,12),Color("a8774f"),10)
	draw_line(p(Vector2(-180,640)),p(Vector2(-70,980)),Color("c9c0a6"),16,true)
	text_at(Vector2(-560,690),"PARC DES MÉSANGES",17,INK)
	# Neighbouring café and bakery on the right.
	cafe(Rect2(770,430,250,170),Color("e8d2b0"),"CAFÉ DU COIN",Color("d9634c"))
	cafe(Rect2(800,790,220,150),Color("f3e3c8"),"BOULANGERIE",Color("3f7fb5"))
	for at in lamp_points(): lamp(at)
	for t in trees: tree(t.p,t.s,t.v)
func text_at(at: Vector2, text: String, size: int, color: Color):
	draw_string(font,p(at),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func tree(at: Vector2, s: float, variant: int):
	var q := p(at)
	ellipse(q+Vector2(6,3),Vector2(26,9)*s,Color(0,0,0,.13))
	draw_line(q,q+Vector2(0,-26*s),Color("7a5638"),6*s,true)
	var greens: Array = [[Color("4e8a4b"),Color("66a35a"),Color("84bb6c")],[Color("3f7a53"),Color("559562"),Color("74b07a")],[Color("6b8f3d"),Color("86a94b"),Color("a3c266")]][variant]
	draw_circle(q+Vector2(0,-40*s),24*s,greens[0])
	draw_circle(q+Vector2(-6*s,-46*s),18*s,greens[1])
	draw_circle(q+Vector2(-9*s,-51*s),8*s,greens[2])
func house(r: Rect2, wall: Color, roof: Color, index: int):
	ellipse(p(r.get_center()+Vector2(15,20)),Vector2(110,40),Color(0,0,0,.1))
	box(r,wall,52)
	box(Rect2(r.position-Vector2(8,8),r.size+Vector2(16,16)),roof,16,52)
	# Door and windows on the front face.
	var d := p(r.position+Vector2(0,r.size.y))
	var c := p(r.end)
	for k in [0.18,0.72]:
		var w := d.lerp(c,k)
		draw_rect(Rect2(w+Vector2(0,-40),Vector2(26,18)),Color("b8d8e6"))
		draw_rect(Rect2(w+Vector2(0,-40),Vector2(26,18)),Color(1,1,1,.8),false,2)
	var door := d.lerp(c,0.46)
	draw_rect(Rect2(door+Vector2(0,-34),Vector2(18,34)),roof.darkened(.2))
	# Garden hedge in front of every other house.
	if index % 2 == 0: box(Rect2(r.position.x+10,r.end.y+12,150,10),Color("5f9a55"),12)
func cafe(r: Rect2, wall: Color, title: String, stripe: Color):
	ellipse(p(r.get_center()+Vector2(20,25)),Vector2(150,50),Color(0,0,0,.1))
	box(r,wall,62)
	box(Rect2(r.position-Vector2(6,6),r.size+Vector2(12,12)),Color("8e8a80"),8,62)
	var d := p(r.position+Vector2(0,r.size.y))
	var c := p(r.end)
	for k in range(8):
		var a := d.lerp(c,k/8.0)
		var b := d.lerp(c,(k+1)/8.0)
		draw_colored_polygon(PackedVector2Array([a+Vector2(0,-44),b+Vector2(0,-44),b+Vector2(4,-30),a+Vector2(4,-30)]),stripe if k % 2 == 0 else CREAM)
	draw_rect(Rect2(d.lerp(c,.12)+Vector2(0,-26),Vector2((c.x-d.x)*.5,22)),Color("b8d8e6"))
	draw_string(font,d+Vector2(8,-50),title,HORIZONTAL_ALIGNMENT_LEFT,-1,15,INK)
	# Terrace tables.
	for k in range(3):
		var t := p(r.position+Vector2(30+k*70,r.size.y+35))
		ellipse(t,Vector2(14,6),Color("efe6d4"))
		draw_line(t,t+Vector2(0,10),Color("6d6a63"),3)
func lamp(at: Vector2):
	var q := p(at)
	draw_line(q,q+Vector2(0,-62),Color("3d4a50"),4,true)
	draw_line(q+Vector2(0,-62),q+Vector2(10,-66),Color("3d4a50"),4,true)
	draw_circle(q+Vector2(12,-64),5,Color("e9e2c8"))
func car(at: Vector2, color: Color, facing: int, parked := false):
	var q := p(at)
	ellipse(q+Vector2(4,6),Vector2(34,12) if not parked else Vector2(18,22),Color(0,0,0,.18))
	if parked:
		# Nose towards the store: footprint is taller than wide.
		box(Rect2(at.x-15,at.y-28,30,56),color,13,4)
		box(Rect2(at.x-12,at.y-12,24,26),Color("a9c7d0"),11,17)
		box(Rect2(at.x-12,at.y-12,24,26),color.lightened(.1),3,28)
		return
	box(Rect2(at.x-32,at.y-13,64,26),color,13,4)
	var shift := -5 if facing > 0 else 5
	box(Rect2(at.x-14+shift,at.y-11,30,22),Color("a9c7d0"),11,17)
	box(Rect2(at.x-14+shift,at.y-11,30,22),color.lightened(.1),3,28)
	for wx in [-20,20]:
		draw_circle(p(at+Vector2(wx,13))+Vector2(0,-2),5,Color("23292c"))
# ---------- Animated layer ----------
func draw_animated():
	var night := is_night()
	for w in walkers:
		if w.side == 0: walker(w)
	for c in cars:
		if c.lane == 0: moving_car(c,night)
	for c in cars:
		if c.lane == 1: moving_car(c,night)
	for w in walkers:
		if w.side == 1: walker(w)
	if night:
		for at in lamp_points():
			var q := p(at)
			ellipse(q+Vector2(10,0),Vector2(80,30),Color(1,.88,.55,.26))
			draw_circle(q+Vector2(12,-64),7,Color(1,.96,.75))
			draw_circle(q+Vector2(12,-64),18,Color(1,.9,.6,.3))
		# Lit windows across the road.
		var i := 0
		for x in range(-1700,2300,240):
			var d := p(Vector2(x,1470))
			var c := p(Vector2(x+170,1470))
			for k in [0.18,0.72]:
				if (i + int(k*10)) % 3 != 0: draw_rect(Rect2(d.lerp(c,k)+Vector2(0,-40),Vector2(26,18)),Color(1,.85,.45,.9))
			i += 1
	if not sim.settings.reduced_effects:
		for c in clouds: ellipse(p(c.p),Vector2(c.r,c.r*.42),Color(0.05,.12,.15,.07))
func moving_car(c: Dictionary, night: bool):
	var facing := 1 if c.lane == 0 else -1
	var at := Vector2(c.x,LANES[c.lane])
	car(at,c.color,facing)
	if night:
		var front := p(at+Vector2(33*facing,0))+Vector2(0,-10)
		draw_circle(front,4,Color(1,.95,.7))
		draw_colored_polygon(PackedVector2Array([front,front+Vector2(90*facing,-16),front+Vector2(90*facing,18)]),Color(1,.95,.7,.18))
func walker(w: Dictionary):
	var q := p(Vector2(w.x,WALKWAYS[w.side]))
	var stride := sin(phase*10+w.id)*4
	ellipse(q+Vector2(0,2),Vector2(10,4),Color(0,0,0,.15))
	draw_line(q+Vector2(-3,-9),q+Vector2(-4+stride,1),INK,4,true)
	draw_line(q+Vector2(3,-9),q+Vector2(4-stride,1),INK,4,true)
	draw_rect(Rect2(q+Vector2(-7,-27),Vector2(14,19)),w.shirt)
	draw_line(q+Vector2(-8,-23),q+Vector2(-10-stride,-13),Color("e3b088"),3,true)
	draw_line(q+Vector2(8,-23),q+Vector2(10+stride,-13),Color("e3b088"),3,true)
	draw_circle(q+Vector2(0,-33),7,[Color("efbb8c"),Color("bc855f"),Color("8c5b44")][w.id % 3])
