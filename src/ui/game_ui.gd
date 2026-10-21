class_name BricoGameUI
extends CanvasLayer
signal save_requested
signal reset_requested
signal speed_changed(value: float)
var sim: BricoSimulation
var view: BricoStoreView
var root: Control
var money_label: Label
var objective: Label
var status: Label
var advice: Label
var tutorial_label: Label
var tutorial_box: PanelContainer
var sheet: PanelContainer
var content: VBoxContainer
var rows: Array = []
var live_labels: Array = []
var selection := ""
var selected_id := ""
var refresh_timer := 0.0
var toast_label: Label
var toast_timer := 0.0
var confirm_reset := false
var dev := false
const TEAL := Color("174956")
const PAPER := Color("fff5e2")
const MUTED := Color("526b68")
func setup(simulation: BricoSimulation, store_view: BricoStoreView, developer: bool):
	sim = simulation
	view = store_view
	dev = developer
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color","Label",TEAL)
	theme.set_color("font_color","Button",PAPER)
	theme.set_color("font_disabled_color","Button",Color("e1e2d7"))
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = TEAL if state == "normal" else (Color("267282") if state == "hover" else (Color("0c3542") if state == "pressed" else Color("83938c")))
		style.set_corner_radius_all(12)
		style.content_margin_left = 12; style.content_margin_right = 12
		style.content_margin_top = 8; style.content_margin_bottom = 8
		theme.set_stylebox(state,"Button",style)
	root.theme = theme
	var header := panel_at(Vector2(12,12),Vector2(516,184),PAPER)
	var top := VBoxContainer.new(); top.add_theme_constant_override("separation",3); header.add_child(top)
	var title := label("BRICO EMPIRE     /     ATELIER 01",16); top.add_child(title)
	var money_row := HBoxContainer.new(); top.add_child(money_row)
	money_label = label("",34); money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; money_row.add_child(money_label)
	var center := button("Recentrer",view.recenter); center.custom_minimum_size.x = 128; money_row.add_child(center)
	objective = label("",21); top.add_child(objective)
	status = label("",18); top.add_child(status)
	var bottom := panel_at(Vector2(12,782),Vector2(516,166),PAPER)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12; bottom.offset_right = -12; bottom.offset_top = -178; bottom.offset_bottom = -12
	var bottom_box := VBoxContainer.new(); bottom_box.add_theme_constant_override("separation",8); bottom.add_child(bottom_box)
	advice = label("",22); bottom_box.add_child(advice)
	var menu := HBoxContainer.new(); menu.add_theme_constant_override("separation",8); bottom_box.add_child(menu)
	for item in [["Équipe","workers"],["Construire","build"],["Réglages","settings"]]:
		var b := button(item[0],func(): open_sheet(item[1],"")); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; menu.add_child(b)
	tutorial_box = panel_at(Vector2(12,640),Vector2(516,125),Color("e3eed5"))
	tutorial_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tutorial_box.offset_left = 12; tutorial_box.offset_right = -12; tutorial_box.offset_top = -318; tutorial_box.offset_bottom = -190
	var tuto := HBoxContainer.new(); tutorial_box.add_child(tuto)
	tutorial_label = label("",22); tutorial_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tuto.add_child(tutorial_label)
	var skip := button("Passer",func(): sim.tutorial = 5; save_requested.emit()); skip.custom_minimum_size.x = 98; tuto.add_child(skip)
	toast_label = label("",18)
	toast_label.position = Vector2(24,205); toast_label.size = Vector2(492,90)
	toast_label.add_theme_color_override("font_color",PAPER)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_label)
	view.selected.connect(open_sheet)
	root.resized.connect(apply_safe_area)
	apply_safe_area()
func apply_safe_area():
	if not OS.has_feature("mobile"): return
	var safe := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if window_size.y > 0:
		var ratio := root.size.y/window_size.y
		root.offset_top = maxf(0,safe.position.y*ratio)
		root.offset_bottom = -maxf(0,(window_size.y-safe.end.y)*ratio)
