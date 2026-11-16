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
var reserve_products: Node3D
var reserve_bin := -1
var sign_materials := {}
const MIN_ZOOM := 4.5
const MAX_ZOOM := 11.5
const MAP_BOUNDS := Rect2(-5,-5,16,23)
const SIGN_FILES := {"Outillage":"tools","Peinture":"paint","Jardinage":"garden","Électricité":"electric","Plomberie":"plumbing","+ Outillage":"tools_locked","+ Peinture":"paint_locked","+ Jardinage":"garden_locked","+ Électricité":"electric_locked","+ Plomberie":"plumbing_locked","RÉSERVE":"reserve","LIVRAISONS":"delivery","NOUVELLE AILE":"extension1","GRAND DÉPÔT":"extension2","+ CAISSE 2":"cash_locked","CAISSE 1":"cash1","CAISSE 2":"cash2"}
const CAMERA_ARM := Vector3(5.7,15.4,14.8)
func setup(simulation: BricoSimulation):
	sim = simulation
func _ready():
	var environment := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("8cddf3")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color.WHITE; env.ambient_light_energy = .44
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.environment = env; add_child(environment)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55,-32,0); sun.light_color = Color.WHITE; sun.light_energy = .65
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
	scenery = Node3D.new(); add_child(scenery); shelves.clear(); cashiers.clear(); reserve_bin = -1; store_revision += 1
	var m := models
	m.block(scenery,Vector3(3,-.15,6.5),Vector3(16,.2,23),Color("62b93c"),.12)
	m.block(scenery,Vector3(3,-.025,4.6),Vector3(6.4,.12,9.8),Color("e9ded0"),.08)
	var top := 3.0 if sim.expansion == 0 else (1.4 if sim.expansion == 1 else 0.0)
	# Large batched tiled surface: each tile is one bevelled slab with shared material.
	for y in range(int(top*10),90,6):
		for x in range(10):
			m.block(scenery,Vector3(x*.6+.3,.045,y*.1+.3),Vector3(.59,.05,.59),Color("fffdf1") if (x+y/6)%2 == 0 else Color("f3f0dd"),.008)
	m.block(scenery,Vector3(3.25,.076,(top+8.9)/2),Vector3(.028,.006,8.9-top),Color("efc575"),.003)
	m.block(scenery,Vector3(3,.51,top),Vector3(6.1,.98,.16),Color("f9faf3"),.04)
	m.block(scenery,Vector3(3,1.02,top+.075),Vector3(6.1,.10,.08),m.ORANGE,.006)
	for x in [.7,2.2,3.7,5.2]:
		m.block(scenery,Vector3(x,.48,top+.10),Vector3(.98,.30,.035),m.TEAL,.025)
		m.block(scenery,Vector3(x,.48,top+.126),Vector3(.90,.23,.018),Color("58c4e4"),.018)
	m.block(scenery,Vector3(.03,.20,(top+9)/2),Vector3(.12,.4,9-top),Color("fff8e9"),.03)
	if sim.expansion < 2:
		var closed_top := 1.4 if sim.expansion == 0 else 0.0
		m.block(scenery,Vector3(3,.07,(closed_top+top)/2),Vector3(5.8,.1,top-closed_top),Color("6bc653"),.04)
		for x in range(6):
			m.block(scenery,Vector3(.5+x,.5,top-.12),Vector3(.07,1,.07),m.TEAL,.01)
			m.block(scenery,Vector3(.5+x,.34,top-.12),Vector3(.95,.055,.07),m.ORANGE,.01)
			m.block(scenery,Vector3(.5+x,.62,top-.12),Vector3(.95,.055,.07),m.CREAM,.01)
		placard(scenery,Vector3(3,1.32,top+.10),"NOUVELLE AILE" if sim.expansion == 0 else "GRAND DÉPÔT",1.70,m.TEAL,35)
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
func placard(parent: Node3D, at: Vector3, text: String, width: float, color: Color, font_size := 42) -> Node3D:
	var m := models; var n := m.node(parent,at)
	n.rotation.y = atan2(CAMERA_ARM.x,CAMERA_ARM.z)
	m.block(n,Vector3.ZERO,Vector3(width,.27,.085),color,.045)
	m.block(n,Vector3(0,-.12,.01),Vector3(width-.08,.025,.08),color.darkened(.12),.008)
	if SIGN_FILES.has(text):
		var plate := QuadMesh.new(); plate.size = Vector2(width-.10,.235)
		var front := m.mesh(n,plate,Vector3(0,.005,.075),Color.WHITE)
		if not sign_materials.has(text):
			var mat := StandardMaterial3D.new(); mat.albedo_texture = load("res://assets/signs/"+SIGN_FILES[text]+".svg"); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; mat.cull_mode = BaseMaterial3D.CULL_DISABLED; mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			sign_materials[text] = mat
		front.material_override = sign_materials[text]
	else:
		var label := m.label(n,Vector3(0,.007,.080),text,font_size,Color.WHITE); label.billboard = BaseMaterial3D.BILLBOARD_DISABLED; label.pixel_size = .0041; label.shaded = false
	return n
