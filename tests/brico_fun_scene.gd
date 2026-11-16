extends SceneTree
var failures := 0
func expect(ok: bool, what: String):
	if not ok: failures += 1; printerr("BRICO FUN FAIL: "+what)
func _initialize(): call_deferred("run")
func shadow_count(node: Node) -> int:
	var count := 0
	if node is Light3D and node.shadow_enabled: count += 1
	if node is GeometryInstance3D and node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: count += 1
	for child in node.get_children(): count += shadow_count(child)
	return count
func run():
	root.size = Vector2i(540,960)
	var sim := BricoSimulation.new(123)
	var view := BricoStore3DView.new(); view.setup(sim); root.add_child(view)
	await process_frame; await physics_frame; await process_frame; view.set_process(false)
	var total: int = sim.inventory.total(); view.update_stock()
	expect(sim.inventory.total() == total,"rendering does not create stock")
	var products: Node3D = view.shelves.tools.get_node("Products")
	var before := products.get_child_count(); expect(before > 0,"stocked shelf has products")
	for i in range(40): view.update_stock()
	expect(products.get_child_count() == before,"unchanged stock does not leak geometry")
	var stock: int = sim.inventory.shelves.tools
	sim.inventory.shelves.tools = 0; view.update_stock()
	expect(products.get_child_count() == 0,"empty shelf has no hanging tools")
	expect(view.shelves.tools.get_node("StockLabel").visible,"empty stock has a text cue")
	sim.inventory.shelves.tools = stock; view.update_stock(); expect(sim.inventory.total() == total,"render refill preserves stock")
	var reserve: int = sim.inventory.reserve.tools
	sim.inventory.reserve.tools = 0; view.update_stock(); expect(view.reserve_products.get_child_count() == 0,"reserve boxes follow stock")
	sim.inventory.reserve.tools = reserve; view.update_stock(); expect(view.reserve_products.get_child_count() > 0,"reserve refill visible")
	expect(shadow_count(view) == 0,"no cast shadows")
	var picked := []; view.selected.connect(func(kind,id): picked.append([kind,id]))
	view.tap(view.camera.unproject_position(Vector3(2.3,.65,4.55)))
	expect(not picked.is_empty() and picked[0] == ["shelf","tools"],"3D ray selection")
	sim.money = 100000
	for action in [["shelf_capacity","tools"],["shelf_capacity","tools"],["unlock","paint"],["expand",""],["unlock","garden"],["checkout",""],["hire",""]]: expect(sim.progression.buy(action[0],action[1]),"purchase "+action[0])
	view.update_stock(); expect(view.shelves.has("garden") and view.cashiers.size() == 2,"extensions render content")
	view.focus = Vector3(1000,0,-1000); view.update_camera(); expect(view.focus.x <= 5.5 and view.focus.z >= 2,"camera bounds")
	view.zoom_at(100,Vector2(270,450)); expect(view.zoom >= view.MIN_ZOOM,"minimum zoom")
	view.zoom_at(.001,Vector2(270,450)); expect(view.zoom <= view.MAX_ZOOM,"maximum zoom")
	expect(sim.stock_audit() == 0,"rebuilds preserve inventory ledger"); expect(shadow_count(view) == 0,"rebuilds keep shadows off")
	print("BRICO FUN SCENE RESULT: ",failures," failures"); view.queue_free(); await process_frame; quit(1 if failures else 0)
