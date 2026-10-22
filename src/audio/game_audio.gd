class_name BricoAudio
extends Node
const MUSIC_RATE := 16000
var sim: BricoSimulation
var sale_player: AudioStreamPlayer
var purchase_player: AudioStreamPlayer
var achievement_player: AudioStreamPlayer
var event_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var night_player: AudioStreamPlayer
var bird_player: AudioStreamPlayer
var cricket_player: AudioStreamPlayer
var ambience_timer := 4.0
var restock_player: AudioStreamPlayer
var seen_restocks := 0
var restock_cooldown := 0.0
const MUSIC_DB := -23.0
func setup(simulation: BricoSimulation):
	sim = simulation
	sale_player = player(tone(740,0.10),-21)
	purchase_player = player(tone(520,0.18),-18)
	restock_player = player(tone(220,.075),-28)
	seen_restocks = sim.restock_count
	achievement_player = player(melody([523.25,659.25,783.99,1046.5],0.11),-16)
	event_player = player(melody([392.0,587.33,392.0,587.33],0.09),-18)
	sim.sale.connect(func(_n,_p):
		if sim.settings.sound: sale_player.play())
	sim.purchased.connect(func(_a,_b):
		if sim.settings.sound: purchase_player.play())
	sim.achieved.connect(func(_a):
		if sim.settings.sound: achievement_player.play())
	sim.event_started.connect(func(_e):
		if sim.settings.sound: event_player.play())
	# The loop is synthesised after the first frame so the store appears immediately.
	call_deferred("start_music")
func player(stream: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new(); add_child(p); p.stream = stream; p.volume_db = db
	return p
func start_music():
	music_player = player(music(),MUSIC_DB)
	bird_player = player(chirp(),-26)
	cricket_player = player(crickets(),-30)
	update_music()
	# Night loop is synthesised a frame later to spread the start-up cost.
	call_deferred("start_night_music")
func start_night_music():
	night_player = player(music([[220.0,261.63,329.63,440.0],[174.61,220.0,261.63,349.23],[130.81,196.0,261.63,329.63],[196.0,246.94,293.66,392.0]],0.55,3.5),-80)
func night_amount() -> float:
	var h := sim.day_hour()
	if h >= 20 or h < 6: return 1.0
	if h >= 18: return (h-18)/2.0
	if h < 8: return 1.0-(h-6)/2.0
	return 0.0
func update_music():
	if music_player == null: return
	for p in [music_player,night_player]:
		if p == null: continue
		if sim.settings.music and not p.playing: p.play()
		elif not sim.settings.music and p.playing: p.stop()
	# Crossfade between the day and night loops following the in-game clock.
	var n := night_amount()
	music_player.volume_db = MUSIC_DB + linear_to_db(maxf(0.001,1.0-n))
	if night_player != null: night_player.volume_db = MUSIC_DB - 2 + linear_to_db(maxf(0.001,n))
func _process(dt: float):
	restock_cooldown = maxf(0,restock_cooldown-dt)
	if sim.restock_count > seen_restocks:
		seen_restocks = sim.restock_count
		if sim.settings.sound and restock_cooldown <= 0:
			restock_player.play(); restock_cooldown = 1.5
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.0001,float(sim.settings.volume))))
	update_music()
	if bird_player == null or not sim.settings.sound: return
	ambience_timer -= dt
	if ambience_timer <= 0:
		var night := night_amount() > 0.5
		ambience_timer = randf_range(3.0,6.0) if night else randf_range(6.0,14.0)
		var p := cricket_player if night else bird_player
		p.pitch_scale = randf_range(0.9,1.15)
		p.play()
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
func melody(notes: Array, step: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	var per := int(22050*step); var count := per*(notes.size()+2)
	var data := PackedByteArray(); data.resize(count*2)
	for i in range(count):
		var n := mini(i/per,notes.size()-1)
		var t := float(i-n*per)/22050
		var length := step*(3.0 if n == notes.size()-1 else 1.0)
		var envelope := maxf(0,1-t/length) * minf(1,t*200)
		data.encode_s16(i*2,int((sin(TAU*notes[n]*t)+0.3*sin(TAU*notes[n]*2*t))*envelope*11000))
	stream.data = data
	return stream
func chirp() -> AudioStreamWAV:
	# Two quick rising whistles, like a sparrow.
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	var count := int(22050*0.42); var data := PackedByteArray(); data.resize(count*2)
	var phase_acc := 0.0
	for i in range(count):
		var t := float(i)/22050
		var local := fmod(t,0.21)
		var hz := 2600.0 + 1400.0*local/0.12
		phase_acc += TAU*hz/22050
		var env := maxf(0,sin(PI*minf(1,local/0.12))) if local < 0.12 else 0.0
		data.encode_s16(i*2,int(sin(phase_acc)*env*9000))
	stream.data = data
	return stream
func crickets() -> AudioStreamWAV:
	# Short pulsed high tone, three chirps.
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	var count := int(22050*0.5); var data := PackedByteArray(); data.resize(count*2)
	for i in range(count):
		var t := float(i)/22050
		var gate := 1.0 if fmod(t,0.16) < 0.07 and fmod(t*90,1.0) < 0.6 else 0.0
		data.encode_s16(i*2,int(sin(TAU*4300*t)*gate*6000))
	stream.data = data
	return stream
# Calm four-chord loop (C, Am, F, G by default): plucked arpeggio over a soft bass.
func music(chords: Array = [[261.63,329.63,392.0,523.25],[220.0,261.63,329.63,440.0],[174.61,220.0,261.63,349.23],[196.0,246.94,293.66,392.0]], note_len := 0.4, decay := 5.5) -> AudioStreamWAV:
	var pattern := [0,1,2,3,2,1,2,3]
	var chord_len := note_len*pattern.size()
	var count := int(MUSIC_RATE*chord_len*chords.size())
	var data := PackedByteArray(); data.resize(count*2)
	for i in range(count):
		var t := float(i)/MUSIC_RATE
		var c := int(t/chord_len) % chords.size()
		var chord: Array = chords[c]
		var tc := fmod(t,chord_len)
		var tn := fmod(tc,note_len)
		var hz: float = chord[pattern[int(tc/note_len)]]
		var pluck := sin(TAU*hz*tn) * exp(-tn*decay) * minf(1,tn*300)
		var bass_hz: float = chord[0]/2
		var bass := sin(TAU*bass_hz*tc) * (0.55+0.45*exp(-tc*1.2)) * minf(1,tc*20) * minf(1,(chord_len-tc)*20)
		data.encode_s16(i*2,int((pluck*0.55+bass*0.35)*14000))
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = MUSIC_RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0; stream.loop_end = count
	return stream

func _exit_tree():
	# Release playing loops when restarting the game or leaving the application.
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
