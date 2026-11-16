class_name BricoAgent3D
extends Node3D
# Original articulated toy characters, with procedural shoulder/elbow animation.
var agent: RefCounted
var employee := false
var models: BricoModels3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var cargo: Node3D
var body: Node3D
var head: Node3D
var caption: Label3D
var phase := 0.0
const INK := Color("173e57")
const DENIM := Color("265c82")
const FLOOR_HEIGHT := .075
func setup(a: RefCounted, is_employee: bool, m: BricoModels3D):
	agent = a; employee = is_employee; models = m
	var skin: Color = [Color("f4c395"),Color("bf8b65"),Color("865941"),Color("e5a878")][a.id%4]
	var shirts := [Color("f65379"),Color("2a99e8"),Color("3bbc54"),Color("ffbe25"),Color("9159cf"),Color("11b9b3")]
	var shirt: Color = models.TEAL if employee else shirts[a.appearance%shirts.size()]
	var hair_color: Color = [Color("4a3025"),Color("75482c"),Color("d3a15d"),Color("59616a")][a.id%4]
	body = models.node(self)
	models.sphere(body,Vector3(0,.431,-.012),Vector3(.315,.315,.225),shirt)
	models.block(body,Vector3(0,.43,.014),Vector3(.27,.24,.19),shirt,.065)
	models.block(body,Vector3(0,.297,0),Vector3(.265,.095,.185),DENIM,.035)
	models.sphere(body,Vector3(0,.58,.002),Vector3(.103,.106,.101),skin)
	for side in [-1,1]:
		var leg := models.node(body,Vector3(side*.077,.262,0)); legs.append(leg)
		models.block(leg,Vector3(0,-.103,0),Vector3(.113,.214,.123),DENIM,.04)
		models.block(leg,Vector3(0,-.218,.036),Vector3(.147,.092,.222),INK,.038)
		models.block(leg,Vector3(0,-.253,.047),Vector3(.15,.026,.223),Color("f6f4df"),.011)
		models.block(leg,Vector3(0,-.191,.096),Vector3(.09,.025,.054),shirt.lerp(models.CREAM,.55),.009)
		var arm := models.node(body,Vector3(side*.17,.535,0)); arms.append(arm)
		models.sphere(arm,Vector3(0,-.058,0),Vector3(.118,.161,.123),shirt)
		var elbow := models.node(arm,Vector3(0,-.139,0)); elbows.append(elbow)
		models.sphere(elbow,Vector3(0,-.058,0),Vector3(.084,.142,.087),skin)
		models.sphere(elbow,Vector3(0,-.137,.004),Vector3(.096,.098,.088),skin)
		models.sphere(elbow,Vector3(-side*.037,-.119,.027),Vector3(.045,.062,.047),skin.lightened(.025))
		if not employee: models.block(body,Vector3(side*.107,.336,.105),Vector3(.042,.065,.015),shirt.darkened(.12),.01)
	if employee: uniform()
	else:
		models.block(body,Vector3(0,.536,.102),Vector3(.115,.032,.018),shirt.lightened(.16),.012)
		if a.appearance%3 == 1:
			models.block(body,Vector3(0,.405,.115),Vector3(.14,.023,.013),models.CREAM,.006)
			models.block(body,Vector3(0,.36,.111),Vector3(.18,.019,.012),models.CREAM,.005)
	head = models.node(body,Vector3(0,.731,0))
	models.sphere(head,Vector3.ZERO,Vector3(.357,.337,.328),skin)
	for side in [-1,1]:
		models.sphere(head,Vector3(side*.175,-.009,-.004),Vector3(.058,.079,.054),skin)
		models.sphere(head,Vector3(side*.101,-.047,.137),Vector3(.065,.041,.024),skin.lerp(Color("f07468"),.23))
		models.sphere(head,Vector3(side*.061,.013,.159),Vector3(.026,.039,.018),INK)
		models.sphere(head,Vector3(side*.058,.022,.168),Vector3(.008,.011,.005),models.CREAM)
		var brow := models.block(head,Vector3(side*.059,.051,.151),Vector3(.047,.012,.013),hair_color,.005); brow.rotation.z = -side*.10
	models.sphere(head,Vector3(0,-.022,.181),Vector3(.059,.058,.059),skin.lightened(.04))
	models.block(head,Vector3(0,-.079,.149),Vector3(.057,.016,.016),Color("874d39"),.006)
	models.block(head,Vector3(0,-.075,.159),Vector3(.035,.006,.005),Color("fff3df"),.002)
	hair(hair_color,a.id)
	if employee: cap([models.ORANGE,Color("ffc52e"),Color("16b7a8")][a.id%3])
	elif a.profile == "artisan": cap(Color("ffd157"))
	elif a.profile == "vip":
		models.block(head,Vector3(0,.121,-.016),Vector3(.35,.055,.29),Color("eca52b"),.024)
		models.block(head,Vector3(0,.164,-.026),Vector3(.25,.072,.235),Color("f5c055"),.033)
		models.block(head,Vector3(0,.143,.102),Vector3(.25,.02,.018),INK,.005)
	cargo = models.node(body,Vector3(0,.397,.239)); cargo.visible = false
	if employee: models.carton(cargo,Vector3.ZERO,Vector3(.29,.23,.25))
	else: cargo.position.y = .355; basket()
	caption = models.label(self,Vector3(0,1.14,0),"",24,models.TEAL); caption.visible = false
	if employee: models.pick(self,Vector3(0,.48,0),Vector3(.43,1.0,.43),"checkout" if a.id >= 3 else "workers",str(a.id-3 if a.id >= 3 else a.id))
