class_name BricoAgent3D
extends Node3D
# Articulated mesh hierarchy. Procedural animation, no claimed skeleton/rig asset.
var agent: RefCounted
var employee := false
var models: BricoModels3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var cargo: Node3D
var body: Node3D
var caption: Label3D
var phase := 0.0
func setup(a: RefCounted, is_employee: bool, m: BricoModels3D):
	agent = a; employee = is_employee; models = m
	var skin: Color = [Color("edba8d"),Color("bc8865"),Color("875c48")][a.id%3]
	var shirts := [Color("fa4e78"),Color("268be6"),Color("22bb52"),Color("ffc321"),Color("ab43de"),Color("00b8bb")]
	var shirt: Color = models.TEAL if employee else shirts[a.appearance]
	body = models.node(self)
	body.scale = Vector3(1.15,1.22,1.15)
	for side in [-1,1]:
		var leg := models.node(body,Vector3(side*.065,.27,0)); legs.append(leg)
		models.block(leg,Vector3(0,-.105,0),Vector3(.09,.21,.105),Color("234d7e"),.025)
		models.block(leg,Vector3(0,-.225,.035),Vector3(.12,.065,.19),Color("183c65"),.025)
		models.block(leg,Vector3(0,-.258,.045),Vector3(.125,.018,.195),models.CREAM,.007)
		var arm := models.node(body,Vector3(side*.16,.49,0)); arms.append(arm)
		models.block(arm,Vector3(0,-.045,0),Vector3(.09,.11,.1),shirt,.02)
		models.block(arm,Vector3(0,-.14,0),Vector3(.07,.13,.075),skin,.022)
		models.sphere(arm,Vector3(0,-.21,0),Vector3(.08,.08,.08),skin)
	models.block(body,Vector3(0,.385,0),Vector3(.25,.25,.17),shirt,.05)
	models.block(body,Vector3(0,.27,0),Vector3(.255,.03,.18),Color("31454d"),.01)
	models.sphere(body,Vector3(0,.65,0),Vector3(.31,.30,.29),skin)
	models.sphere(body,Vector3(0,.742,-.022),Vector3(.30,.14,.27),Color("624b3d"))
	for x in [-.055,.055]:
		models.sphere(body,Vector3(x,.677,.137),Vector3(.055,.063,.028),Color.WHITE)
		models.sphere(body,Vector3(x,.674,.156),Vector3(.027,.035,.014),Color("073e65"))
	models.block(body,Vector3(0,.606,.14),Vector3(.05,.012,.012),Color("a65038"),.003)
	models.sphere(body,Vector3(0,.631,.15),Vector3(.05,.045,.045),skin.lightened(.1))
	for side in [-1,1]:
		models.sphere(body,Vector3(side*.148,.652,-.004),Vector3(.045,.065,.04),skin)
		models.sphere(body,Vector3(side*.085,.631,.126),Vector3(.05,.028,.015),skin.lerp(Color("f56c5c"),.26))
	if employee:
		models.block(body,Vector3(0,.37,.096),Vector3(.16,.17,.015),models.ORANGE,.012)
		models.block(body,Vector3(.04,.43,.11),Vector3(.06,.035,.012),models.CREAM,.005)
		var cap_color: Color = [models.ORANGE,Color("ffc321"),Color("20d195")][a.id%3]
		models.sphere(body,Vector3(0,.782,-.015),Vector3(.3,.13,.28),cap_color)
		models.block(body,Vector3(0,.76,.12),Vector3(.31,.03,.13),cap_color,.008)
		if a.specialty == "Costaud":
			models.block(body,Vector3(-.155,.41,0),Vector3(.05,.13,.15),models.ORANGE,.018)
		if a.specialty == "Minutieux":
			models.block(body,Vector3(.09,.35,.115),Vector3(.025,.09,.02),models.CREAM,.004)
	elif a.profile == "artisan":
		models.sphere(body,Vector3(0,.75,0),Vector3(.265,.14,.24),Color("efd06c"))
	elif a.profile == "vip":
		models.block(body,Vector3(0,.74,.04),Vector3(.25,.06,.24),Color("e7bf56"),.015)
	cargo = models.carton(body,Vector3(0,.35,.22)); cargo.visible = false
	if not employee:
		# Basket stays attached to the carrying pose, never floats ahead of its owner.
		for child in cargo.get_children(): cargo.remove_child(child); child.queue_free()
		models.block(cargo,Vector3.ZERO,Vector3(.26,.15,.2),Color("ffb721"),.03)
		models.block(cargo,Vector3(0,.075,0),Vector3(.27,.025,.21),models.TEAL,.008)
		for x in [-.1,0,.1]: models.block(cargo,Vector3(x,0,.105),Vector3(.014,.1,.01),models.CREAM,.002)
	caption = models.label(self,Vector3(0,1.12,0),a.name if employee else "",24,models.TEAL)
	models.pick(self,Vector3(0,.4,0),Vector3(.36,.85,.35),"workers",str(a.id)) if employee else null
func animate(dt: float, reduced: bool, debug := false):
	phase += dt
	position = Vector3(agent.pos.x/100,0,agent.pos.y/100)
	var moving: bool = not agent.route.is_empty()
	if moving:
		var heading := atan2(agent.direction.x,agent.direction.y)
		rotation.y = lerp_angle(rotation.y,heading,minf(1,dt*12))
	var stride := sin(phase*10+agent.id)*.55 if moving else 0.0
	var carrying: bool = agent.cargo > 0 if employee else agent.carrying
	var working: bool = agent.state == BricoWorker.State.RESTOCKING if employee else agent.state == BricoCustomer.State.PICKING
	# Face the reserved shelf while picking/stocking; other states face the route.
	if working: rotation.y = PI/2 if employee else PI
	for i in range(2):
		legs[i].rotation.x = stride*(1 if i == 0 else -1)
		arms[i].rotation.x = -1.0 if carrying else -stride*(1 if i == 0 else -1)*.75
		arms[i].rotation.z = (-.18 if i == 0 else .18) if carrying else 0.0
		if working: arms[i].rotation.x = -.9+sin(phase*7)*.18
	body.position.y = (absf(sin(phase*10+agent.id))*.024 if moving else sin(phase*2.6+agent.id)*.005) if not reduced else 0
	cargo.visible = carrying
	caption.visible = employee or debug
	if debug: caption.text = str(agent.state)
	elif employee: caption.text = agent.name+ (" · attente" if agent.waiting_goods else "")
