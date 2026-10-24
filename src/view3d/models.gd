class_name BricoModels3D
extends RefCounted
# Original shared meshes/materials; no external model pack or runtime dependency.
var materials := {}
var geometry := {}
const TEAL := Color("007c9c")
const CREAM := Color("fff9e6")
const ORANGE := Color("ff8b16")
func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not materials.has(key):
		var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 1.0; m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED; m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
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
	# Four bevelled rings and softly rounded corners, shared between identical parts.
	var b := minf(bevel,minf(size.x,minf(size.y,size.z))*.24)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array = []
	for layer in range(4):
		var inset := b if layer in [0,3] else 0.0
		var y: float = [-size.y/2,-size.y/2+b,size.y/2-b,size.y/2][layer]
		var ring := PackedVector3Array()
		var sx := size.x/2-inset; var sz := size.z/2-inset
		var radius := minf(b*1.5,minf(sx,sz)*.4)
		for corner in range(4):
			var angle := corner*PI/2
			var center := Vector2((sx-radius)*(1 if corner in [0,3] else -1),(sz-radius)*(1 if corner < 2 else -1))
			for step in range(4):
				var a := angle+step*PI/6
				ring.append(Vector3(center.x+cos(a)*radius,y,center.y+sin(a)*radius))
		rings.append(ring)
	for layer in range(3):
		for i in range(16):
			var j := (i+1)%16
			triangle(st,rings[layer][i],rings[layer+1][i],rings[layer+1][j])
			triangle(st,rings[layer][i],rings[layer+1][j],rings[layer][j])
	for i in range(16):
		triangle(st,Vector3(0,size.y/2,0),rings[3][(i+1)%16],rings[3][i])
		triangle(st,Vector3(0,-size.y/2,0),rings[0][i],rings[0][(i+1)%16])
	st.generate_normals(); return st.commit()
func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3):
	st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
func sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var key := "unit_sphere"
	if not geometry.has(key):
		var s := SphereMesh.new(); s.radius = .5; s.height = 1; s.radial_segments = 12; s.rings = 6; geometry[key] = s
	var n := mesh(parent,geometry[key],at,color); n.scale = size; return n
func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var key := "cylinder/%s/%s" % [radius,height]
	if not geometry.has(key):
		var c := CylinderMesh.new(); c.top_radius = radius; c.bottom_radius = radius; c.height = height; c.radial_segments = 12; geometry[key] = c
	return mesh(parent,geometry[key],at,color)
func label(parent: Node3D, at: Vector3, text: String, size := 32, tint := CREAM) -> Label3D:
	var l := Label3D.new(); l.position = at; l.text = text; l.font = preload("res://assets/fonts/Fredoka-Semibold.ttf"); l.font_size = size; l.pixel_size = .0036; l.modulate = tint
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED; l.outline_size = 0; parent.add_child(l); return l
func pick(parent: Node3D, at: Vector3, size: Vector3, kind: String, id: String):
	var a := Area3D.new(); a.position = at; a.collision_layer = 1; a.collision_mask = 0
	a.set_meta("kind",kind); a.set_meta("id",id)
	var c := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; c.shape = shape; a.add_child(c); parent.add_child(a)
func carton(parent: Node3D, at: Vector3, size := Vector3(.28,.23,.25)) -> Node3D:
	var n := node(parent,at); block(n,Vector3.ZERO,size,Color("e0a34e"))
	block(n,Vector3(0,size.y/2+.003,0),Vector3(.035,.008,size.z),Color("ffda80"),.001)
	block(n,Vector3(0,0,size.z/2+.004),Vector3(.035,size.y,.008),Color("ffda80"),.001); return n
func plant(parent: Node3D, at: Vector3, large := false):
	var n := node(parent,at); var s := 1.5 if large else 1.0
	cylinder(n,Vector3(0,.08*s,0),.09*s,.16*s,Color("df641f"))
	cylinder(n,Vector3(0,.165*s,0),.095*s,.025*s,Color("ff9a37"))
	for i in range(4):
		var a := i*TAU/4
		var leaf := sphere(n,Vector3(sin(a)*.065,.25+float(i%2)*.05,cos(a)*.065)*s,Vector3(.09,.2,.08)*s,Color("36bd38")); leaf.rotation.z = sin(a)*.5
func product(parent: Node3D, family: String, at: Vector3, variant: int, color: Color):
	var n := node(parent,at)
	match family:
		"tools":
			if variant%2 == 0:
				block(n,Vector3(0,.08,0),Vector3(.25,.15,.13),color)
				block(n,Vector3(0,.18,0),Vector3(.1,.045,.035),TEAL,.008)
				block(n,Vector3(0,.07,.071),Vector3(.035,.04,.01),CREAM,.002)
				for x in [-.087,.087]: block(n,Vector3(x,.11,.073),Vector3(.025,.04,.012),ORANGE,.003)
			else:
				block(n,Vector3(0,.16,0),Vector3(.21,.09,.1),color)
				block(n,Vector3(-.03,.08,0),Vector3(.055,.12,.07),TEAL,.008)
				block(n,Vector3(.14,.16,0),Vector3(.09,.022,.025),Color("bec8c2"),.004)
		"paint":
			var radius := .09 if variant%2 == 0 else .07
			cylinder(n,Vector3(0,.11,0),radius,.21,CREAM)
			cylinder(n,Vector3(0,.11,0),radius+.002,.10,color)
			cylinder(n,Vector3(0,.223,0),radius+.008,.02,Color("ebf3f0"))
			block(n,Vector3(0,.25,0),Vector3(.07,.025,.025),TEAL,.005)
			block(n,Vector3(0,.11,radius+.003),Vector3(.085,.065,.009),CREAM,.007)
		"garden":
			if variant%2 == 0:
				block(n,Vector3(0,.11,0),Vector3(.22,.21,.14),Color("ffdc6d"),.045)
				block(n,Vector3(0,.11,.076),Vector3(.19,.10,.015),color,.008)
			else: plant(n,Vector3.ZERO)
		"electric":
			cylinder(n,Vector3(0,.08,0),.075,.14,TEAL)
			sphere(n,Vector3(0,.21,0),Vector3(.15,.18,.15),color.lightened(.15))
		"plumbing":
			block(n,Vector3(-.07,.1,0),Vector3(.07,.19,.07),color,.025)
			block(n,Vector3(0,.19,0),Vector3(.2,.07,.07),color,.025)

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
