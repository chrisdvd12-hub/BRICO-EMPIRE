class_name BricoModels3D
extends RefCounted
# Original shared meshes/materials; no external model pack or runtime dependency.
var materials := {}
var geometry := {}
const TEAL := Color("006f98")
const CREAM := Color("fff8e9")
const ORANGE := Color("ff9c20")
func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not materials.has(key):
		var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 1.0; m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED; m.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
		materials[key] = m
	return materials[key]
func node(parent: Node3D, at := Vector3.ZERO) -> Node3D:
	var n := Node3D.new(); n.position = at; parent.add_child(n); return n
func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh = shape; n.material_override = material(color); n.position = at; n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(n); return n
func block(parent: Node3D, at: Vector3, size: Vector3, color: Color, bevel := .025) -> MeshInstance3D:
	var key := str(size)+str(bevel)
	if not geometry.has(key): geometry[key] = rounded_mesh(size,bevel)
	return mesh(parent,geometry[key],at,color)
func rounded_mesh(size: Vector3, bevel: float) -> ArrayMesh:
	# True rounded cuboids with analytic normals; shared between all identical parts.
	var half := size*.5
	var radius := clampf(bevel,0.0001,minf(half.x,minf(half.y,half.z))*.92)
	var inner := half-Vector3.ONE*radius
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var axes := [Vector3.RIGHT,Vector3.UP,Vector3.BACK]
	for face in range(3):
		var u: Vector3 = axes[(face+1)%3]; var v: Vector3 = axes[(face+2)%3]
		var ui := (face+1)%3; var vi := (face+2)%3
		var us := [-half[ui],-inner[ui]-radius*.5,-inner[ui],inner[ui],inner[ui]+radius*.5,half[ui]]
		var vs := [-half[vi],-inner[vi]-radius*.5,-inner[vi],inner[vi],inner[vi]+radius*.5,half[vi]]
		for side in [-1.0,1.0]:
			for i in range(5):
				for j in range(5):
					var a: Vector3 = axes[face]*half[face]*side+u*us[i]+v*vs[j]
					var b: Vector3 = axes[face]*half[face]*side+u*us[i+1]+v*vs[j]
					var c: Vector3 = axes[face]*half[face]*side+u*us[i+1]+v*vs[j+1]
					var d: Vector3 = axes[face]*half[face]*side+u*us[i]+v*vs[j+1]
					for point in ([a,c,b,a,d,c] if side > 0 else [a,b,c,a,c,d]):
						var core: Vector3 = point.clamp(-inner,inner)
						var normal: Vector3 = (point-core).normalized()
						st.set_normal(normal); st.add_vertex(core+normal*radius)
	return st.commit()
func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3):
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
func sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var key := "unit_sphere"
	if not geometry.has(key):
		var s := SphereMesh.new(); s.radius = .5; s.height = 1; s.radial_segments = 16; s.rings = 8; geometry[key] = s
	var n := mesh(parent,geometry[key],at,color); n.scale = size; return n
func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var key := "cylinder/%s/%s" % [radius,height]
	if not geometry.has(key):
		var c := CylinderMesh.new(); c.top_radius = radius; c.bottom_radius = radius; c.height = height; c.radial_segments = 16; geometry[key] = c
	return mesh(parent,geometry[key],at,color)
func label(parent: Node3D, at: Vector3, text: String, size := 32, tint := CREAM) -> Label3D:
	var l := Label3D.new(); l.position = at; l.text = text; l.font = preload("res://assets/fonts/Fredoka-Semibold.ttf"); l.font_size = size; l.pixel_size = .0036; l.modulate = tint
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; l.outline_size = 0; parent.add_child(l); return l
func pick(parent: Node3D, at: Vector3, size: Vector3, kind: String, id: String):
	var a := Area3D.new(); a.position = at; a.collision_layer = 1; a.collision_mask = 0
	a.set_meta("kind",kind); a.set_meta("id",id)
	var c := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; c.shape = shape; a.add_child(c); parent.add_child(a)
func tapered_cylinder(parent: Node3D, at: Vector3, top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var key := "taper/%s/%s/%s" % [top,bottom,height]
	if not geometry.has(key):
		var c := CylinderMesh.new(); c.top_radius = top; c.bottom_radius = bottom; c.height = height; c.radial_segments = 16; geometry[key] = c
	return mesh(parent,geometry[key],at,color)
func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, color: Color) -> MeshInstance3D:
	var key := "ring/%s/%s" % [radius,thickness]
	if not geometry.has(key):
		var shape := TorusMesh.new(); shape.inner_radius = radius-thickness; shape.outer_radius = radius+thickness; shape.rings = 20; shape.ring_segments = 6; geometry[key] = shape
	return mesh(parent,geometry[key],at,color)
