class_name BricoGameUI
extends CanvasLayer
signal save_requested
signal reset_requested
signal speed_changed(value: float)
signal import_requested(code: String)
var sim: BricoSimulation
var view: BricoStoreView
var root: Control
var money_label: Label
var title_label: Label
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
# Call-to-action palette: [fill, text]. Each role gets its own colour.
const KINDS := {"buy":["2f9e6a","ffffff"],"build":["2f9e6a","ffffff"],"team":["e8893a","ffffff"],"trophy":["f2c14e","4a3306"],"options":["5b6f7a","ffffff"],"camera":["2f7fd0","ffffff"],"close":["d9634c","ffffff"],"skip":["ffffff","174956"],"danger":["c2492f","ffffff"],"default":["174956","fff5e2"],"maxed":["f2c14e","4a3306"],"stats":["8c6bc4","ffffff"],"gold":["e0a526","3b2a05"]}
var styles := {}
var bold: FontVariation
var build_button: Button
var build_ready := false
var pulse := 0.0
var toasts: Array = []
var confirm_franchise := false
var confirm_import := false
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
	bold = FontVariation.new(); bold.base_font = ThemeDB.fallback_font; bold.variation_embolden = 0.6
	var header := panel_at(Vector2(12,12),Vector2(516,184),PAPER)
	var top := VBoxContainer.new(); top.add_theme_constant_override("separation",3); header.add_child(top)
	title_label = label("BRICO EMPIRE     /     ATELIER 01",16); top.add_child(title_label)
	var money_row := HBoxContainer.new(); top.add_child(money_row)
	money_row.add_theme_constant_override("separation",8)
	money_label = label("",31); money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; money_row.add_child(money_label)
	money_row.add_child(button("Stats",func(): open_sheet("stats",""),"stats"))
	var center := button("Recentrer",view.recenter,"camera"); money_row.add_child(center)
	objective = label("",21); top.add_child(objective)
	status = label("",18); top.add_child(status)
	# Header lines never wrap: a long objective must not push the status out of the panel.
	for l in [title_label,objective,status]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF; l.clip_text = true; l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var bottom := panel_at(Vector2(12,782),Vector2(516,166),PAPER)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 12; bottom.offset_right = -12; bottom.offset_top = -178; bottom.offset_bottom = -12
	var bottom_box := VBoxContainer.new(); bottom_box.add_theme_constant_override("separation",8); bottom.add_child(bottom_box)
	advice = label("",22); bottom_box.add_child(advice)
	var menu := HBoxContainer.new(); menu.add_theme_constant_override("separation",8); bottom_box.add_child(menu)
	for item in [["Équipe","workers","team"],["Construire","build","build"],["Succès","achievements","trophy"],["Options","settings","options"]]:
		# Four entries share the bar: smaller text and compact margins keep them on one row.
		var b := button(item[0],func(): open_sheet(item[1],""),item[2],true); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size",20)
		if item[1] == "build": build_button = b
		menu.add_child(b)
	tutorial_box = panel_at(Vector2(12,640),Vector2(516,125),Color("e3eed5"))
	tutorial_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tutorial_box.offset_left = 12; tutorial_box.offset_right = -12; tutorial_box.offset_top = -318; tutorial_box.offset_bottom = -190
	var tuto := HBoxContainer.new(); tutorial_box.add_child(tuto)
	tutorial_label = label("",22); tutorial_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tuto.add_child(tutorial_label)
	var skip := button("Passer",func(): sim.tutorial = 5; save_requested.emit(),"skip"); skip.custom_minimum_size.x = 98; tuto.add_child(skip)
	toast_label = label("",18)
	toast_label.position = Vector2(24,205); toast_label.size = Vector2(492,0)
	toast_label.add_theme_color_override("font_color",PAPER)
	var toast_style := StyleBoxFlat.new(); toast_style.bg_color = Color(0.06,.2,.24,.88); toast_style.set_corner_radius_all(12)
	toast_style.content_margin_left = 12; toast_style.content_margin_right = 12; toast_style.content_margin_top = 8; toast_style.content_margin_bottom = 8
	toast_label.add_theme_stylebox_override("normal",toast_style)
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast_label)
	view.selected.connect(open_sheet)
	sim.achieved.connect(func(a):
		show_toast("Succès débloqué : %s · +%d pièces" % [a.name,a.reward])
		show_tip("achievements","Ouvrez « Succès » pour suivre tous les objectifs, dont l’objectif du jour."))
	sim.event_started.connect(func(e):
		show_toast("%s ! %s" % [e.name,e.text])
		show_tip("events","Les événements durent quelques secondes : profitez-en pour avoir des rayons bien remplis."))
	sim.daily_completed.connect(func(d): show_toast("Objectif du jour réussi ! +%d pièces" % d.reward))
	sim.new_day.connect(func(d): show_toast("Jour %d · Objectif du jour : %s (+%d pièces)" % [d,sim.daily_text(),sim.daily.reward]))
	sim.franchised.connect(func(level): show_toast("Atelier %02d ouvert ! Toutes les ventes rapportent +%d %% pour toujours." % [level+1,int(round((sim.franchise_multiplier()-1)*100))]))
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
func button(text: String, callback: Callable, kind := "default", compact := false) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 72
	b.pressed.connect(callback)
	style_button(b,kind,compact)
	return b
