class_name BricoAudio
extends Node
var sim: BricoSimulation
var sale_player: AudioStreamPlayer
var purchase_player: AudioStreamPlayer
func setup(simulation: BricoSimulation):
	sim = simulation
	sale_player = AudioStreamPlayer.new(); add_child(sale_player); sale_player.stream = tone(740,0.10); sale_player.volume_db = -21
	purchase_player = AudioStreamPlayer.new(); add_child(purchase_player); purchase_player.stream = tone(520,0.18); purchase_player.volume_db = -18
	sim.sale.connect(func(_n,_p):
		if sim.settings.sound: sale_player.play())
	sim.purchased.connect(func(_a,_b):
		if sim.settings.sound: purchase_player.play())
func tone(hz: float, seconds: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	var data := PackedByteArray(); var count := int(22050*seconds); data.resize(count*2)
	for i in range(count):
		var t := float(i)/22050
		var envelope := pow(1-float(i)/count,2) * minf(1,t*100)
		var sample := int(sin(TAU*hz*t)*envelope*15000)
		data.encode_s16(i*2,sample)
	stream.data = data
	return stream