func uniform():
	var m := models
	m.block(body,Vector3(0,.395,.115),Vector3(.205,.222,.025),m.ORANGE,.027)
	for x in [-.071,.071]:
		m.block(body,Vector3(x,.504,.109),Vector3(.036,.111,.026),m.ORANGE,.011)
		m.sphere(body,Vector3(x,.465,.139),Vector3(.018,.018,.008),m.CREAM)
	m.block(body,Vector3(0,.37,.134),Vector3(.12,.074,.014),m.ORANGE.darkened(.12),.014)
	m.block(body,Vector3(.042,.448,.139),Vector3(.063,.033,.013),m.CREAM,.008)
	if agent.specialty == "Minutieux": m.block(body,Vector3(-.043,.394,.153),Vector3(.014,.083,.012),m.CREAM,.004)
	elif agent.specialty == "Costaud": m.block(body,Vector3(0,.3,.105),Vector3(.245,.038,.02),INK,.009)
func hair(color: Color, identity: int):
	var m := models
	m.sphere(head,Vector3(0,.105,-.032),Vector3(.346,.132,.307),color)
	match identity%4:
		0:
			var tuft := m.sphere(head,Vector3(-.052,.135,.025),Vector3(.215,.114,.182),color); tuft.rotation.z = -.20
			m.sphere(head,Vector3(.078,.113,-.025),Vector3(.15,.105,.25),color)
		1:
			m.sphere(head,Vector3(0,.01,-.115),Vector3(.34,.274,.155),color)
			for side in [-1,1]: m.sphere(head,Vector3(side*.141,.018,-.005),Vector3(.088,.208,.143),color)
		2:
			for x in [-.083,0,.083]: m.sphere(head,Vector3(x,.142,.011),Vector3(.119,.111,.186),color)
		3:
			m.sphere(head,Vector3(-.116,.043,-.046),Vector3(.08,.123,.205),color)
			m.sphere(head,Vector3(.116,.043,-.046),Vector3(.08,.123,.205),color)
func cap(color: Color):
	var m := models
	m.sphere(head,Vector3(0,.134,-.025),Vector3(.374,.152,.341),color)
	m.block(head,Vector3(0,.112,.084),Vector3(.345,.042,.215),color,.033)
	m.sphere(head,Vector3(0,.214,-.025),Vector3(.04,.025,.04),color.darkened(.08))
	m.block(head,Vector3(0,.146,.145),Vector3(.093,.051,.018),m.CREAM,.014)
func basket():
	var m := models; var color := Color("fbb927")
	m.block(cargo,Vector3(0,-.065,0),Vector3(.282,.026,.215),color,.018)
	for z in [-.102,.102]:
		m.block(cargo,Vector3(0,.057,z),Vector3(.294,.028,.023),color,.01)
		for x in [-.11,-.055,0,.055,.11]: m.block(cargo,Vector3(x,-.006,z),Vector3(.018,.115,.018),color,.006)
	for x in [-.137,.137]:
		m.block(cargo,Vector3(x,.057,0),Vector3(.025,.028,.212),color,.008)
		for z in [-.07,0,.07]: m.block(cargo,Vector3(x,-.006,z),Vector3(.018,.115,.018),color,.006)
	for x in [-.127,.127]: m.block(cargo,Vector3(x,.099,0),Vector3(.018,.084,.018),m.TEAL,.006)
	m.block(cargo,Vector3(0,.141,0),Vector3(.268,.022,.025),m.TEAL,.009)
func animate(dt: float, reduced: bool, debug := false):
	phase += dt
	position = Vector3(agent.pos.x/100,FLOOR_HEIGHT,agent.pos.y/100)
	var moving: bool = not agent.route.is_empty()
	if moving: rotation.y = lerp_angle(rotation.y,atan2(agent.direction.x,agent.direction.y),minf(1,dt*12))
	var stride := sin(phase*9.5+agent.id)*.48 if moving else 0.0
	var carrying: bool = agent.cargo > 0 if employee else agent.carrying
	var working: bool = agent.state in [BricoWorker.State.RESTOCKING,BricoWorker.State.LOADING] if employee else agent.state == BricoCustomer.State.PICKING
	var paying: bool = not employee and agent.state == BricoCustomer.State.PAYING
	if working:
		var facing := PI if not employee or agent.state == BricoWorker.State.LOADING else PI/2
		rotation.y = lerp_angle(rotation.y,facing,minf(1,dt*14))
	for i in range(2):
		legs[i].rotation.x = stride*(1 if i == 0 else -1)
		var shoulder := -.65 if carrying else -stride*(1 if i == 0 else -1)*.65
		var elbow := -.78 if carrying else -.10
		if working: shoulder = -.78+sin(phase*6)*.10; elbow = -.66-sin(phase*6)*.10
		if employee and agent.id >= 3 and working: shoulder = -1.15+sin(phase*6)*.10; elbow = -.85
		if paying and i == 1: shoulder = -.92+sin(phase*6)*.12; elbow = -.46
		arms[i].rotation.x = lerpf(arms[i].rotation.x,shoulder,minf(1,dt*16)); elbows[i].rotation.x = lerpf(elbows[i].rotation.x,elbow,minf(1,dt*16)); arms[i].rotation.z = 0
	body.position.y = (absf(sin(phase*9.5+agent.id))*.019 if moving else sin(phase*2.2+agent.id)*.004) if not reduced else 0
	cargo.visible = carrying
	caption.visible = debug or (employee and agent.waiting_goods)
	if debug: caption.text = str(agent.state)
	elif employee and agent.waiting_goods: caption.text = "Stock attendu"
