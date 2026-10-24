class_name BricoStore3DView
extends Node3D
signal selected(kind: String, id: String)
var sim: BricoSimulation
var models := BricoModels3D.new()
var camera: Camera3D
var scenery: Node3D
var population: Node3D
var figures := {}
var shelves := {}
var feedback: Array = []
var focus := Vector3(3,.2,5.6)
var zoom := 8.4
var fingers := {}
var held := false
var dragged := false
var press := Vector2.ZERO
var last_pointer := Vector2.ZERO
var pinch_distance := 0.0
var ui_blocks_point: Callable
var debug_states := false
var selected_kind := ""
var selected_id := ""
var selection_marker: Node3D
var store_revision := 0
var sun: DirectionalLight3D
var light_mode := false
var actor_batches := {}
var actor_meshes: Array = []
var low_applied := true
var cashiers: Array = []
const MIN_ZOOM := 4.5
const MAX_ZOOM := 11.5
const MAP_BOUNDS := Rect2(-5,-5,16,23)
const CAMERA_ARM := Vector3(4.0,13.0,17.0)
func setup(simulation: BricoSimulation):
	sim = simulation
func _ready():
	var environment := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("73dafa")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = .65
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env; add_child(environment)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55,-32,0); sun.light_color = Color.WHITE; sun.light_energy = .4
	sun.shadow_enabled = false; sun.directional_shadow_max_distance = 35; sun.shadow_bias = .04
	add_child(sun)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.keep_aspect = Camera3D.KEEP_WIDTH; camera.near = .1; camera.far = 70
	add_child(camera); camera.make_current()
	population = Node3D.new(); add_child(population)
	rebuild(); recenter()
	sim.purchased.connect(purchased)
	sim.sale.connect(show_payment)
func show_payment(amount: int, at: Vector2):
	if feedback.size() > 12: return
	var origin := Vector3(at.x/100,1.05,at.y/100)
	var count := 1 if sim.settings.reduced_effects else 3
	for i in range(count):
		var bill := Sprite3D.new(); bill.texture = preload("res://assets/ui/banknote.svg"); bill.pixel_size = .006; bill.billboard = BaseMaterial3D.BILLBOARD_ENABLED; bill.shaded = false; bill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bill.position = origin+Vector3((i-1)*.10,i*.06,0); add_child(bill)
		feedback.append({"node":bill,"time":0.0,"bill":true,"origin":bill.position,"spread":(i-1)*.24})
	var label := models.label(self,origin+Vector3(0,.34,0),"+%d" % amount,34,Color("008746"))
	feedback.append({"node":label,"time":0.0})
func purchased(action: String, target: String):
	rebuild()
	if action == "expand" or action == "franchise": recenter()
	if not sim.settings.reduced_effects:
		var at := Vector3(3,.7,4.8)
		if shelves.has(target): at = shelves[target].position+Vector3(.7,.9,.5)
		var note := models.label(self,at,"OUVERTURE !" if action in ["unlock","expand"] else "AMÉLIORÉ",30,models.TEAL)
		feedback.append({"node":note,"time":0.0})
