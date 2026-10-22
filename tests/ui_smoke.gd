extends SceneTree
var failures := 0
var game
func expect(condition: bool, message: String):
	if not condition: failures += 1; printerr("UI FAIL: "+message)
func _initialize(): call_deferred("run")
func frame():
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String):
	await frame()
	var image := root.get_texture().get_image()
	image.save_png("res://docs/"+name+".png")
func mouse_button(pos: Vector2, pressed: bool):
	var event := InputEventMouseButton.new(); event.position = pos; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
	Input.parse_input_event(event)
func touch_at(pos: Vector2, down: bool, index := 0):
	var e := InputEventScreenTouch.new(); e.index = index; e.position = pos; e.pressed = down
	Input.parse_input_event(e)
func touch_button(b: Button):
	var at := b.get_global_rect().get_center()
	touch_at(at,true); await frame(); touch_at(at,false); await frame()
func run():
	root.size = Vector2i(540,960)
	var main := load("res://main.tscn") as PackedScene
	game = main.instantiate(); game.legacy_2d = true; root.add_child(game)
	await frame()
	game.set_process(false)
	for i in range(30*70): game.sim.tick(1.0/30)
	game.ui.refresh()
	game.ui.toast_timer = 0; game.ui.toasts.clear()
	await capture("01-boutique")
	var view: BricoStoreView = game.view
	var ui: BricoGameUI = game.ui
	var shelf: Vector2 = view.camera_offset+view.p(Vector2(210,440))*view.camera_zoom
	mouse_button(shelf,true); mouse_button(shelf,false)
	await frame()
	expect(ui.selection == "shelf" and ui.selected_id == "tools","mouse selects shelf")
	await capture("02-ameliorations")
	var old_money: int = game.sim.money
	var old_camera: Vector2 = view.camera_offset
	# Input on panel must not move camera or select furniture underneath.
	mouse_button(Vector2(300,900),true)
	var motion := InputEventMouseMotion.new(); motion.position = Vector2(330,850); motion.relative = Vector2(30,-50); Input.parse_input_event(motion)
	mouse_button(Vector2(330,850),false)
	await frame()
	expect(view.camera_offset == old_camera,"UI blocks store gesture passthrough")
	ui.close_sheet(); await frame()
	# Drag across a shelf must not open its panel.
	mouse_button(shelf,true)
	motion = InputEventMouseMotion.new(); motion.position = shelf+Vector2(80,20); motion.relative = Vector2(80,20); Input.parse_input_event(motion)
	mouse_button(shelf+Vector2(80,20),false)
	await frame()
	expect(ui.selection.is_empty(),"drag does not select")
	expect(view.camera_offset != old_camera,"mouse drag pans")
	view.recenter()
	var zoom_before := view.camera_zoom
	# Actual two-finger InputEvent stream.
	for item in [[0,Vector2(200,400)],[1,Vector2(300,400)]]:
		var touch := InputEventScreenTouch.new(); touch.index = item[0]; touch.position = item[1]; touch.pressed = true; Input.parse_input_event(touch)
	for x in [320,380]:
		var drag := InputEventScreenDrag.new(); drag.index = 1; drag.position = Vector2(x,400); drag.relative = Vector2(20,0); Input.parse_input_event(drag)
	for i in [0,1]:
		var release := InputEventScreenTouch.new(); release.index = i; release.position = Vector2(200 if i == 0 else 380,400); release.pressed = false; Input.parse_input_event(release)
	await frame()
	expect(view.camera_zoom > zoom_before,"two-finger pinch zooms")
	expect(ui.selection.is_empty(),"pinch does not select")
	view.recenter()
	# All four real Controls must respond to a native touch, with empty visible labels.
	for kind in ["workers","build","achievements","settings"]:
		var b: Button = ui.nav_buttons[kind]
		expect(b.text.is_empty() and b.icon != null,"navigation is icon-only: "+kind)
		expect(b.get_meta("cta") == "nav","navigation shares one colour: "+kind)
		await touch_button(b)
		expect(ui.selection == kind,"touch opens GUI menu: "+kind)
		var body: Control = ui.sheet.get_child(0).get_child(0)
		expect(body.get_global_rect().end.x <= ui.root.size.x,"sheet fits portrait width: "+kind)
		expect(not view.held and view.fingers.is_empty(),"UI touch leaves no world gesture")
		ui.close_sheet(); await frame()
	# A single touch buys once; generated mouse events must never select the world.
	ui.open_sheet("shelf","tools"); await frame()
	var cap_before: int = game.sim.capacity("tools")
	var cash_before: int = game.sim.money
	var price: int = game.sim.progression.cost("shelf_capacity","tools")
	await touch_button(ui.rows[0].button)
	expect(game.sim.capacity("tools") == cap_before+game.sim.cfg.v("capacity_step"),"touch upgrade applied exactly once")
	expect(game.sim.money == cash_before-price,"touch upgrade charged exactly once")
	ui.close_sheet(); await frame()
	# Hard limits clamp both axes at every supported zoom, preserving the property.
	for z in [.5,.8,1.3]:
		view.camera_zoom = z
		for extreme in [Vector2(-1e6,-1e6),Vector2(1e6,1e6)]:
			view.camera_offset = extreme; view.clamp_camera()
			var bounds := view.projected_map_bounds()
			var screen := Rect2(bounds.position*z+view.camera_offset,bounds.size*z)
			expect(screen.position.x <= 0.1 and screen.end.x >= 539.9,"horizontal camera stays inside map")
			expect(screen.position.y <= 196.1 and screen.end.y >= 781.9,"vertical camera stays inside map")
	view.recenter()
	game.sim.money = 50000
	for action in [["unlock","paint"],["expand",""],["unlock","garden"],["checkout",""],["hire",""],["expand",""],["unlock","electric"],["unlock","plumbing"],["hire",""]]: game.sim.progression.buy(action[0],action[1])
	game.sim.tutorial = 5
	for i in range(30*120): game.sim.tick(1.0/30)
	ui.refresh()
	ui.toast_timer = 0; ui.toasts.clear()
	await capture("03-magasin-agrandi")
	ui.open_sheet("workers",""); await capture("04-equipe")
	ui.close_sheet(); await frame()
	var orphan_count := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for _i in range(6):
		ui.open_sheet("stats",""); await frame()
		ui.close_sheet(); await frame()
	expect(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphan_count,"reopening statistics does not leak orphan nodes")
	# Touch selection at projected coordinates.
	shelf = view.camera_offset+view.p(Vector2(210,440))*view.camera_zoom
	var down := InputEventScreenTouch.new(); down.index = 0; down.position = shelf; down.pressed = true; Input.parse_input_event(down)
	var up := InputEventScreenTouch.new(); up.index = 0; up.position = shelf; up.pressed = false; Input.parse_input_event(up)
	await frame()
	expect(ui.selection == "shelf","single touch selects")
	ui.close_sheet(); await frame()
	# Pause lifecycle must stop simulation; long absence credited once on resume.
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	expect(game.suspended,"pause marks simulation suspended")
	var saved: Dictionary = game.save_store.load_data()
	saved.last_saved = int(Time.get_unix_time_from_system())-120
	game.save_store.write(saved)
	var before: int = game.sim.money
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(not game.suspended and game.sim.money > before,"resume credits observed absence")
	var credited: int = game.sim.money
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	expect(game.sim.money == credited,"duplicate resume cannot credit again")
	root.size = Vector2i(360,640)
	await capture("05-petit-ecran")
	expect(ui.root.size.x >= 360,"UI remains sized on small screen")
	print("UI RESULT: ",failures," failures")
	game.save_store.reset()
	game.queue_free(); await process_frame; await process_frame
	game = null
	call_deferred("quit",1 if failures else 0)
