class_name BricoProgression
extends RefCounted
var sim_ref: WeakRef
var sim:
	get: return sim_ref.get_ref()
func _init(simulation): sim_ref = weakref(simulation)
func cost(action: String, target: String = "") -> int:
	match action:
		"unlock": return sim.cfg.family(target).unlock
		"expand":
			if sim.expansion >= 2: return 0
			return sim.cfg.v("expansion_prices")[sim.expansion]
		"hire": return int(sim.cfg.v("worker_price") * pow(1.7,sim.workers.size()-1))
		"checkout": return sim.cfg.v("checkout_price")
		"shelf_capacity", "shelf_value", "shelf_service": return sim.cfg.upgrade_cost(sim.levels[target][action.trim_prefix("shelf_")])
		"worker_speed", "worker_carry", "worker_restock": return sim.cfg.upgrade_cost(sim.worker_levels[action.trim_prefix("worker_")])
		"cash_speed": return sim.cfg.upgrade_cost(sim.cash_levels[int(target)])
	return 0
func reason(action: String, target: String = "") -> String:
	match action:
		"unlock":
			if sim.opened[target]: return "Rayon déjà ouvert"
			if sim.expansion < sim.cfg.family(target).expansion: return "Ouvrez d’abord l’agrandissement %d" % sim.cfg.family(target).expansion
		"expand":
			if sim.expansion >= 2: return "Magasin entièrement agrandi"
			if not sim.opened.paint: return "Ouvrez d’abord la peinture"
			if sim.expansion == 1 and not sim.opened.garden: return "Ouvrez d’abord le jardinage"
		"hire":
			if sim.workers.size() >= sim.cfg.v("max_workers"): return "Équipe au complet"
		"checkout":
			if sim.checkouts >= 2: return "Les deux caisses sont ouvertes"
		"shelf_capacity", "shelf_value", "shelf_service":
			if not sim.opened[target]: return "Rayon fermé"
			if sim.levels[target][action.trim_prefix("shelf_")] >= sim.cfg.v("max_level"): return "Niveau maximal"
		"worker_speed", "worker_carry", "worker_restock":
			if sim.worker_levels[action.trim_prefix("worker_")] >= sim.cfg.v("max_level"): return "Niveau maximal"
		"cash_speed":
			if int(target) >= sim.checkouts: return "Caisse fermée"
			if sim.cash_levels[int(target)] >= sim.cfg.v("max_level"): return "Niveau maximal"
		_: return "Action inconnue"
	if sim.money < cost(action,target): return "Il manque %d pièces" % (cost(action,target)-sim.money)
	return ""
func buy(action: String, target: String = "") -> bool:
	if not reason(action,target).is_empty(): return false
	sim.money -= cost(action,target)
	match action:
		"unlock": sim.opened[target] = true
		"expand": sim.expansion += 1
		"hire": sim.workers.append(BricoWorker.new(sim.workers.size()))
		"checkout": sim.checkouts = 2
		"shelf_capacity", "shelf_value", "shelf_service":
			sim.levels[target][action.trim_prefix("shelf_")] += 1
			if sim.tutorial == 2: sim.tutorial = 3
		"worker_speed", "worker_carry", "worker_restock": sim.worker_levels[action.trim_prefix("worker_")] += 1
		"cash_speed": sim.cash_levels[int(target)] += 1
	sim.nav.rebuild(sim.expansion,sim.opened,sim.cfg)
	sim.changed.emit()
	sim.purchased.emit(action,target)
	return true
func objective() -> String:
	if not sim.opened.paint: return "Ouvrir la peinture · %d pièces" % sim.cfg.family("paint").unlock
	if sim.expansion == 0: return "Agrandir le magasin · %d pièces" % sim.cfg.v("expansion_prices")[0]
	if not sim.opened.garden: return "Ouvrir le jardinage · %d pièces" % sim.cfg.family("garden").unlock
	if sim.checkouts == 1: return "Ouvrir la deuxième caisse · %d pièces" % sim.cfg.v("checkout_price")
	if sim.expansion == 1: return "Créer le grand dépôt · %d pièces" % sim.cfg.v("expansion_prices")[1]
	for id in ["electric","plumbing"]:
		if not sim.opened[id]: return "Ouvrir : %s · %d pièces" % [sim.cfg.family(id).name,sim.cfg.family(id).unlock]
	var total: int = sim.cfg.v("achievements").size()
	if sim.achievements.size() < total: return "Succès : %d/%d débloqués" % [sim.achievements.size(),total]
	return "Votre Brico Empire s’épanouit !"