func rebuild():
	if is_instance_valid(scenery): remove_child(scenery); scenery.queue_free()
	scenery = Node3D.new(); add_child(scenery); shelves.clear(); cashiers.clear(); store_revision += 1
	var m := models
	m.block(scenery,Vector3(3,-.15,6.5),Vector3(16,.2,23),Color("45bc32"),.12)
	m.block(scenery,Vector3(3,-.025,4.6),Vector3(6.4,.12,9.8),Color("e2eaf0"),.08)
	var top := 3.0 if sim.expansion == 0 else (1.4 if sim.expansion == 1 else 0.0)
	# Large batched tiled surface: each tile is one bevelled slab with shared material.
	for y in range(int(top*10),90,6):
		for x in range(10):
			m.block(scenery,Vector3(x*.6+.3,.045,y*.1+.3),Vector3(.59,.05,.59),Color("fffdf1") if (x+y/6)%2 == 0 else Color("f3f0dd"),.008)
	m.block(scenery,Vector3(3.25,.076,(top+8.9)/2),Vector3(.42,.008,8.9-top),Color("b1ee43"),.003)
	m.block(scenery,Vector3(3,.38,top),Vector3(6.1,.75,.12),Color("f9faf3"),.04)
	m.block(scenery,Vector3(3,.65,top+.075),Vector3(6.1,.055,.015),m.ORANGE,.006)
	for x in [.7,2.2,3.7,5.2]:
		m.block(scenery,Vector3(x,.48,top+.071),Vector3(.9,.24,.018),Color("34c5f2"),.015)
	m.block(scenery,Vector3(.03,.20,(top+9)/2),Vector3(.12,.4,9-top),Color("fff8e9"),.03)
	if sim.expansion < 2:
		var closed_top := 1.4 if sim.expansion == 0 else 0.0
		m.block(scenery,Vector3(3,.07,(closed_top+top)/2),Vector3(5.8,.1,top-closed_top),Color("6bc653"),.04)
		for x in range(6):
			m.block(scenery,Vector3(.5+x,.5,top-.12),Vector3(.07,1,.07),m.TEAL,.01)
			m.block(scenery,Vector3(.5+x,.34,top-.12),Vector3(.95,.055,.07),m.ORANGE,.01)
			m.block(scenery,Vector3(.5+x,.62,top-.12),Vector3(.95,.055,.07),m.CREAM,.01)
		m.label(scenery,Vector3(3,.9,top-.15),"NOUVELLE AILE" if sim.expansion == 0 else "GRAND DÉPÔT",40,m.TEAL)
		m.pick(scenery,Vector3(3,.3,(closed_top+top)/2),Vector3(5.8,.6,top-closed_top),"expand","")
	reserve_and_dock()
	for f in sim.cfg.families:
		if f.expansion <= sim.expansion: shelf(f)
	for i in range(2): checkout(i)
	facade(); neighbourhood()
	selection_marker = m.node(scenery)
	var ring := TorusMesh.new(); ring.inner_radius = .28; ring.outer_radius = .31; ring.rings = 24; ring.ring_segments = 6
	m.mesh(selection_marker,ring,Vector3(0,.1,0),m.ORANGE); selection_marker.visible = false
	update_stock()
	models.batch_static(scenery)
func reserve_and_dock():
	var m := models
	m.block(scenery,Vector3(.76,.075,3.35),Vector3(1.12,.04,.9),Color("d6c6a1"))
	for x in [.35,.7,1.05]:
		m.block(scenery,Vector3(x,.14,3.22),Vector3(.28,.13,.7),Color("a2835e"),.008)
		m.carton(scenery,Vector3(x,.38,3.18),Vector3(.27,.34,.28))
	m.carton(scenery,Vector3(.7,.65,3.18))
	m.label(scenery,Vector3(.73,.98,3.18),"RÉSERVE",30,m.TEAL)
	m.pick(scenery,Vector3(.78,.4,3.4),Vector3(1.2,.9,1.1),"reserve","")
	m.block(scenery,Vector3(.7,.08,6.3),Vector3(1.1,.04,1),Color("c9d1b5"))
	for x in [.3,.65,1.0]:
		m.block(scenery,Vector3(x,.11,6.75),Vector3(.18,.02,.15),m.ORANGE,.004)
		m.carton(scenery,Vector3(x,.25,6.3))
	m.label(scenery,Vector3(.7,.8,6.3),"LIVRAISON",26,m.TEAL)
	m.pick(scenery,Vector3(.7,.4,6.3),Vector3(1.2,.8,1.1),"reserve","")
	if sim.expansion >= 1:
		m.block(scenery,Vector3(.8,.08,2.05),Vector3(1.2,.08,.7),Color("c1aa82"))
		for x in [.45,.8,1.15]: m.carton(scenery,Vector3(x,.29,2.05))
	if sim.expansion == 2:
		for x in [.45,1.05,5.5]:
			m.carton(scenery,Vector3(x,.22,.65),Vector3(.4,.35,.45))
			m.carton(scenery,Vector3(x,.55,.65))