func reserve_and_dock():
	var m := models; var rack := m.node(scenery,Vector3(.77,0,3.20))
	m.block(rack,Vector3(0,.075,0),Vector3(1.22,.05,.64),Color("c29a62"),.025)
	for x in [-.56,.56]: m.block(rack,Vector3(x,.58,-.20),Vector3(.09,1.05,.10),m.TEAL,.025)
	for y in [.16,.56,.96]:
		m.block(rack,Vector3(0,y,-.02),Vector3(1.2,.075,.55),Color("dcba83"),.025)
		m.block(rack,Vector3(0,y+.015,.27),Vector3(1.22,.05,.035),m.TEAL,.01)
	placard(rack,Vector3(0,1.42,-.10),"RÉSERVE",1.18,m.TEAL,40)
	reserve_products = m.node(rack); reserve_products.name = "Products"
	m.pick(scenery,Vector3(.78,.57,3.35),Vector3(1.3,1.2,.9),"reserve","")
	m.block(scenery,Vector3(.67,.085,6.38),Vector3(1.12,.08,1.04),Color("d8c5a0"),.025)
	for z in [6.02,6.35,6.68]: m.block(scenery,Vector3(.67,.139,z),Vector3(1.06,.035,.16),Color("b08a51"),.012)
	for x in [.35,.72,1.04]:
		m.carton(scenery,Vector3(x,.31,6.36),Vector3(.29,.30,.30))
		m.block(scenery,Vector3(x,.16,6.9),Vector3(.20,.015,.065),m.ORANGE,.006)
	placard(scenery,Vector3(.67,.83,6.04),"LIVRAISONS",1.17,m.TEAL,31)
	m.pick(scenery,Vector3(.67,.4,6.3),Vector3(1.2,.8,1.1),"reserve","")
	if sim.expansion >= 1:
		m.block(scenery,Vector3(.8,.08,2.05),Vector3(1.2,.08,.7),Color("c1aa82"),.03)
		for x in [.45,.8,1.15]: m.carton(scenery,Vector3(x,.29,2.05))
	if sim.expansion == 2:
		for x in [.45,1.05,5.5]:
			m.carton(scenery,Vector3(x,.22,.65),Vector3(.4,.35,.45)); m.carton(scenery,Vector3(x,.55,.65))
func update_reserve_stock():
	if not is_instance_valid(reserve_products): return
	var total := 0; var capacity := 0
	for family in sim.cfg.families:
		if sim.opened[family.id]: total += sim.inventory.reserve[family.id]; capacity += sim.reserve_capacity()
	var bin := ceili(8.0*total/maxi(1,capacity))
	if bin == reserve_bin: return
	reserve_bin = bin
	for child in reserve_products.get_children(): reserve_products.remove_child(child); child.queue_free()
	for i in range(bin): models.carton(reserve_products,Vector3(-.39+(i%3)*.39,.34+(i/3)*.40,0),Vector3(.32,.28,.30))
	models.batch_static(reserve_products)
