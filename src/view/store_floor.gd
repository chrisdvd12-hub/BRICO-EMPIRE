class_name BricoStoreFloor
extends Node2D
# Tiled store floor, cached: redrawn only when a purchase changes the surface.
var sim: BricoSimulation
func setup(simulation: BricoSimulation):
	sim = simulation
	show_behind_parent = true
	sim.purchased.connect(func(_a,_b): queue_redraw())
func p(v: Vector2) -> Vector2:
	return Vector2(v.x + v.y * 0.17,v.y * 0.9)
func floor_rect(r: Rect2, color: Color):
	draw_colored_polygon(PackedVector2Array([p(r.position),p(r.position+Vector2(r.size.x,0)),p(r.end),p(r.position+Vector2(0,r.size.y))]),color)
func shade(points: Array, from: Color, to: Color):
	# Two-tone strip: first two points take `from`, last two `to` (soft gradient).
	var packed := PackedVector2Array(); for point in points: packed.append(p(point))
	draw_polygon(packed,PackedColorArray([from,from,to,to]))
static func noise(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453,1.0)
func _draw():
	if sim == null: return
	floor_rect(Rect2(-30,-30,660,1000),Color("a39d88"))
	var top := 300 if sim.expansion == 0 else (140 if sim.expansion == 1 else 0)
	var light := Color("f7efde")
	var dark := Color("eee6d3")
	var scuffs := PackedVector2Array()
	for ty in range(top,900,60):
		for tx in range(0,600,60):
			var v := noise(tx,ty)
			var base := light if ((tx+ty)/60) % 2 == 0 else dark
			floor_rect(Rect2(tx,ty,60,60),base.darkened(v*0.05))
			# Subtle mottling inside each tile.
			floor_rect(Rect2(tx+8+v*20,ty+10+v*14,18,12),base.lightened(.04))
			if v > 0.8:
				var a := p(Vector2(tx+15+v*20,ty+30)); scuffs.append(a); scuffs.append(a+Vector2(14,2))
	if not scuffs.is_empty(): draw_multiline(scuffs,Color(0.45,0.38,0.3,.12),3)
	# Grout lines.
	var grout := PackedVector2Array()
	for y in range(top,901,60): grout.append(p(Vector2(0,y))); grout.append(p(Vector2(600,y)))
	for x in range(0,601,60): grout.append(p(Vector2(x,top))); grout.append(p(Vector2(x,900)))
	draw_multiline(grout,Color("e3d9c4"),1)
	# Continuous central aisle guides the eye from the entrance to the departments.
	floor_rect(Rect2(305,top+20,42,860-top),Color("e3eddf"))
	# Soft contact shadow at the foot of the back and left walls.
	shade([Vector2(12,top+12),Vector2(600,top+12),Vector2(600,top+46),Vector2(12,top+46)],Color(0.1,0.15,0.15,.16),Color(0.1,0.15,0.15,0))
	shade([Vector2(12,top+12),Vector2(12,900),Vector2(44,900),Vector2(44,top+12)],Color(0.1,0.15,0.15,.14),Color(0.1,0.15,0.15,0))
	# Daylight sheen from the entrance.
	shade([Vector2(230,900),Vector2(370,900),Vector2(420,620),Vector2(280,620)],Color(1,1,1,.16),Color(1,1,1,0))
