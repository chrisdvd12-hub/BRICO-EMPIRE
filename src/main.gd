extends Node
const STEP := 1.0/30
var sim: BricoSimulation
var save_store := BricoSaveStore.new()
var view: BricoStoreView
var ui: BricoGameUI
var accumulator := 0.0
var save_timer := 0.0
var suspended := false
var speed := 1.0
var developer := false
var offline_notice := ""
var sale_save_pending := false
func _ready():
	developer = "--dev" in OS.get_cmdline_user_args()
	if "--smoke" in OS.get_cmdline_user_args(): save_store = BricoSaveStore.new("user://smoke_save.json")
	start_game()
func start_game():
	sim = BricoSimulation.new()
	var data := save_store.load_data()
	var now := int(Time.get_unix_time_from_system())
	if not data.is_empty():
		sim.restore(data)
		apply_offline(data,now)
	view = BricoStoreView.new(); view.setup(sim); add_child(view)
	ui = BricoGameUI.new(); add_child(ui); ui.setup(sim,view,developer)
	var audio := BricoAudio.new(); audio.name = "Audio"; add_child(audio); audio.setup(sim)
	ui.save_requested.connect(save_game)
	ui.reset_requested.connect(reset_game)
	ui.speed_changed.connect(func(value): speed = value)
	sim.purchased.connect(func(_a,_b): save_game())
	sim.sale.connect(func(_amount,_position): sale_save_pending = true)
	if not offline_notice.is_empty(): ui.show_toast(offline_notice); offline_notice = ""
	elif not save_store.warning.is_empty(): ui.show_toast(save_store.warning)
	save_game()
func apply_offline(data: Dictionary, now: int):
	var estimate := save_store.offline_amount(data,now,sim.cfg)
	if estimate.amount <= 0: return
	sim.money += estimate.amount
	# Persist before presenting reward; reloading cannot credit the same absence twice.
	if save_store.write(sim.snapshot(now)):
		offline_notice = "Absence estimée : +%d pièces pour %d min (40 %% du rythme encaissé, plafond 2 h)." % [estimate.amount,estimate.seconds/60]
	else:
		sim.money -= estimate.amount
		offline_notice = "Estimation hors ligne non créditée : sauvegarde indisponible."
func save_game():
	if sim == null: return
	if not save_store.write(sim.snapshot(int(Time.get_unix_time_from_system()))) and ui != null: ui.show_toast(save_store.warning)
func reset_game():
	save_store.reset()
	view.queue_free(); ui.queue_free(); get_node("Audio").queue_free()
	# Defer recreation until the old audio node has left the tree.
	call_deferred("restart")
func restart():
	accumulator = 0; save_timer = 0; speed = 1
	start_game()
func _process(dt: float):
	if sim == null or suspended: return
	# Bound catch-up. Real absences use offline estimation, never an unbounded tick.
	accumulator += minf(dt,0.15)*speed
	var old_tutorial := sim.tutorial
	var steps := 0
	while accumulator >= STEP and steps < 80:
		sim.tick(STEP); accumulator -= STEP; steps += 1
	if sim.tutorial != old_tutorial or sale_save_pending:
		sale_save_pending = false
		save_game()
	save_timer += minf(dt,.15)
	if save_timer >= sim.cfg.v("autosave_seconds"):
		save_timer = 0; save_game()
func _notification(what: int):
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if sim != null and not suspended:
			suspended = true; save_game(); accumulator = 0
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if sim != null and suspended:
			var data := save_store.load_data()
			if not data.is_empty(): apply_offline(data,int(Time.get_unix_time_from_system()))
			suspended = false; accumulator = 0; save_game()
			if ui != null and not offline_notice.is_empty(): ui.show_toast(offline_notice); offline_notice = ""
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(); get_tree().quit()
