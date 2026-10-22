extends SceneTree
var failures := 0
var game
func expect(ok: bool, what: String):
	if not ok: failures += 1; printerr("3D FAIL: "+what)
func frame():
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func shot(name: String):
	await frame(); root.get_texture().get_image().save_png("res://docs/"+name+".png")
func _initialize(): call_deferred("run")
func touch(at: Vector2, down: bool):
	var e := InputEventScreenTouch.new(); e.position = at; e.pressed = down; Input.parse_input_event(e)
func run():
	root.size = Vector2i(540,960)
	game = load("res://main.tscn").instantiate(); root.add_child(game)
	await frame(); game.set_process(false)
	var view: BricoStore3DView = game.view
	var ui: BricoGameUI = game.ui
	expect(view.camera.projection == Camera3D.PROJECTION_ORTHOGONAL,"real orthographic Camera3D")
	expect(view.scenery.get_child_count() > 50,"volumetric scene contains furniture")
	for _i in range(30*70): game.sim.tick(1.0/30)
	await frame(); ui.refresh(); ui.toast_timer = 0; ui.toasts.clear()
	expect(game.sim.total_sales > 0 and game.sim.restock_count > 0,"3D presentation keeps complete sales and restocks")
	expect(game.sim.stock_audit() == 0,"stock conserved")
	await shot("12-3d-boutique")
	# Projection / ray query uses a mesh point, not an approximate 2D hit rectangle.
	var at := view.camera.unproject_position(Vector3(2.3,.72,4.55))
	touch(at,true); await frame(); touch(at,false); await frame()
	expect(ui.selection == "shelf" and ui.selected_id == "tools","touch ray selects real 3D shelf")
	await shot("13-3d-amelioration")
	var before: int = game.sim.capacity("tools")
	var button: Button = ui.rows[0].button
	var point := button.get_global_rect().get_center()
	touch(point,true); await frame(); touch(point,false); await frame()
	expect(game.sim.capacity("tools") == before+4,"touch upgrade changes capacity exactly once")
	ui.close_sheet(); await frame()
	# A two-finger stream changes the real orthographic zoom and never selects furniture.
	var prior_zoom := view.zoom
	for i in range(2):
		var e := InputEventScreenTouch.new(); e.index = i; e.position = Vector2(200+i*100,450); e.pressed = true; Input.parse_input_event(e)
	var drag := InputEventScreenDrag.new(); drag.index = 1; drag.position = Vector2(380,450); drag.relative = Vector2(80,0); Input.parse_input_event(drag)
	for i in range(2):
		var e := InputEventScreenTouch.new(); e.index = i; e.position = Vector2(200+i*180,450); e.pressed = false; Input.parse_input_event(e)
	await frame()
	expect(view.zoom < prior_zoom and ui.selection.is_empty(),"3D two-finger pinch does not select")
	game.sim.settings.graphics_low = true; await frame()
	expect(not view.sun.shadow_enabled and root.scaling_3d_scale == .75,"low graphics changes shadows and resolution")
	game.sim.settings.graphics_low = false; await frame()
	var old_focus := view.focus
	view.pan(Vector2(240,420),Vector2(310,460))
	expect(view.focus != old_focus,"camera pans on ground plane")
	view.zoom_at(100,Vector2(270,460)); expect(view.zoom >= view.MIN_ZOOM,"minimum camera distance")
	view.zoom_at(.001,Vector2(270,460)); expect(view.zoom <= view.MAX_ZOOM,"maximum camera distance")
	view.focus = Vector3(1000,0,-1000); view.update_camera()
	expect(view.focus.x <= 5.5 and view.focus.z >= 2,"camera property boundary")
	game.sim.money = 100000
	for purchase in [["unlock","paint"],["expand",""],["unlock","garden"],["checkout",""],["hire",""],["expand",""],["unlock","electric"],["unlock","plumbing"],["hire",""]]:
		expect(game.sim.progression.buy(purchase[0],purchase[1]),"3D purchase: "+purchase[0])
	game.sim.tutorial = 5
	for _i in range(30*120): game.sim.tick(1.0/30)
	ui.refresh(); ui.toast_timer = 0; ui.toasts.clear(); view.recenter()
	await shot("14-3d-magasin")
	expect(view.shelves.size() == 5 and game.sim.total_sales > 20,"five volumetric departments trade")
	expect(game.sim.stock_audit() == 0,"multiple employees conserve stock")
	# All navigation points remain accessible in the projected XZ plane.
	for f in game.sim.cfg.families:
		expect(not game.sim.nav.path(game.sim.nav.entrance,Vector2(f.customer[0][0],f.customer[0][1])).is_empty(),"navigation reaches "+f.id)
	# Restore an existing genuine release save without a reset or a format change.
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy_v2.json"))
	var restored := BricoSimulation.new(); restored.restore(old)
	expect(restored.money == int(old.money) and restored.tutorial == 5,"existing save preserved")
	var saved: Dictionary = game.sim.snapshot(1000)
	restored.restore(saved); expect(restored.money == game.sim.money and restored.opened == game.sim.opened,"3D save round trip")
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED); expect(game.suspended,"background suspends simulation")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED); expect(not game.suspended,"resume works")
	print("3D RESULT: ",failures," failures; draw calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," objects=",Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	game.save_store.reset(); game.queue_free(); await process_frame; game = null; call_deferred("quit",1 if failures else 0)