func cta_style(kind: String, state: String, compact: bool) -> StyleBox:
	var key := "%s/%s/%s" % [kind,state,compact]
	if styles.has(key): return styles[key]
	var base := Color(KINDS[kind][0])
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(14)
	s.bg_color = base
	s.border_color = base.darkened(.32)
	match state:
		"hover": s.bg_color = base.lightened(.12)
		"pressed": s.bg_color = base.darkened(.08)
		"disabled":
			if kind == "maxed": s.bg_color = base.lightened(.45); s.border_color = base.darkened(.1)
			else: s.bg_color = Color("d9dcd3"); s.border_color = Color("b6bab0")
	if kind == "skip":
		s.border_color = TEAL; s.border_width_left = 2; s.border_width_right = 2; s.border_width_top = 2
		if state == "hover": s.bg_color = Color("eef6f4")
	# Raised key: thick darker bottom edge that sinks when pressed (total height unchanged).
	var pressed := state == "pressed"
	s.border_width_bottom = 2 if pressed else 6
	s.content_margin_left = 4 if compact else 14; s.content_margin_right = s.content_margin_left
	s.content_margin_top = 12 if pressed else 8; s.content_margin_bottom = 6
	if state != "disabled" and not pressed:
		s.shadow_color = Color(0,0,0,.18); s.shadow_size = 4; s.shadow_offset = Vector2(0,3)
	styles[key] = s
	return s
func style_button(b: Button, kind: String, compact := false):
	if b.get_meta("cta","") == kind: return
	b.set_meta("cta",kind)
	for state in ["normal","hover","pressed","disabled"]: b.add_theme_stylebox_override(state,cta_style(kind,state,compact))
	b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	var text := Color(KINDS[kind][1])
	for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]: b.add_theme_color_override(key,text)
	b.add_theme_color_override("font_disabled_color",text if kind == "maxed" else Color("7f8984"))
	b.add_theme_font_override("font",bold)
func panel_at(at: Vector2, dimensions: Vector2, color: Color) -> PanelContainer:
	var panel := PanelContainer.new(); panel.position = at; panel.size = dimensions
	var style := StyleBoxFlat.new(); style.bg_color = color; style.set_corner_radius_all(18)
	style.content_margin_left = 16; style.content_margin_right = 16; style.content_margin_top = 12; style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	return panel
func show_toast(text: String):
	# Queue messages so a burst of news (sale, achievement, event) stays readable.
	if toast_timer > 0 and toasts.size() < 4: toasts.append(text); return
	toast_label.text = text; toast_timer = 6
func show_tip(id: String, text: String):
	if sim.tips_seen.has(id): return
	sim.tips_seen.append(id)
	show_toast("Astuce · " + text)
	save_requested.emit()
