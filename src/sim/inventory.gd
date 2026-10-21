class_name BricoInventory
extends RefCounted
# All transfers are synchronous within the simulation tick. Cargo belongs to its worker.
var cfg: BricoConfig
var shelves: Dictionary = {}
var reserve: Dictionary = {}
var delivered: int = 0
var sold: int = 0
func _init(config: BricoConfig):
	cfg = config
	for f in cfg.families:
		shelves[f.id] = 0
		reserve[f.id] = 0
func take_reserve(id: String, wanted: int) -> int:
	var amount: int = mini(wanted, reserve[id])
	reserve[id] -= amount
	return amount
func put_shelf(id: String, amount: int):
	shelves[id] += amount
func pick(id: String) -> bool:
	if shelves[id] < 1: return false
	shelves[id] -= 1
	return true
func total() -> int:
	var result := 0
	for id in shelves: result += int(shelves[id]) + int(reserve[id])
	return result
func deliver(opened: Dictionary, capacity: int):
	for id in opened:
		if not opened[id]: continue
		var n := maxi(0, mini(cfg.v("delivery_batch"), capacity - int(reserve[id])))
		reserve[id] += n
		delivered += n