func shelf(f: Dictionary):
	var m := models
	var root := m.node(scenery,Vector3(f.rect[0]/100,0,f.rect[1]/100)); shelves[f.id] = root
	root.set_meta("family",f.id); root.set_meta("stock_bin",-1)
	var width: float = f.rect[2]/100.0; var depth: float = f.rect[3]/100.0
	m.pick(root,Vector3(width/2,.42,depth/2),Vector3(width+.08,.95,depth+.08),"shelf",f.id)
	if not sim.opened[f.id]:
		m.block(root,Vector3(width/2,.08,depth/2),Vector3(width,.08,depth),Color("d5ebf0"))
		m.carton(root,Vector3(width/2,.3,depth/2),Vector3(.6,.45,.45))
		for i in range(5): m.block(root,Vector3(.15+i*.27,.2,depth+.012),Vector3(.17,.08,.035),m.ORANGE,.008)
		m.block(root,Vector3(width/2,.75,depth/2),Vector3(width*.9,.23,.1),m.TEAL,.03)
		m.label(root,Vector3(width/2,.76,depth/2+.07),"+ "+f.name,30); return
	var level: int = maxi(sim.levels[f.id].capacity,sim.levels[f.id].value)
	var color := m.TEAL if level < 3 else Color("00668b")
	var accent: Color = {"tools":Color("ff9821"),"paint":Color("ef498c"),"garden":Color("48bd31")}.get(f.id,m.ORANGE)
	var height := .72 if level < 3 else .94
	m.block(root,Vector3(width/2,.09,depth/2),Vector3(width+.12,.04,depth+.14),accent.lerp(m.CREAM,.52))
	for x in [.04,width-.04]:
		for z in [.05,depth-.05]: m.block(root,Vector3(x,height/2,z),Vector3(.065,height,.065),color,.014)
	for y in [.18,.48] + ([.74] if level >= 3 else []):
		m.block(root,Vector3(width/2,y,depth/2),Vector3(width,.065,depth),color,.02)
		m.block(root,Vector3(width/2,y+.02,depth+.005),Vector3(width,.035,.025),accent,.005)
	m.block(root,Vector3(width/2,.49,.07),Vector3(width-.09,.45,.035),Color("bd9b70") if f.id == "tools" else color,.008)
	if f.id == "paint":
		for i in range(7): m.block(root,Vector3(.15+i*.18,.64,.095),Vector3(.13,.12,.015),Color.from_hsv(i*.11,.72,.98),.008)
	elif f.id == "garden":
		for x in [.15,.45,.75,1.05,1.3]: m.block(root,Vector3(x,.7,.06),Vector3(.025,.35,.025),Color("b6a070"),.003)
		for x in [.1,width-.1]: m.plant(root,Vector3(x,.55,.13))
	elif f.id == "tools":
		for x in range(8):
			for y in range(2): m.sphere(root,Vector3(.15+x*.15,.57+y*.1,.094),Vector3(.018,.018,.008),Color("826d54"))
	if level >= 5:
		m.block(root,Vector3(width/2,height+.04,depth/2),Vector3(width+.08,.055,depth+.08),m.ORANGE,.02)
	m.block(root,Vector3(width/2,height+.18,.06),Vector3(width+.07,.25,.11),color,.045)
	m.block(root,Vector3(width/2,height+.18,.125),Vector3(width-.02,.18,.018),accent,.028)
	m.label(root,Vector3(width/2,height+.18,.15),f.name,34)
	# Orange kick plate and white feet add a finished toy-like silhouette.
	m.block(root,Vector3(width/2,.13,depth+.015),Vector3(width,.09,.04),accent,.012)
	for x in [.06,width-.06]: m.block(root,Vector3(x,.09,depth-.05),Vector3(.13,.14,.14),m.CREAM,.018)
	var stock_label := m.label(root,Vector3(width/2,.14,depth+.12),"",24,m.TEAL); stock_label.name = "StockLabel"
	var products := m.node(root); products.name = "Products"
func update_stock():
	for f in sim.cfg.families:
		if not shelves.has(f.id) or not sim.opened[f.id]: continue
		var root: Node3D = shelves[f.id]
		var count: int = sim.inventory.shelves[f.id]
		var bin := ceili(8.0*count/sim.capacity(f.id))
		var text := "%d / %d" % [count,sim.capacity(f.id)]
		if count <= 2: text += " · VIDE" if count == 0 else " · STOCK BAS"
		root.get_node("StockLabel").text = text
		if root.get_meta("stock_bin") == bin: continue
		root.set_meta("stock_bin",bin)
		var products := root.get_node("Products")
		for child in products.get_children(): products.remove_child(child); child.queue_free()
		for i in range(bin):
			var y := .225 if i < 4 else .525
			models.product(products,f.id,Vector3(.2+(i%4)*.33,y,.29 if i < 4 else .45),i,Color(f.color).lightened((i%3)*.06))
		models.batch_static(products)