func close_sheet():
	if is_instance_valid(sheet): sheet.queue_free()
	sheet = null; rows.clear(); live_labels.clear(); selection = ""; confirm_reset = false; confirm_franchise = false; confirm_import = false
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
	var titles := {"shelf":sim.cfg.family(id).get("name","Rayon"),"workers":"Équipe de réassort","checkout":"Caisse %d" % (int(id)+1),"reserve":"Réserve & livraisons","expand":"Agrandir le magasin","build":"Construire & grandir","achievements":"Succès","settings":"Réglages","stats":"Statistiques"}
	var title := label(titles.get(kind,"Brico Empire"),25); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; heading.add_child(title)
	heading.add_child(button("Fermer",close_sheet,"close"))
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation",12); scroll.add_child(content)
	match kind:
		"shelf":
			if not sim.opened[id]:
				content.add_child(label("Livraisons gratuites et emplacement fixe. Le réassort commencera dès la prochaine livraison."))
				purchase_row("unlock",id,"Ouvrir ce rayon",func(): return "%d pièces par vente · capacité %d" % [sim.sale_value(id),sim.capacity(id)])
			else:
				live(func(): return "En rayon : %d/%d · Réserve : %d/%d" % [sim.inventory.shelves[id],sim.capacity(id),sim.inventory.reserve[id],sim.reserve_capacity()])
				purchase_row("shelf_capacity",id,"Capacité",func(): return "Niv. %d/5 · %d à %d unités" % [sim.levels[id].capacity,sim.capacity(id),sim.capacity(id)+sim.cfg.v("capacity_step")])
				purchase_row("shelf_value",id,"Valeur des produits",func():
					var next_value := int(round(sim.cfg.family(id).price*(1.0+sim.levels[id].value*sim.cfg.v("value_step"))))
					return "Niv. %d/5 · %d à %d pièces / vente" % [sim.levels[id].value,sim.sale_value(id),next_value])
				purchase_row("shelf_service",id,"Prise du produit",func(): return "Niv. %d/5 · %.1f à %.1f s" % [sim.levels[id].service,sim.pick_time(id),sim.pick_time(id)*sim.cfg.v("speed_factor")])
		"workers":
			live(func():
				var states := ""
				var names := ["Disponible","Vers la réserve","Charge un lot","Transporte","Remplit le rayon"]
				for w in sim.workers: states += "%s (%s) : %s%s\n" % [w.name,w.specialty,names[w.state]," · attend la livraison" if w.waiting_goods else ""]
				return states.strip_edges())
			var specialties := ""
			for w in sim.workers: specialties += "%s : %s.\n" % [w.name,BricoWorker.specialty_text(w.specialty)]
			if sim.workers.size() < sim.cfg.v("max_workers"):
				var next := BricoWorker.new(sim.workers.size())
				specialties += "Prochaine recrue : %s, %s." % [next.name,BricoWorker.specialty_text(next.specialty)]
			content.add_child(label(specialties.strip_edges(),17))
			purchase_row("hire","","Recruter",func(): return "%d/%d employés · poste autonome" % [sim.workers.size(),sim.cfg.v("max_workers")])
			purchase_row("worker_speed","","Déplacement de l’équipe",func(): return "Niv. %d/5 · %.0f à %.0f unités/s" % [sim.worker_levels.speed,sim.worker_speed(),sim.worker_speed()+sim.cfg.v("worker_speed")*sim.cfg.v("worker_speed_step")])
			purchase_row("worker_carry","","Lot transporté",func(): return "Niv. %d/5 · %d à %d unités" % [sim.worker_levels.carry,sim.carry_capacity(),sim.carry_capacity()+sim.cfg.v("carry_step")])
			purchase_row("worker_restock","","Vitesse de réassort",func(): return "Niv. %d/5 · %.1f à %.1f s" % [sim.worker_levels.restock,sim.restock_time(),sim.restock_time()*sim.cfg.v("speed_factor")])
		"checkout":
			if int(id) >= sim.checkouts:
				purchase_row("checkout","","Ouvrir la seconde caisse",func(): return "Caissier inclus · %.1f s / client" % sim.checkout_time(1))
			else:
				live(func(): return "%d client(s) dans la file · encaissement automatique" % sim.queues[int(id)].size())
				purchase_row("cash_speed",id,"Encaissement",func(): return "Niv. %d/5 · %.1f à %.1f s / client" % [sim.cash_levels[int(id)],sim.checkout_time(int(id)),sim.checkout_time(int(id))*sim.cfg.v("speed_factor")])
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
			purchase_row("expand","","Agrandissement %d/2" % mini(2,sim.expansion+1),func(): return "Nouvelle aile : surface jardinage + réception" if sim.expansion == 0 else "Grand dépôt : réserve 24 à 48 ; rayons +4 ; électricité et plomberie")
			if sim.checkouts < 2: purchase_row("checkout","","Deuxième caisse",func(): return "Caissier inclus · une file supplémentaire")
			content.add_child(label("DÉCORATION · améliore la note du magasin",17))
			for item in sim.cfg.v("decor"):
				purchase_row("decor",item.id,item.name,func(): return "%s · note +%.2f" % [item.text,item.rating])
			content.add_child(label("FRANCHISE",17))
			live(func(): return "Atelier %02d · bonus de vente actuel +%d %%. Une franchise ouvre un nouvel atelier : magasin, rayons, équipe, déco et argent repartent de zéro (+%d pièces de départ) ; succès, statistiques et bonus restent, et le bonus grimpe de %d %%." % [sim.franchise_level+1,int(round((sim.franchise_multiplier()-1)*100)),(sim.franchise_level+1)*sim.cfg.v("franchise_start_bonus"),int(sim.cfg.v("franchise_step")*100)])
			var franchise_button := button("",func():
				if not sim.progression.reason("franchise").is_empty(): show_toast(sim.progression.reason("franchise")); return
				if not confirm_franchise:
					confirm_franchise = true; show_toast("Appuyez encore pour confirmer : le magasin actuel sera remplacé par un nouvel atelier."); refresh(); return
				if sim.progression.buy("franchise"): close_sheet(); save_requested.emit(),"gold")
			content.add_child(franchise_button)
			live_labels.append([label(""),func():
				var ready := sim.progression.reason("franchise").is_empty()
				franchise_button.disabled = not ready
				franchise_button.text = ("Confirmer la franchise" if confirm_franchise else "Ouvrir l’atelier %02d" % (sim.franchise_level+2)) if ready else "Franchise : %s" % sim.progression.reason("franchise").to_lower()
				return ""])
		"achievements":
			var daily_box := VBoxContainer.new(); daily_box.add_theme_constant_override("separation",2); content.add_child(daily_box)
			var daily_title := label("",21); daily_title.add_theme_color_override("font_color",Color("8c6bc4")); daily_box.add_child(daily_title)
			var daily_bar := progress_bar(Color("8c6bc4")); daily_box.add_child(daily_bar)
			live_labels.append([daily_title,func():
				daily_bar.max_value = maxi(1,int(sim.daily.get("goal",1))); daily_bar.value = int(sim.daily.get("progress",0))
				if sim.daily.get("done",false): return "OBJECTIF DU JOUR RÉUSSI · revenez demain"
				return "OBJECTIF DU JOUR · %s · %d/%d · +%d pièces" % [sim.daily_text(),sim.daily.progress,sim.daily.goal,sim.daily.reward]])
			live(func(): return "%d/%d débloqués · %d pièces gagnées en récompenses" % [sim.achievements.size(),sim.cfg.v("achievements").size(),sim.achievement_rewards])
			for a in sim.cfg.v("achievements"):
				var group := VBoxContainer.new(); group.add_theme_constant_override("separation",2); content.add_child(group)
				var done: bool = sim.achievements.has(a.id)
				var name_label := label(("OBTENU · " if done else "") + a.name,21)
				if done: name_label.add_theme_color_override("font_color",Color("2f7d55"))
				group.add_child(name_label)
				group.add_child(label("%s · récompense %d pièces" % [a.text,a.reward],17))
				if not done:
					var bar := progress_bar(Color("f2aa56")); bar.max_value = a.goal
					group.add_child(bar)
					var progress := label("",15); group.add_child(progress)
					live_labels.append([progress,func():
						var v: int = mini(sim.stat(a.stat),a.goal); bar.value = v
						return "%d / %d" % [v,a.goal]])
		"settings":
			var sound := CheckButton.new(); sound.text = "Sons"; sound.button_pressed = sim.settings.sound; sound.custom_minimum_size.y = 72; content.add_child(sound)
			sound.toggled.connect(func(enabled): sim.settings.sound = enabled; save_requested.emit())
			var music := CheckButton.new(); music.text = "Musique d’ambiance"; music.button_pressed = sim.settings.music; music.custom_minimum_size.y = 72; content.add_child(music)
			music.toggled.connect(func(enabled): sim.settings.music = enabled; save_requested.emit())
			var effects_button := CheckButton.new(); effects_button.text = "Réduire les effets visuels"; effects_button.button_pressed = sim.settings.reduced_effects; effects_button.custom_minimum_size.y = 72; content.add_child(effects_button)
			effects_button.toggled.connect(func(enabled): sim.settings.reduced_effects = enabled; save_requested.emit())
			var volume_label := label("",20); content.add_child(volume_label)
			var volume := HSlider.new(); volume.min_value = 0; volume.max_value = 1; volume.step = 0.05; volume.value = sim.settings.volume; volume.custom_minimum_size.y = 44
			content.add_child(volume)
			live_labels.append([volume_label,func(): return "Volume : %d %%" % int(round(sim.settings.volume*100))])
			volume.value_changed.connect(func(v): sim.settings.volume = v; refresh())
			volume.drag_ended.connect(func(_changed): save_requested.emit())
			content.add_child(label("SAUVEGARDE · transférez votre partie vers un autre appareil",17))
			var code_field := LineEdit.new(); code_field.placeholder_text = "Collez ici un code de sauvegarde"; code_field.custom_minimum_size.y = 56; code_field.add_theme_font_size_override("font_size",16)
			var field_style := StyleBoxFlat.new(); field_style.bg_color = Color.WHITE; field_style.set_border_width_all(2); field_style.border_color = Color("c9c0a6"); field_style.set_corner_radius_all(10); field_style.content_margin_left = 12; field_style.content_margin_right = 12
			code_field.add_theme_stylebox_override("normal",field_style); code_field.add_theme_stylebox_override("focus",field_style)
			code_field.add_theme_color_override("font_color",TEAL); code_field.add_theme_color_override("font_placeholder_color",MUTED)
			content.add_child(button("Copier ma sauvegarde",func():
				code_field.text = Marshalls.utf8_to_base64(JSON.stringify(sim.snapshot(int(Time.get_unix_time_from_system()))))
				DisplayServer.clipboard_set(code_field.text)
				code_field.select_all()
				show_toast("Code copié : collez-le dans Options › Sauvegarde sur l’autre appareil."),"camera"))
			content.add_child(code_field)
			content.add_child(button("Charger le code collé",(func():
				if code_field.text.strip_edges().is_empty(): show_toast("Collez d’abord un code de sauvegarde."); return
				if not confirm_import:
					confirm_import = true; show_toast("Appuyez encore pour remplacer la partie actuelle par ce code."); return
				import_requested.emit(code_field.text.strip_edges())),"options"))
			content.add_child(label("Sauvegarde locale automatique · aucune publicité ni achat intégré. Les sons et la musique sont synthétisés par le jeu.",17))
			var reset_button := button("Réinitialiser la partie",(func():
				if confirm_reset: reset_requested.emit()
				else:
					confirm_reset = true
					content.add_child(label("Attention : toute la progression sera effacée. Appuyez de nouveau sur Réinitialiser pour confirmer.",18))),"danger")
			content.add_child(reset_button)
			if dev: developer_controls()
		"stats":
			stats_sheet()
	refresh()