func shelf(f: Dictionary):
	var m := models
	var root := m.node(scenery,Vector3(f.rect[0]/100,0,f.rect[1]/100)); shelves[f.id] = root
	root.set_meta("family",f.id); root.set_meta("stock_bin",-1)
	var width: float = f.rect[2]/100.0; var depth: float = f.rect[3]/100.0
	m.pick(root,Vector3(width/2,.54,depth/2),Vector3(width+.06,1.12,depth+.06),"shelf",f.id)
	if not sim.opened[f.id]:
		m.block(root,Vector3(width/2,.095,depth/2),Vector3(width,.08,depth),Color("dae8df"),.05)
		m.carton(root,Vector3(width/2,.36,depth/2),Vector3(.58,.48,.48))
		for i in range(5): m.block(root,Vector3(.15+i*.27,.17,depth+.012),Vector3(.17,.08,.035),m.ORANGE,.02)
		placard(root,Vector3(width/2,.88,depth*.45),"+ "+f.name,width*.96,m.TEAL,36); return
	var level: int = maxi(sim.levels[f.id].capacity,sim.levels[f.id].value)
	var color := m.TEAL if level < 3 else Color("075b8b")
	var accent: Color = {"tools":Color("ffa21c"),"paint":Color("ffbc40"),"garden":Color("49ab2f")}.get(f.id,m.ORANGE)
	var height := .94 if level < 3 else 1.18
	m.block(root,Vector3(width/2,.12,depth/2),Vector3(width+.08,.14,depth+.05),color,.045)
	m.block(root,Vector3(width/2,.095,depth+.012),Vector3(width,.12,.07),accent,.025)
	for x in [.04,width-.04]:
		m.block(root,Vector3(x,height/2+.1,.08),Vector3(.105,height,.12),color,.033)
		m.block(root,Vector3(x,.11,depth-.07),Vector3(.15,.15,.18),color,.035)
	m.block(root,Vector3(width/2,height/2+.15,.09),Vector3(width-.1,height-.10,.075),Color("dcb978") if f.id == "tools" else color.lightened(.06),.025)
	for y in [.24,.63] + ([1.0] if level >= 3 else []):
		m.block(root,Vector3(width/2,y,depth*.46),Vector3(width,.09,depth*.88),color,.03)
		m.block(root,Vector3(width/2,y+.017,depth*.90),Vector3(width,.07,.055),accent,.018)
		for x in [.25,width-.25]: m.block(root,Vector3(x,y-.006,depth*.935),Vector3(.14,.043,.01),m.CREAM,.006)
	if f.id == "tools":
		for x in range(8):
			for y in range(3): m.cylinder(root,Vector3(.16+x*.15,.46+y*.15,.135),.010,.01,Color("b18b50")).rotation.x = PI/2
	elif f.id == "paint":
		for i in range(6): m.block(root,Vector3(.18+i*.20,.92,.14),Vector3(.16,.10,.012),[Color("fa8d24"),Color("e64f94"),Color("32b564"),Color("39a6dc"),Color("ffd13e"),Color("805ccc")][i],.02)
	var title := placard(root,Vector3(width/2,height+.22,.07),f.name,width+.07,color,43)
	m.block(title,Vector3(0,-.145,0),Vector3(width*.65,.025,.07),accent,.009)
	if level >= 5:
		m.block(root,Vector3(width/2,height+.39,depth*.28),Vector3(width+.14,.075,depth*.56),accent,.035)
		for x in [.10,width-.10]: m.block(root,Vector3(x,height+.1,.1),Vector3(.045,.40,.04),m.CREAM,.012)
	var stock_label := m.label(root,Vector3(width/2,.20,depth+.08),"",24,color); stock_label.name = "StockLabel"; stock_label.visible = false
	var products := m.node(root); products.name = "Products"