func checkout(index: int):
	var m := models; var x := 1.5 if index == 0 else 3.7
	if index >= sim.checkouts:
		m.block(scenery,Vector3(x+.5,.08,7.87),Vector3(1,.04,.65),Color("c9cdb7"))
		m.label(scenery,Vector3(x+.5,.4,7.87),"+ CAISSE 2",28,m.TEAL)
		m.pick(scenery,Vector3(x+.5,.4,7.9),Vector3(1.1,.8,.8),"checkout",str(index)); return
	var c := m.node(scenery,Vector3(x,0,7.6))
	m.block(c,Vector3(.5,.28,.27),Vector3(1,.54,.55),m.TEAL,.06)
	m.block(c,Vector3(.32,.565,.26),Vector3(.55,.05,.48),Color("235477"),.015)
	for z in [.09,.19,.29,.39]: m.block(c,Vector3(.32,.595,z),Vector3(.49,.012,.012),Color("6b9db1"),.002)
	m.block(c,Vector3(.76,.62,.3),Vector3(.04,.18,.04),m.TEAL,.006)
	m.block(c,Vector3(.76,.73,.3),Vector3(.25,.17,.055),Color("193c49"),.02)
	m.block(c,Vector3(.76,.73,.335),Vector3(.20,.12,.008),Color("6fea9a"),.005)
	m.pick(c,Vector3(.5,.4,.25),Vector3(1.1,.9,.7),"checkout",str(index))
	m.block(c,Vector3(.5,.35,.56),Vector3(.9,.21,.035),m.ORANGE,.025)
	m.label(c,Vector3(.5,.35,.60),"CAISSE %d" % (index+1),25)
	m.block(c,Vector3(.92,.59,.3),Vector3(.10,.06,.16),Color("123d62"),.012)
	m.block(c,Vector3(.92,.625,.3),Vector3(.07,.008,.10),Color("67f0af"),.005)
	# Dedicated stationary cashier, same articulated silhouette as the workforce.
	var dummy := BricoWorker.new(3+index); dummy.pos = Vector2((x+.6)*100,833)
	var cashier := BricoAgent3D.new(); scenery.add_child(cashier); cashier.setup(dummy,true,m); cashier.position = Vector3(x+.6,0,8.33); cashier.rotation.y = PI; cashier.caption.visible = false
	cashiers.append({"view":cashier,"index":index})
	for z in [6.2,6.65,7.1]: m.block(scenery,Vector3(x+.5,.09,z),Vector3(.28,.009,.04),Color("abc0a7"),.004)
