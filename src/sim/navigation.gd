class_name BricoNavigation
extends RefCounted
const CELL := 20.0
var grid := AStarGrid2D.new()
var revision := 0
var entrance := Vector2(300, 880)
var stock_point := Vector2(90, 370)
func rebuild(expansion: int, opened: Dictionary, cfg: BricoConfig):
	grid.region = Rect2i(0, 0, 30, 46)
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = Vector2(10, 10)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var top := 300 if expansion == 0 else (140 if expansion == 1 else 0)
	for y in range(46):
		for x in range(30):
			var p := Vector2(x * CELL + 10, y * CELL + 10)
			var blocked := p.y < top or x == 0 or x == 29 or y == 45
			for f in cfg.families:
				# Footprints are reserved even while closed; openings never invalidate a live route.
				if Rect2(f.rect[0], f.rect[1], f.rect[2], f.rect[3]).has_point(p): blocked = true
			for r in [Rect2(30, 300, 100, 40), Rect2(150, 760, 100, 55), Rect2(370, 760, 100, 55)]:
				if r.has_point(p): blocked = true
			grid.set_point_solid(Vector2i(x,y), blocked)
	revision += 1
func path(from: Vector2, target: Vector2) -> PackedVector2Array:
	var a := Vector2i(clampi(int(from.x/CELL),1,28),clampi(int(from.y/CELL),0,44))
	var b := Vector2i(clampi(int(target.x/CELL),1,28),clampi(int(target.y/CELL),0,44))
	if grid.is_point_solid(a) or grid.is_point_solid(b): return PackedVector2Array()
	var result := grid.get_point_path(a,b)
	if not result.is_empty(): result[result.size()-1] = target
	return result
static func move_agent(agent: RefCounted, delta: float, speed: float) -> bool:
	var remaining := speed * delta
	while not agent.route.is_empty() and remaining > 0:
		var target: Vector2 = agent.route[0]
		var distance: float = agent.pos.distance_to(target)
		if distance <= remaining:
			agent.pos = target
			agent.route.remove_at(0)
			remaining -= distance
		else:
			agent.direction = (target - agent.pos).normalized()
			agent.pos = agent.pos.move_toward(target, remaining)
			remaining = 0
	return agent.route.is_empty()