func update_stock():
	update_reserve_stock()
	for f in sim.cfg.families:
		if not shelves.has(f.id) or not sim.opened[f.id]: continue
		var root: Node3D = shelves[f.id]
		var count: int = sim.inventory.shelves[f.id]
		var level: int = maxi(sim.levels[f.id].capacity,sim.levels[f.id].value)
		var slots := 9 if level >= 3 else 6
		var bin := ceili(float(slots)*count/sim.capacity(f.id))
		var label: Label3D = root.get_node("StockLabel"); label.text = "VIDE" if count == 0 else "STOCK BAS"; label.visible = count <= 2
		if root.get_meta("stock_bin") == bin: continue
		root.set_meta("stock_bin",bin)
		var products := root.get_node("Products")
		for child in products.get_children(): products.remove_child(child); child.queue_free()
		var palette := [Color("fb8c25"),Color("31a6d7"),Color("ed538b"),Color("54b837"),Color("ffcc35"),Color("8062cc")]
		var width: float = f.rect[2]/100.0
		for i in range(bin):
			var at := Vector3(.21+(i%3)*(width-.42)/2,.285+float(i/3)*.39,.50)
			var item := models.product(products,f.id,at,i,palette[i%palette.size()]); item.scale = Vector3.ONE*(1.0 if f.id == "garden" else 1.22)
		if f.id == "tools" and bin >= 4: models.hanging_tools(products,Vector3(width/2,.38,.18),width*.75)
		models.batch_static(products)
func checkout(index: int):
	var m := models; var x := 1.5 if index == 0 else 3.7
	if index >= sim.checkouts:
		m.block(scenery,Vector3(x+.5,.10,7.87),Vector3(1,.06,.65),Color("e2e4d5"),.03)
		for dx in [-.35,.35]: m.block(scenery,Vector3(x+.5+dx,.15,7.87),Vector3(.06,.05,.5),m.ORANGE,.012)
		placard(scenery,Vector3(x+.5,.58,7.87),"+ CAISSE 2",1.1,m.TEAL,30)
		m.pick(scenery,Vector3(x+.5,.4,7.9),Vector3(1.1,.8,.8),"checkout",str(index)); return
	var c := m.node(scenery,Vector3(x,0,7.6))
	m.block(c,Vector3(.5,.31,.27),Vector3(1,.50,.57),m.TEAL,.07)
	m.block(c,Vector3(.5,.60,.27),Vector3(1.04,.08,.62),m.CREAM,.04)
	m.block(c,Vector3(.30,.655,.26),Vector3(.54,.025,.49),Color("244c63"),.015)
	for z in [.09,.19,.29,.39]: m.block(c,Vector3(.3,.675,z),Vector3(.48,.012,.015),Color("3d697c"),.005)
	m.block(c,Vector3(.76,.71,.28),Vector3(.07,.15,.07),m.TEAL,.018)
	var terminal := m.block(c,Vector3(.76,.84,.28),Vector3(.25,.19,.09),Color("173f58"),.026); terminal.rotation.x = -.15
	m.block(c,Vector3(.76,.84,.335),Vector3(.19,.125,.013),Color("69d6d5"),.012)
	m.block(c,Vector3(.92,.67,.36),Vector3(.12,.06,.18),Color("194a63"),.02)
	m.block(c,Vector3(.92,.705,.36),Vector3(.085,.01,.095),Color("b8edaa"),.008)
	m.block(c,Vector3(.5,.32,.57),Vector3(.87,.28,.04),m.ORANGE,.04)
	placard(c,Vector3(.5,.32,.60),"CAISSE %d" % (index+1),.85,m.ORANGE,28)
	m.pick(c,Vector3(.5,.5,.25),Vector3(1.1,1,.7),"checkout",str(index))
	var dummy := BricoWorker.new(3+index); dummy.pos = Vector2((x+.6)*100,833)
	var cashier := BricoAgent3D.new(); scenery.add_child(cashier); cashier.setup(dummy,true,m); cashier.position = Vector3(x+.6,.075,8.33); cashier.rotation.y = PI; cashier.caption.visible = false
	cashiers.append({"view":cashier,"index":index})
	for z in [6.2,6.65,7.1]: m.block(scenery,Vector3(x+.5,.09,z),Vector3(.28,.009,.04),Color("d9ac66"),.004)