func facade():
	var m := models
	for x in [.2,3.9]:
		m.block(scenery,Vector3(x+.95,.28,9.07),Vector3(1.9,.56,.16),m.TEAL,.055)
		m.block(scenery,Vector3(x+.95,.38,9.17),Vector3(1.62,.26,.035),Color("2ec9f4"),.035)
		m.block(scenery,Vector3(x+.95,.10,9.18),Vector3(1.86,.09,.04),m.ORANGE,.012)
		for dx in [.53,1.12]: m.block(scenery,Vector3(x+dx,.38,9.20),Vector3(.035,.29,.035),m.TEAL,.005)
		m.plant(scenery,Vector3(x+.15,.02,9.43),true)
	# Open central gateway: the sign is mounted on the left wing, keeping the tills visible.
	for x in [2.2,3.78]:
		m.block(scenery,Vector3(x,.51,9.05),Vector3(.13,1.02,.16),m.TEAL,.028)
		m.block(scenery,Vector3(x,.57,9.15),Vector3(.065,.78,.035),m.ORANGE,.012)
	for i in range(6): m.block(scenery,Vector3(2.3+i*.27,1.02,9.22),Vector3(.27,.085,.58),m.ORANGE if i%2 == 0 else m.CREAM,.018)
	m.block(scenery,Vector3(3,1.00,9.52),Vector3(1.64,.15,.08),m.TEAL,.02)
	for x in [2.28,2.55,2.82,3.09,3.36,3.63]: m.sphere(scenery,Vector3(x,.995,9.57),Vector3(.055,.055,.025),Color("ffed84"))
	# Layered sign, solid border and a sculpted hammer give the brand a physical presence.
	m.block(scenery,Vector3(1.12,.99,9.16),Vector3(2.14,.70,.18),m.ORANGE,.09)
	m.block(scenery,Vector3(1.12,.99,9.27),Vector3(2.04,.62,.08),m.CREAM,.065)
	var sign := MeshInstance3D.new(); var plate := QuadMesh.new(); plate.size = Vector2(1.98,.55); sign.mesh = plate; sign.position = Vector3(1.12,.99,9.32)
	var logo_material := StandardMaterial3D.new(); logo_material.albedo_texture = preload("res://assets/brand/logo.svg"); logo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; logo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; logo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sign.material_override = logo_material; sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; scenery.add_child(sign)
	var brand_hammer := m.hammer(scenery,Vector3(.13,1.58,9.13),.82); brand_hammer.rotation.z = -.30
	m.block(scenery,Vector3(3,.07,8.84),Vector3(1.2,.025,.35),Color("3dc85b"),.035)
func neighbourhood():
	var m := models
	# Larger finite garden, forecourt and neighbouring buildings; camera remains inside.
	m.block(scenery,Vector3(3,-.01,12.9),Vector3(15.7,.045,1.6),Color("46728b"),.02)
	for x in range(-5,11): m.block(scenery,Vector3(x,.02,12.9),Vector3(.45,.009,.055),m.CREAM,.002)
	for z in [11.95,13.9]: m.block(scenery,Vector3(3,.02,z),Vector3(15.7,.05,.35),Color("f3f2e4"),.02)
	# Parking kept clear of the actual entrance.
	m.block(scenery,Vector3(3,.015,10.8),Vector3(7.1,.04,1.45),Color("7098a9"),.02)
	for x in [.1,1.2,2.3,4.3,5.4,6.5]: m.block(scenery,Vector3(x,.045,10.8),Vector3(.035,.01,.9),Color.WHITE,.002)
	for building in [[-3.8,3.0,Color("fead26")],[9.2,1.6,Color("1c9bdd")],[8.7,8.0,Color("f04f80")]]:
		var x: float = building[0]; var z: float = building[1]; var color: Color = building[2]
		m.block(scenery,Vector3(x,.85,z),Vector3(1.4,1.7,1.8),color,.12)
		m.block(scenery,Vector3(x,1.8,z),Vector3(1.6,.25,2.0),m.TEAL,.1)
		for dx in [-.36,.36]: m.block(scenery,Vector3(x+dx,1.05,z+.92),Vector3(.42,.48,.035),Color("5fddfb"),.04)
	for x in [-3.0,-1.3,7.1,9.7]:
		for z in [-3.3,-.8,4.8,10.0,16.1]:
			m.cylinder(scenery,Vector3(x,.4,z),.09,.8,Color("a75f2c"))
			m.sphere(scenery,Vector3(x,1.20,z),Vector3(1.05,1.35,1.0),Color("20b044"))
			m.sphere(scenery,Vector3(x-.24,1.40,z+.14),Vector3(.72,.82,.7),Color("7be52e"))
			m.sphere(scenery,Vector3(x+.25,1.04,z+.10),Vector3(.56,.60,.56),Color("26c45b"))
	# Finite street scenery: chunky toy cars and a branded delivery van.
	vehicle(Vector3(.62,0,10.80),Color("ffb721"),false)
	vehicle(Vector3(5.48,0,10.80),Color("ed4e91"),false)
	var van := vehicle(Vector3(-1.75,0,6.25),m.TEAL,true); van.rotation.y = PI/2
	for x in [-.75,6.8]:
		m.block(scenery,Vector3(x,.18,9.8),Vector3(.65,.30,.45),m.TEAL,.05)
		m.block(scenery,Vector3(x,.35,9.8),Vector3(.59,.05,.40),Color("e79836"),.02)
		for dx in [-.20,0,.20]: m.plant(scenery,Vector3(x+dx,.37,9.8))
	for z in range(-5,18):
		for x in [-4.8,10.8]: m.block(scenery,Vector3(x,.23,z+.5),Vector3(.3,.5,.96),Color("148f43"),.09)
	for x in range(-5,11):
		for z in [-4.8,17.8]: m.block(scenery,Vector3(x+.5,.23,z),Vector3(.96,.5,.3),Color("148f43"),.09)
