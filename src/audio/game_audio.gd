class_name BricoAudio
extends Node
const MUSIC_RATE := 16000
var sim: BricoSimulation
var sale_player: AudioStreamPlayer
var purchase_player: AudioStreamPlayer
var achievement_player: AudioStreamPlayer
var event_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
func setup(simulation: BricoSimulation):
	sim = simulation
	sale_player = player(tone(740,0.10),-21)
	purchase_player = player(tone(520,0.18),-18)
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
	music_player = player(music(),-23)
	update_music()
func update_music():
	if music_player == null: return
	if sim.settings.music and not music_player.playing: music_player.play()
	elif not sim.settings.music and music_player.playing: music_player.stop()
func _process(_dt: float):
	update_music()
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
# Calm four-chord loop (C, Am, F, G): plucked arpeggio over a soft bass.
func music() -> AudioStreamWAV:
	var chords := [[261.63,329.63,392.0,523.25],[220.0,261.63,329.63,440.0],[174.61,220.0,261.63,349.23],[196.0,246.94,293.66,392.0]]
	var pattern := [0,1,2,3,2,1,2,3]
	var note_len := 0.4
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
		var pluck := sin(TAU*hz*tn) * exp(-tn*5.5) * minf(1,tn*300)
		var bass_hz: float = chord[0]/2
		var bass := sin(TAU*bass_hz*tc) * (0.55+0.45*exp(-tc*1.2)) * minf(1,tc*20) * minf(1,(chord_len-tc)*20)
		data.encode_s16(i*2,int((pluck*0.55+bass*0.35)*14000))
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = MUSIC_RATE
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0; stream.loop_end = count
	return stream