func label(text: String, size := 19) -> Label:
	var l := Label.new(); l.text = text; l.add_theme_font_size_override("font_size",size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
func button(text: String, callback: Callable) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 72
	b.pressed.connect(callback)
	return b
func panel_at(at: Vector2, dimensions: Vector2, color: Color) -> PanelContainer:
	var panel := PanelContainer.new(); panel.position = at; panel.size = dimensions
	var style := StyleBoxFlat.new(); style.bg_color = color; style.set_corner_radius_all(18)
	style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	return panel
func show_toast(text: String):
	toast_label.text = text; toast_timer = 8
func close_sheet():
	if is_instance_valid(sheet): sheet.queue_free()
	sheet = null; rows.clear(); live_labels.clear(); selection = ""; confirm_reset = false
	view.cancel_gestures()
func open_sheet(kind: String, id: String):
	close_sheet()
	selection = kind; selected_id = id
	view.cancel_gestures()
	if kind == "shelf" and id == "tools" and sim.tutorial == 1:
		sim.tutorial = 2; save_requested.emit()
	# Full-screen modal input shield prevents touches through UI, even over empty margins.
	sheet = PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	var transparent := StyleBoxFlat.new(); transparent.bg_color = Color(0.02,.12,.15,.25)
	sheet.add_theme_stylebox_override("panel",transparent)
	root.add_child(sheet)
	var body := PanelContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	body.offset_top = -570; body.offset_bottom = -12; body.offset_left = 12; body.offset_right = -12
	var style := StyleBoxFlat.new(); style.bg_color = PAPER; style.set_corner_radius_all(22)
	style.content_margin_left = 18; style.content_margin_right = 18; style.content_margin_top = 14; style.content_margin_bottom = 14
	body.add_theme_stylebox_override("panel",style)
	# A plain Control ensures the bottom sheet can anchor independently of PanelContainer layout.
	var overlay := Control.new(); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; sheet.add_child(overlay); overlay.add_child(body)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",12); body.add_child(column)
	var heading := HBoxContainer.new(); column.add_child(heading)
	var titles := {"shelf":sim.cfg.family(id).get("name","Rayon"),"workers":"Équipe de réassort","checkout":"Caisse %d" % (int(id)+1),"reserve":"Réserve & livraisons","expand":"Agrandir le magasin","build":"Construire & grandir","settings":"Réglages"}
	var title := label(titles.get(kind,"Brico Empire"),25); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; heading.add_child(title)
	heading.add_child(button("Fermer",close_sheet))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",12); scroll.add_child(content)
	match kind:
		"shelf":
			if not sim.opened[id]:
				content.add_child(label("Livraisons gratuites et emplacement fixe. Le réassort commencera dès la prochaine livraison."))
				purchase_row("unlock",id,"Ouvrir ce rayon",func(): return "%d pièces par vente · capacité %d" % [sim.sale_value(id),sim.capacity(id)])
			else:
				live(func(): return "En rayon : %d/%d · Réserve : %d/%d" % [sim.inventory.shelves[id],sim.capacity(id),sim.inventory.reserve[id],sim.reserve_capacity()])
				purchase_row("shelf_capacity",id,"Capacité",func(): return "Niv. %d/5 · %d → %d unités" % [sim.levels[id].capacity,sim.capacity(id),sim.capacity(id)+sim.cfg.v("capacity_step")])
				purchase_row("shelf_value",id,"Valeur des produits",func():
					var next_value := int(round(sim.cfg.family(id).price*(1.0+sim.levels[id].value*sim.cfg.v("value_step"))))
					return "Niv. %d/5 · %d → %d pièces / vente" % [sim.levels[id].value,sim.sale_value(id),next_value])
				purchase_row("shelf_service",id,"Prise du produit",func(): return "Niv. %d/5 · %.1f → %.1f s" % [sim.levels[id].service,sim.pick_time(id),sim.pick_time(id)*sim.cfg.v("speed_factor")])
		"workers":
			live(func():
				var states := ""
				var names := ["Disponible","Vers la réserve","Charge un lot","Transporte","Remplit le rayon"]
				for w in sim.workers: states += "Employé %d : %s%s\n" % [w.id+1,names[w.state]," · attend la livraison" if w.waiting_goods else ""]
				return states.strip_edges())
			purchase_row("hire","","Recruter",func(): return "%d/%d employés · poste autonome" % [sim.workers.size(),sim.cfg.v("max_workers")])
			purchase_row("worker_speed","","Déplacement de l’équipe",func(): return "Niv. %d/5 · %.0f → %.0f unités/s" % [sim.worker_levels.speed,sim.worker_speed(),sim.worker_speed()+sim.cfg.v("worker_speed")*sim.cfg.v("worker_speed_step")])
			purchase_row("worker_carry","","Lot transporté",func(): return "Niv. %d/5 · %d → %d unités" % [sim.worker_levels.carry,sim.carry_capacity(),sim.carry_capacity()+sim.cfg.v("carry_step")])
			purchase_row("worker_restock","","Vitesse de réassort",func(): return "Niv. %d/5 · %.1f → %.1f s" % [sim.worker_levels.restock,sim.restock_time(),sim.restock_time()*sim.cfg.v("speed_factor")])
		"checkout":
			if int(id) >= sim.checkouts:
				purchase_row("checkout","","Ouvrir la seconde caisse",func(): return "Caissier inclus · %.1f s / client" % sim.checkout_time(1))
			else:
				live(func(): return "%d client(s) dans la file · encaissement automatique" % sim.queues[int(id)].size())
				purchase_row("cash_speed",id,"Encaissement",func(): return "Niv. %d/5 · %.1f → %.1f s / client" % [sim.cash_levels[int(id)],sim.checkout_time(int(id)),sim.checkout_time(int(id))*sim.cfg.v("speed_factor")])
		"reserve":
			content.add_child(label("Chaque famille possède sa propre capacité. Les marchandises sont gratuites ; seuls les achats encaissés rapportent de l’argent."))
			live(func():
				var t := "Prochaine livraison : %d s\n" % ceili(sim.delivery_timer)
				for f in sim.cfg.families:
					if sim.opened[f.id]: t += "%s : %d/%d%s\n" % [f.name,sim.inventory.reserve[f.id],sim.reserve_capacity()," · PLEINE" if sim.inventory.reserve[f.id] >= sim.reserve_capacity() else ""]
				return t.strip_edges())
			content.add_child(label("Le grand dépôt porte la réserve à 48 unités par famille. Après rechargement, les marchandises en transit sont récupérées ici ; un dépassement temporaire est possible.",17))
		"build", "expand":
			for f in sim.cfg.families:
				if not sim.opened[f.id]: purchase_row("unlock",f.id,"Ouvrir : " + f.name,func(): return "Vente : %d pièces · %d unités en rayon" % [sim.sale_value(f.id),sim.capacity(f.id)])
			purchase_row("expand","","Agrandissement %d/2" % mini(2,sim.expansion+1),func(): return "Nouvelle aile : surface jardinage + réception" if sim.expansion == 0 else "Grand dépôt : réserve 24 → 48 ; rayons +4 unités")
			if sim.checkouts < 2: purchase_row("checkout","","Deuxième caisse",func(): return "Caissier inclus · une file supplémentaire")
		"settings":
			var sound := CheckButton.new(); sound.text = "Sons"; sound.button_pressed = sim.settings.sound; sound.custom_minimum_size.y = 72; content.add_child(sound)
			sound.toggled.connect(func(enabled): sim.settings.sound = enabled; save_requested.emit())
			var effects_button := CheckButton.new(); effects_button.text = "Réduire les effets visuels"; effects_button.button_pressed = sim.settings.reduced_effects; effects_button.custom_minimum_size.y = 72; content.add_child(effects_button)
			effects_button.toggled.connect(func(enabled): sim.settings.reduced_effects = enabled; save_requested.emit())
			content.add_child(label("Sauvegarde locale automatique · aucune publicité ni achat intégré. Les sons sont synthétisés ; aucune musique dans cette version.",17))
			var reset_button := button("Réinitialiser la partie",func():
				if confirm_reset: reset_requested.emit()
				else:
					confirm_reset = true
					content.add_child(label("Attention : toute la progression sera effacée. Appuyez de nouveau sur Réinitialiser pour confirmer.",18)))
			content.add_child(reset_button)
			if dev: developer_controls()
	refresh()
func live(getter: Callable):
	var l := label(""); content.add_child(l); live_labels.append([l,getter])
func purchase_row(action: String, target: String, title: String, effect: Callable):
	var group := VBoxContainer.new(); group.add_theme_constant_override("separation",4); content.add_child(group)
	group.add_child(label(title,21))
	var detail := label("",21); group.add_child(detail)
	var buy := button("",func():
		if sim.progression.buy(action,target):
			var k := selection; var i := selected_id
			open_sheet(k,i)
		else:
			show_toast(sim.progression.reason(action,target)); refresh())
	group.add_child(buy)
	var reason_label := label("",15); group.add_child(reason_label)
	rows.append({"action":action,"target":target,"detail":detail,"effect":effect,"button":buy,"reason":reason_label})
func developer_controls():
	content.add_child(label("DÉVELOPPEUR · --dev",21))
	for n in [1,4,16]: content.add_child(button("Simulation ×%d" % n,func(): speed_changed.emit(float(n))))
	content.add_child(button("Ajouter 5 000 pièces",func(): sim.money += 5000; save_requested.emit()))
	content.add_child(button("États des agents",func(): view.debug_states = not view.debug_states))
	content.add_child(button("Ouvrir l’étape suivante",func():
		var action := "unlock"; var target := "paint"
		if sim.opened.paint:
			if sim.expansion == 0: action = "expand"; target = ""
			elif not sim.opened.garden: target = "garden"
			elif sim.expansion == 1: action = "expand"; target = ""
			else: return
		sim.money += sim.progression.cost(action,target)
		sim.progression.buy(action,target)))
	live(func(): return "Audit stock : %d (attendu 0)\nTâches : %s\nStocks : %s\nClients : %d/%d" % [sim.stock_audit(),str(sim.tasks),str(sim.inventory.shelves),sim.customers.size(),sim.cfg.v("max_clients")])
func refresh():
	if not is_instance_valid(money_label): return
	money_label.text = "%s pièces" % format_money(sim.money)
	objective.text = sim.progression.objective()
	var rpm := sim.measured_rpm()
	status.text = "%s · Livraison %d s · %d clients" % ["Mesure des ventes…" if rpm < 0 else "%.0f pièces/min observées" % rpm,ceili(sim.delivery_timer),sim.customers.size()]
	advice.text = sim.advice
	tutorial_box.visible = sim.tutorial < 5
	var steps := ["1/5 · Observez une vente : un client prend un produit, puis paie.","2/5 · Touchez le rayon outillage pour voir ses améliorations.","3/5 · Achetez une amélioration. La première coûte 100 pièces.","4/5 · Observez l’employé : il transporte un carton de la réserve au rayon.","5/5 · Prochain objectif : la peinture, 300 pièces. Touchez ici pour terminer."]
	if sim.tutorial < 5: tutorial_label.text = steps[sim.tutorial]
	for row in rows:
		var why: String = sim.progression.reason(row.action,row.target)
		var maxed := why in ["Niveau maximal","Équipe au complet","Magasin entièrement agrandi","Les deux caisses sont ouvertes"]
		row.detail.text = str(row.effect.call()).split(" → ")[0] + " · au maximum" if maxed else row.effect.call()
		row.button.text = "Niveau maximal" if maxed else "Acheter · %d pièces" % sim.progression.cost(row.action,row.target)
		row.button.disabled = not why.is_empty()
		row.reason.text = why
		row.reason.visible = not why.is_empty()
	for item in live_labels: item[0].text = item[1].call()
static func format_money(amount: int) -> String:
	var raw := str(amount); var result := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length()-i)%3 == 0: result += " "
		result += raw[i]
	return result
func _process(dt: float):
	refresh_timer -= dt
	if refresh_timer <= 0: refresh_timer = .3; refresh()
	toast_timer -= dt
	if is_instance_valid(toast_label): toast_label.visible = toast_timer > 0
func _input(event: InputEvent):
	if sim == null: return
	if sim.tutorial == 4 and not is_instance_valid(sheet):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
			if tutorial_box.get_global_rect().has_point(event.position): sim.tutorial = 5; save_requested.emit(); get_viewport().set_input_as_handled()