func vehicle(at: Vector3, color: Color, delivery: bool) -> Node3D:
	var m := models; var car := m.node(scenery,at)
	m.block(car,Vector3(0,.24,0),Vector3(.54,.25,.90),color,.08)
	m.block(car,Vector3(0,.47,-.06),Vector3(.48,.29,.51),color,.07)
	m.block(car,Vector3(0,.48,.205),Vector3(.38,.19,.018),Color("84edff"),.03)
	for x in [-.28,.28]:
		for z in [-.28,.28]:
			var wheel := m.cylinder(car,Vector3(x,.15,z),.13,.075,Color("194363")); wheel.rotation.z = PI/2
			var hub := m.cylinder(car,Vector3(x*1.08,.15,z),.065,.078,m.CREAM); hub.rotation.z = PI/2
	for x in [-.17,.17]: m.block(car,Vector3(x,.26,.455),Vector3(.12,.08,.02),Color("fff4ad"),.012)
	m.block(car,Vector3(0,.13,.46),Vector3(.45,.06,.06),m.CREAM,.02)
	if delivery:
		m.block(car,Vector3(0,.58,-.30),Vector3(.56,.57,.60),m.CREAM,.07)
		m.block(car,Vector3(.286,.58,-.30),Vector3(.025,.22,.45),m.ORANGE,.02)
		m.carton(car,Vector3(0,.96,-.30),Vector3(.32,.20,.31))
	return car
func recenter():
	focus = Vector3(3,.1,6.0 if sim.expansion == 0 else (5.3 if sim.expansion == 1 else 4.7)); zoom = 8.4 if sim.expansion == 0 else 9.0
	update_camera()
func update_camera():
	if camera == null: return
	focus.x = clampf(focus.x,1,5.5); focus.z = clampf(focus.z,2.0,9.5)
	camera.size = zoom; camera.position = focus+CAMERA_ARM; camera.look_at(focus)
func ground(at: Vector2) -> Vector3:
	var plane := Plane(Vector3.UP,0)
	var hit = plane.intersects_ray(camera.project_ray_origin(at),camera.project_ray_normal(at))
	return hit if hit != null else focus
func pan(from: Vector2, to: Vector2):
	focus += ground(from)-ground(to); update_camera()
func zoom_at(factor: float, at: Vector2):
	var before := ground(at); zoom = clampf(zoom/factor,MIN_ZOOM,MAX_ZOOM); update_camera()
	focus += before-ground(at); update_camera()
func tap(at: Vector2):
	var ray := PhysicsRayQueryParameters3D.create(camera.project_ray_origin(at),camera.project_ray_origin(at)+camera.project_ray_normal(at)*60,1)
	ray.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty(): return
	var object: Area3D = hit.collider
	selected_kind = object.get_meta("kind"); selected_id = object.get_meta("id")
	selection_marker.position = Vector3(hit.position.x,.09,hit.position.z); selection_marker.visible = true
	selected.emit(selected_kind,selected_id)