func carton(parent: Node3D, at: Vector3, size := Vector3(.28,.23,.25)) -> Node3D:
	var n := node(parent,at); block(n,Vector3.ZERO,size,Color("dca25a"),.035)
	var tape := Color("f6cf86"); var front := size.z*.5+.003
	block(n,Vector3(0,size.y*.5+.003,0),Vector3(size.x*.18,.007,size.z*.99),tape,.002)
	block(n,Vector3(0,0,front),Vector3(size.x*.18,size.y*.98,.008),tape,.002)
	block(n,Vector3(0,size.y*.5+.004,0),Vector3(size.x*.99,.005,.008),Color("bd813d"),.001)
	block(n,Vector3(-size.x*.23,-size.y*.02,front+.004),Vector3(size.x*.31,size.y*.37,.008),CREAM,.006)
	for y in [-.07,.03]: block(n,Vector3(-size.x*.23,size.y*y,front+.01),Vector3(size.x*.20,size.y*.027,.003),TEAL,.001)
	return n
func plant(parent: Node3D, at: Vector3, large := false) -> Node3D:
	var n := node(parent,at); n.scale = Vector3.ONE*(1.55 if large else 1.0)
	tapered_cylinder(n,Vector3(0,.085,0),.108,.076,.17,Color("e9702b"))
	ring(n,Vector3(0,.163,0),.106,.014,Color("ffae50"))
	cylinder(n,Vector3(0,.163,0),.092,.012,Color("855331"))
	for i in range(6):
		var a := i*TAU/6
		var leaf := sphere(n,Vector3(sin(a)*.072,.265+float(i%2)*.055,cos(a)*.072),Vector3(.102,.235,.075),Color("49ba31") if i%2 == 0 else Color("79d83b")); leaf.rotation = Vector3(cos(a)*.49,a,-sin(a)*.49)
	cylinder(n,Vector3(0,.24,0),.012,.16,Color("369526"))
	sphere(n,Vector3(0,.345,0),Vector3(.08,.18,.08),Color("92e346"))
	return n
func tool_case(parent: Node3D, at: Vector3, color := ORANGE) -> Node3D:
	var n := node(parent,at)
	block(n,Vector3(0,.091,0),Vector3(.29,.18,.15),color,.037)
	block(n,Vector3(0,.035,.068),Vector3(.275,.045,.032),TEAL,.014)
	block(n,Vector3(0,.103,.078),Vector3(.16,.074,.015),TEAL,.015)
	block(n,Vector3(-.016,.104,.088),Vector3(.052,.011,.006),CREAM,.002)
	for x in [-.105,.105]: block(n,Vector3(x,.151,.079),Vector3(.036,.046,.018),Color("ffe6a6"),.008)
	var handle := ring(n,Vector3(0,.199,0),.044,.010,TEAL); handle.rotation.x = PI/2
	return n
func drill(parent: Node3D, at: Vector3, color := ORANGE) -> Node3D:
	var n := node(parent,at)
	block(n,Vector3(-.04,.225,0),Vector3(.21,.12,.125),color,.043)
	var chuck := cylinder(n,Vector3(.084,.225,0),.049,.055,TEAL); chuck.rotation.z = PI/2
	var collar := cylinder(n,Vector3(.12,.225,0),.034,.035,Color("c8d6d7")); collar.rotation.z = PI/2
	var bit := cylinder(n,Vector3(.159,.225,0),.011,.051,Color("6e92a0")); bit.rotation.z = PI/2
	var grip := block(n,Vector3(-.061,.124,0),Vector3(.076,.15,.09),TEAL,.022); grip.rotation.z = -.17
	block(n,Vector3(-.056,.035,0),Vector3(.155,.069,.13),TEAL,.02)
	block(n,Vector3(-.056,.063,.056),Vector3(.12,.024,.022),color,.007)
	block(n,Vector3(.001,.159,.048),Vector3(.026,.045,.014),Color("ffe4ac"),.005)
	for x in [-.102,-.078,-.054]: block(n,Vector3(x,.235,.065),Vector3(.010,.041,.005),TEAL,.003)
	block(n,Vector3(.007,.231,.066),Vector3(.046,.036,.005),CREAM,.006)
	return n
func small_hammer(parent: Node3D, at: Vector3, color := ORANGE) -> Node3D:
	var n := node(parent,at)
	block(n,Vector3(0,.115,0),Vector3(.034,.23,.039),color,.012)
	block(n,Vector3(0,.055,0),Vector3(.044,.092,.047),TEAL,.012)
	block(n,Vector3(0,.258,0),Vector3(.19,.074,.085),Color("c7d8de"),.019)
	block(n,Vector3(-.096,.258,0),Vector3(.036,.085,.09),TEAL,.009)
	return n