func facade():
	var m := models
	# Open cutaway shopfront keeps the entrance and the working cashiers visible.
	for wing in [[.10,2.0],[3.92,1.98]]:
		var start: float = wing[0]; var width: float = wing[1]
		m.block(scenery,Vector3(start+width/2,.35,9.10),Vector3(width,.60,.15),m.CREAM,.06)
		m.block(scenery,Vector3(start+width/2,.42,9.2),Vector3(width-.14,.34,.035),Color("59c8e8"),.025)
		m.block(scenery,Vector3(start+width/2,.16,9.23),Vector3(width,.13,.055),m.ORANGE,.025)
		for x in [start+.06,start+width-.06]: m.block(scenery,Vector3(x,.90,9.10),Vector3(.12,1.65,.16),m.TEAL,.035)
		m.block(scenery,Vector3(start+width/2,1.69,9.12),Vector3(width+.12,.17,.20),m.ORANGE,.045)
		for i in range(8):
			var stripe := m.block(scenery,Vector3(start+(i+.5)*width/8,1.48,9.31),Vector3(width/8+.006,.10,.62),m.ORANGE if i%2 == 0 else m.CREAM,.025); stripe.rotation.x = -.16
			m.block(scenery,Vector3(start+(i+.5)*width/8,1.39,9.61),Vector3(width/8-.012,.17,.09),m.ORANGE if i%2 == 0 else m.CREAM,.036)
		for dx in [width*.32,width*.67]: m.block(scenery,Vector3(start+dx,.43,9.24),Vector3(.04,.36,.035),m.TEAL,.012)
	for x in [2.30,3.72]:
		m.block(scenery,Vector3(x,.65,9.03),Vector3(.13,1.23,.19),m.TEAL,.035)
		m.block(scenery,Vector3(x,.69,9.15),Vector3(.05,.86,.03),Color("ffba43"),.01)
	m.block(scenery,Vector3(3.01,1.29,9.05),Vector3(1.55,.15,.22),m.ORANGE,.035)
	m.block(scenery,Vector3(1.19,1.99,9.20),Vector3(2.45,.75,.20),m.ORANGE,.105)
	m.block(scenery,Vector3(1.19,1.99,9.32),Vector3(2.30,.61,.075),m.CREAM,.07)
	var sign := MeshInstance3D.new(); var plate := QuadMesh.new(); plate.size = Vector2(2.24,.56); sign.mesh = plate; sign.position = Vector3(1.19,1.99,9.37)
	var mat := StandardMaterial3D.new(); mat.albedo_texture = preload("res://assets/brand/logo.svg"); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sign.material_override = mat; sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; scenery.add_child(sign)
	var hammer := m.hammer(scenery,Vector3(.08,2.44,9.13),.72); hammer.rotation.z = -.30
	m.block(scenery,Vector3(3,.085,8.86),Vector3(1.23,.028,.42),m.TEAL,.06)
	for x in [.15,5.88]:
		m.block(scenery,Vector3(x,.21,9.60),Vector3(.46,.34,.43),Color("ec8c35"),.07)
		m.block(scenery,Vector3(x,.40,9.60),Vector3(.50,.06,.47),Color("ffbc62"),.025)
		m.plant(scenery,Vector3(x,.43,9.60),true)
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
	focus = Vector3(3,.15,6.1 if sim.expansion == 0 else (6.0 if sim.expansion == 1 else 5.3)); zoom = 7.8 if sim.expansion == 0 else 8.6
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