func _process(dt: float):
	if camera == null: return
	if low_applied != sim.settings.graphics_low:
		low_applied = sim.settings.graphics_low
		sun.shadow_enabled = false
		get_viewport().scaling_3d_scale = .75 if low_applied else 1.0
	var live := {}
	var changed := false
	for employee in [true,false]:
		for agent in (sim.workers if employee else sim.customers):
			var key := ("w" if employee else "c")+str(agent.id); live[key] = true
			if figures.has(key) and figures[key].agent != agent:
				figures[key].queue_free(); figures.erase(key)
			if not figures.has(key):
				var figure := BricoAgent3D.new(); population.add_child(figure); figure.setup(agent,employee,models); figures[key] = figure; changed = true
			figures[key].animate(minf(dt,.1),sim.settings.reduced_effects,debug_states)
	for key in figures.keys():
		if not live.has(key):
			figures[key].queue_free(); figures.erase(key); changed = true
	if changed: rebuild_actor_batches()
	update_actor_batches()
	for entry in cashiers:
		var paying := false
		if not sim.queues[entry.index].is_empty():
			for customer in sim.customers:
				if customer.id == sim.queues[entry.index][0]: paying = customer.state == BricoCustomer.State.PAYING; break
		entry.view.agent.state = BricoWorker.State.RESTOCKING if paying else BricoWorker.State.IDLE
		entry.view.animate(minf(dt,.1),sim.settings.reduced_effects)
		entry.view.rotation.y = PI; entry.view.caption.visible = false
	update_stock()
	for item in feedback:
		item.time += dt
		if item.get("bill",false):
			var t: float = item.time/1.7
			item.node.position = item.origin+Vector3(item.spread*t,sin(t*PI)*.38+t*.3,0)
			item.node.modulate.a = minf(1,(1-t)*3)
		else: item.node.position.y += dt*.28
		if item.time > 1.7: item.node.queue_free()
	feedback = feedback.filter(func(item): return item.time <= 1.7)
func rebuild_actor_batches():
	for batch in actor_batches.values(): batch.node.visible = false; batch.node.queue_free()
	actor_batches.clear()
	var groups := {}
	for figure in figures.values(): models.collect_meshes(figure,groups)
	for key in groups:
		var parts: Array = groups[key]
		var first: MeshInstance3D = parts[0]
		var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.mesh = first.mesh; multi.instance_count = parts.size()
		var draw := MultiMeshInstance3D.new(); draw.multimesh = multi; draw.material_override = first.material_override; draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(draw)
		for part in parts: part.visible = false
		actor_batches[key] = {"node":draw,"parts":parts}
func update_actor_batches():
	for batch in actor_batches.values():
		for i in range(batch.parts.size()):
			var part: MeshInstance3D = batch.parts[i]
			# Cargo visibility follows the actual transported quantity, including its ancestors.
			var hidden := false
			var ancestor := part.get_parent()
			while ancestor != null and ancestor != population:
				if ancestor is Node3D and not ancestor.visible: hidden = true; break
				ancestor = ancestor.get_parent()
			var transform := part.global_transform
			if hidden: transform.basis = Basis.from_scale(Vector3.ZERO)
			batch.node.multimesh.set_instance_transform(i,transform)
func cancel_gestures():
	held = false; fingers.clear(); dragged = true; pinch_distance = 0
func _input(event: InputEvent):
	if ui_blocks_point.is_valid() and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion):
		if ui_blocks_point.call(event.position): cancel_gestures()
func _unhandled_input(event: InputEvent):
	if camera == null: return
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if ui_blocks_point.is_valid() and (event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventMouseMotion):
		if ui_blocks_point.call(event.position): return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom_at(1.1,event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom_at(1/1.1,event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: held = true; dragged = false; press = event.position; last_pointer = press
			elif held:
				held = false
				if not dragged: tap(event.position)
	elif event is InputEventMouseMotion and held:
		if event.position.distance_to(press) > 12: dragged = true
		if dragged: pan(last_pointer,event.position)
		last_pointer = event.position
	elif event is InputEventScreenTouch:
		if event.pressed:
			fingers[event.index] = event.position
			if fingers.size() == 1: press = event.position; dragged = false
			else:
				dragged = true; var points := fingers.values(); pinch_distance = points[0].distance_to(points[1])
		else:
			if fingers.has(event.index) and fingers.size() == 1 and not dragged and not event.canceled: tap(event.position)
			fingers.erase(event.index); pinch_distance = 0
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var previous: Vector2 = fingers[event.index]; fingers[event.index] = event.position
		if fingers.size() == 2:
			var points := fingers.values(); var distance: float = points[0].distance_to(points[1])
			if pinch_distance > 0: zoom_at(distance/pinch_distance,(points[0]+points[1])/2)
			pinch_distance = distance; dragged = true
		else:
			if event.position.distance_to(press) > 12: dragged = true
			if dragged: pan(previous,event.position)