func paint_tin(parent: Node3D, at: Vector3, color: Color, small := false) -> Node3D:
	var n := node(parent,at); var radius := .089 if small else .105; var height := .20 if small else .24
	cylinder(n,Vector3(0,height*.5,0),radius,height,CREAM)
	cylinder(n,Vector3(0,height*.48,0),radius+.002,height*.55,color)
	ring(n,Vector3(0,.018,0),radius,.007,Color("a3bac3"))
	cylinder(n,Vector3(0,height+.006,0),radius+.009,.021,Color("dce8e9"))
	cylinder(n,Vector3(0,height+.019,0),radius-.012,.007,color)
	var handle := ring(n,Vector3(0,height*.71,0),radius+.014,.006,Color("708f9c")); handle.rotation.x = PI/2
	sphere(n,Vector3(0,height*.5,radius+.006),Vector3(.087,.071,.010),CREAM)
	sphere(n,Vector3(0,height*.5,radius+.013),Vector3(.028,.042,.005),color)
	return n
func soil_bag(parent: Node3D, at: Vector3, color: Color) -> Node3D:
	var n := node(parent,at)
	block(n,Vector3(0,.145,0),Vector3(.245,.29,.16),Color("ffda66"),.059)
	block(n,Vector3(0,.269,0),Vector3(.217,.035,.14),color,.013)
	block(n,Vector3(0,.144,.084),Vector3(.20,.17,.012),color,.023)
	block(n,Vector3(0,.065,.092),Vector3(.14,.015,.006),CREAM,.003)
	block(n,Vector3(0,.151,.097),Vector3(.01,.087,.006),CREAM,.002)
	var leaf := sphere(n,Vector3(.027,.172,.10),Vector3(.067,.10,.013),CREAM); leaf.rotation.z = -.52
	return n
func hanging_tools(parent: Node3D, at: Vector3, width := 1.2) -> Node3D:
	var n := node(parent,at)
	for i in range(5):
		var item := small_hammer(n,Vector3((i-2)*width/5,0,0),ORANGE if i%2 == 0 else Color("ffca3d")); item.scale = Vector3.ONE*.78
	return n
func product(parent: Node3D, family: String, at: Vector3, variant: int, color: Color) -> Node3D:
	var n := node(parent,at)
	match family:
		"tools":
			match variant%3:
				0: tool_case(n,Vector3.ZERO,ORANGE if variant%2 == 0 else Color("ffc52f"))
				1: drill(n,Vector3.ZERO,ORANGE)
				2:
					block(n,Vector3(0,.16,-.018),Vector3(.16,.31,.024),Color("f9ca44"),.019)
					small_hammer(n,Vector3(0,0,.012))
		"paint": paint_tin(n,Vector3.ZERO,color,variant%3 == 1)
		"garden":
			if variant%2 == 0: soil_bag(n,Vector3.ZERO,Color("43a536"))
			else: plant(n,Vector3.ZERO)
		"electric":
			cylinder(n,Vector3(0,.055,0),.061,.11,TEAL)
			for y in [.035,.065,.095]: ring(n,Vector3(0,y,0),.062,.005,Color("90b3be"))
			sphere(n,Vector3(0,.19,0),Vector3(.17,.21,.17),Color("ffdf63"))
		"plumbing":
			cylinder(n,Vector3(-.06,.11,0),.038,.22,Color("b5d7dd"))
			var pipe := cylinder(n,Vector3(.018,.22,0),.038,.16,Color("b5d7dd")); pipe.rotation.z = PI/2
			block(n,Vector3(-.06,.256,0),Vector3(.10,.022,.03),color,.007)
	return n

func batch_static(root: Node3D):
	var groups := {}
	collect_meshes(root,groups)
	for key in groups:
		var parts: Array = groups[key]
		if parts.size() < 2: continue
		var first: MeshInstance3D = parts[0]
		var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.mesh = first.mesh; multi.instance_count = parts.size()
		for i in range(parts.size()):
			multi.set_instance_transform(i,root.global_transform.affine_inverse()*parts[i].global_transform)
			parts[i].visible = false
		var draw := MultiMeshInstance3D.new(); draw.multimesh = multi; draw.material_override = first.material_override; draw.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(draw)
func collect_meshes(root: Node, groups: Dictionary):
	for child in root.get_children():
		# Product groups change with inventory; articulated actors have a separate dynamic batch.
		if child is BricoAgent3D or child.name == "Products": continue
		if child is MeshInstance3D:
			var key := str(child.mesh.get_instance_id())+"/"+str(child.material_override.get_instance_id())
			if not groups.has(key): groups[key] = []
			groups[key].append(child)
		collect_meshes(child,groups)

# Recognisable oversized brand prop; shared geometry, no additional lights or assets.
func hammer(parent: Node3D, at: Vector3, size := 1.0) -> Node3D:
	var n := node(parent,at); n.scale = Vector3.ONE*size
	block(n,Vector3(0,-.15,0),Vector3(.12,.63,.13),ORANGE,.035)
	block(n,Vector3(0,-.4,0),Vector3(.15,.18,.15),TEAL,.025)
	block(n,Vector3(0,.19,0),Vector3(.51,.21,.24),Color("edf7ff"),.05)
	block(n,Vector3(-.255,.19,0),Vector3(.065,.25,.28),TEAL,.025)
	block(n,Vector3(.21,.16,0),Vector3(.18,.1,.20),TEAL,.025)
	return n
