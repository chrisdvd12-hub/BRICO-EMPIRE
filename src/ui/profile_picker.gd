class_name BricoProfilePicker
extends CanvasLayer
signal player_chosen(id: String)
var profiles: BricoProfiles
var root: Control
var list: VBoxContainer
var message: Label
var name_field: LineEdit
var avatar := 0
const COLORS := [Color("00a7ce"),Color("ff941c"),Color("20b754"),Color("b94bdd"),Color("ef467b"),Color("efc61c")]
func setup(manager: BricoProfiles):
	profiles = manager; layer = 10
	root = Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(root)
	var bg := TextureRect.new(); bg.texture = preload("res://assets/loading/final-c.webp"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; root.add_child(bg)
	var card := PanelContainer.new(); card.position = Vector2(24,300); card.size = Vector2(492,630)
	var style := StyleBoxFlat.new(); style.bg_color = Color("fffdf5"); style.set_corner_radius_all(26); style.set_border_width_all(4); style.border_color = Color("006c82"); style.set_content_margin_all(22); card.add_theme_stylebox_override("panel",style); root.add_child(card)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",12); card.add_child(column)
	var title := label("Qui joue aujourd’hui ?",29); column.add_child(title)
	column.add_child(label("Chaque joueur garde son propre magasin.\nSauvegardes sur cet appareil uniquement.",18))
	var scroll := ScrollContainer.new(); scroll.custom_minimum_size.y = 205; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation",8); scroll.add_child(list)
	for p in profiles.entries:
		var b := Button.new(); b.text = p.name+ ("  ·  dernière partie" if p.id == profiles.active_id else ""); b.custom_minimum_size.y = 72
		decorate(b,COLORS[p.avatar]); b.pressed.connect(func(): player_chosen.emit(p.id)); list.add_child(b)
	name_field = LineEdit.new(); name_field.placeholder_text = "Nom du nouveau joueur"; name_field.max_length = 20; name_field.custom_minimum_size.y = 64; name_field.add_theme_font_override("font",preload("res://assets/fonts/Fredoka-Regular.ttf")); name_field.add_theme_font_size_override("font_size",22); column.add_child(name_field)
	var create := Button.new(); create.text = "Créer mon magasin"; create.custom_minimum_size.y = 72; decorate(create,Color("006c82")); column.add_child(create)
	create.disabled = profiles.entries.size() >= profiles.LIMIT
	create.pressed.connect(create_player); name_field.text_submitted.connect(func(_text): create_player())
	message = label(profiles.warning if profiles.entries.size() < profiles.LIMIT else "6 profils maximum sur cet appareil.",17); column.add_child(message)
func create_player():
	var id := profiles.create_player(name_field.text,profiles.entries.size())
	if id.is_empty(): message.text = "Choisis un nom de 1 à 20 caractères." if name_field.text.strip_edges().is_empty() else "Création impossible : limite ou sauvegarde indisponible."
	else: player_chosen.emit(id)
func label(text: String, font_size: int) -> Label:
	var l := Label.new(); l.text = text; l.add_theme_font_override("font",preload("res://assets/fonts/Fredoka-Semibold.ttf")); l.add_theme_font_size_override("font_size",font_size); l.add_theme_color_override("font_color",Color("006074")); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; return l
func decorate(b: Button, color: Color):
	b.clip_text = true; b.add_theme_font_override("font",preload("res://assets/fonts/Fredoka-Semibold.ttf")); b.add_theme_font_size_override("font_size",22)
	for state in ["normal","hover","pressed","disabled"]:
		var s := StyleBoxFlat.new(); s.bg_color = color.darkened(.18) if state == "pressed" else color; s.set_corner_radius_all(15); s.set_content_margin_all(12); b.add_theme_stylebox_override(state,s)
		b.add_theme_color_override("font_"+state+"_color" if state != "normal" else "font_color",Color.WHITE)