func progress_bar(color: Color) -> ProgressBar:
	var bar := ProgressBar.new(); bar.custom_minimum_size.y = 18; bar.show_percentage = false
	var fill := StyleBoxFlat.new(); fill.bg_color = color; fill.set_corner_radius_all(6); bar.add_theme_stylebox_override("fill",fill)
	var track := StyleBoxFlat.new(); track.bg_color = Color("e3dccb"); track.set_corner_radius_all(6); bar.add_theme_stylebox_override("background",track)
	return bar
func stats_sheet():
	var stars := Control.new(); stars.custom_minimum_size = Vector2(0,44); content.add_child(stars)
	stars.draw.connect(func():
		var r := sim.rating()
		for i in range(5):
			var c := Vector2(22+i*44,22)
			var pts := PackedVector2Array()
			for k in range(10):
				var a := -PI/2 + k*PI/5
				pts.append(c+Vector2(cos(a),sin(a))*(18 if k % 2 == 0 else 8))
			stars.draw_colored_polygon(pts,Color("e3dccb"))
			var part := clampf(r-i,0,1)
			if part > 0:
				var clipped := PackedVector2Array()
				for q in pts: clipped.append(Vector2(minf(q.x,c.x-18+36*part),q.y))
				stars.draw_colored_polygon(clipped,Color("f2c14e"))
		stars.draw_string(ThemeDB.fallback_font,Vector2(240,32),"%.1f / 5" % r,HORIZONTAL_ALIGNMENT_LEFT,-1,26,TEAL))
	live(func(): return "Satisfaction des clients %.1f · décoration +%.2f · %s" % [sim.satisfaction_rating(),sim.decor_bonus(),"les clients affluent" if sim.rating() >= 4 else ("clientèle normale" if sim.rating() >= 2.5 else "les clients boudent le magasin")])
	content.add_child(label("REVENUS PAR MINUTE · 15 DERNIÈRES MINUTES",17))
	var chart := Control.new(); chart.custom_minimum_size = Vector2(0,150); content.add_child(chart)
	chart.draw.connect(func():
		var values: Array = sim.minute_revenue.duplicate(); values.append(sim.minute_acc)
		var top := 1
		for v in values: top = maxi(top,int(v))
		var w := chart.size.x / 16.0
		chart.draw_line(Vector2(0,130),Vector2(chart.size.x,130),Color("c9c0a6"),2)
		for i in range(values.size()):
			var h := 120.0 * float(values[i]) / top
			var x := (16 - values.size() + i) * w
			var color := Color("8c6bc4") if i == values.size()-1 else Color("2f9e6a")
			chart.draw_rect(Rect2(x+3,130-h,w-6,h),color)
		chart.draw_string(ThemeDB.fallback_font,Vector2(0,148),"max %d pièces/min · barre violette : minute en cours" % top,HORIZONTAL_ALIGNMENT_LEFT,-1,14,MUTED))
	var redraw_driver := label("")
	redraw_driver.hide()
	content.add_child(redraw_driver)
	live_labels.append([redraw_driver,func(): chart.queue_redraw(); stars.queue_redraw(); return ""])
	live(func():
		var lines := "Ventes : %d clients · %s pièces encaissées\nAujourd’hui : %s pièces · meilleur jour : %s pièces\nClients satisfaits : %d · VIP servis : %d · objectifs du jour : %d" % [sim.total_sales,format_money(sim.total_revenue),format_money(sim.day_revenue),format_money(maxi(sim.best_day,sim.day_revenue)),sim.happy_served,sim.vip_served,sim.dailies_done]
		var best := ""; var best_n := -1
		for f in sim.cfg.families:
			if int(sim.family_sales.get(f.id,0)) > best_n: best_n = int(sim.family_sales.get(f.id,0)); best = f.name
		lines += "\nRayon star : %s (%d articles)" % [best,best_n]
		return lines)
	content.add_child(label("ARTICLES VENDUS PAR RAYON",17))
	for f in sim.cfg.families:
		var row := VBoxContainer.new(); content.add_child(row)
		var name_label := label("",17); row.add_child(name_label)
		var bar := progress_bar(Color(f.color)); row.add_child(bar)
		live_labels.append([name_label,func():
			var total := 1
			for g in sim.cfg.families: total = maxi(total,int(sim.family_sales.get(g.id,0)))
			bar.max_value = total; bar.value = int(sim.family_sales.get(f.id,0))
			return "%s · %d" % [f.name,int(sim.family_sales.get(f.id,0))] + ("" if sim.opened[f.id] else " · fermé")])
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
			show_toast(sim.progression.reason(action,target)); refresh(),"buy")
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
	var hour := sim.day_hour()
	title_label.text = "BRICO EMPIRE  /  ATELIER %02d  ·  JOUR %d  ·  %02d h %02d" % [sim.franchise_level+1,sim.day_number(),int(hour),int(fmod(hour,1.0)*6)*10]
	if not sim.event.is_empty():
		status.text = "%s · encore %d s · %d clients" % [sim.event.name,ceili(sim.event_left),sim.customers.size()]
		status.add_theme_color_override("font_color",Color("c2492f"))
	else:
		status.text = "Note %.1f/5 · %s · %d clients" % [sim.rating(),"mesure des ventes…" if rpm < 0 else "%.0f pièces/min" % rpm,sim.customers.size()]
		status.remove_theme_color_override("font_color")
	advice.text = sim.advice
	# Calm moments show the daily objective instead of generic advice.
	if sim.advice.begins_with("L’activité est fluide") and not sim.daily.is_empty() and not sim.daily.done:
		advice.text = "Objectif du jour : %s · %d/%d · +%d pièces" % [sim.daily_text(),sim.daily.progress,sim.daily.goal,sim.daily.reward]
	if sim.tutorial >= 5:
		show_tip("world","Glissez pour explorer le quartier ; « Recentrer » ramène au magasin, « Stats » montre la note.")
	if sim.outcomes.size() >= 10 and sim.satisfaction_rating() < 3.0:
		show_tip("rating","Note en baisse : rayons vides et files longues mécontentent les clients, qui viennent alors moins.")
	if sim.franchise_ready():
		show_tip("franchise","Franchise disponible dans « Construire » : nouvel atelier avec un bonus de vente permanent.")
	tutorial_box.visible = sim.tutorial < 5
	var steps := ["1/5 · Observez une vente : un client prend un produit, puis paie.","2/5 · Touchez le rayon outillage pour voir ses améliorations.","3/5 · Achetez une amélioration. La première coûte 100 pièces.","4/5 · Observez l’employé : il transporte un carton de la réserve au rayon.","5/5 · Prochain objectif : la peinture, 300 pièces. Touchez ici pour terminer."]
	if sim.tutorial < 5: tutorial_label.text = steps[sim.tutorial]
	for row in rows:
		var why: String = sim.progression.reason(row.action,row.target)
		var maxed := why in ["Niveau maximal","Équipe au complet","Magasin entièrement agrandi","Les deux caisses sont ouvertes","Déjà installé"]
		if row.action == "decor": row.detail.text = row.effect.call()
		else: row.detail.text = str(row.effect.call()).split(" à ")[0] + " · au maximum" if maxed else row.effect.call()
		row.button.text = ("Installé" if why == "Déjà installé" else "Niveau maximal") if maxed else "Acheter · %d pièces" % sim.progression.cost(row.action,row.target)
		row.button.disabled = not why.is_empty()
		style_button(row.button,"maxed" if maxed else "buy")
		row.reason.text = why
		row.reason.visible = not why.is_empty() and not maxed
	for item in live_labels: item[0].text = item[1].call()
	# Nudge towards the build menu when a key purchase is affordable.
	build_ready = sim.progression.reason("expand").is_empty() or sim.progression.reason("checkout").is_empty()
	for f in sim.cfg.families:
		if not sim.opened[f.id] and sim.progression.reason("unlock",f.id).is_empty(): build_ready = true
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
	if toast_timer <= 0 and not toasts.is_empty():
		toast_label.text = toasts.pop_front(); toast_timer = 6
	if is_instance_valid(toast_label): toast_label.visible = toast_timer > 0
	if is_instance_valid(build_button):
		pulse += dt
		var glow := 0.0 if not build_ready or sim.settings.reduced_effects else 0.18*(0.5+0.5*sin(pulse*5))
		build_button.modulate = Color(1+glow,1+glow,1+glow)
		build_button.text = "Construire !" if build_ready else "Construire"
func _input(event: InputEvent):
	if sim == null: return
	if sim.tutorial == 4 and not is_instance_valid(sheet):
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
			if tutorial_box.get_global_rect().has_point(event.position): sim.tutorial = 5; save_requested.emit(); get_viewport().set_input_as_handled()
