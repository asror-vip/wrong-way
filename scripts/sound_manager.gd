extends Node

# Wrong Way — Procedural Sound Synthesizer
# Generates 8-bit retro sounds directly into AudioStreamWAV without external assets.

var sound_enabled: bool = true
var screen_shake_enabled: bool = true

var sfx_jump: AudioStreamWAV
var sfx_land: AudioStreamWAV
var sfx_die: AudioStreamWAV
var sfx_trap: AudioStreamWAV
var sfx_win: AudioStreamWAV
var sfx_click: AudioStreamWAV

var _players: Array[AudioStreamPlayer] = []
var _max_players: int = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(_max_players):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	
	sfx_jump = _gen_jump()
	sfx_land = _gen_land()
	sfx_die = _gen_die()
	sfx_trap = _gen_trap()
	sfx_win = _gen_win()
	sfx_click = _gen_click()

func play_sfx(stream: AudioStreamWAV, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not sound_enabled or stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	# Fallback: re-use first player
	var p = _players[0]
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func play_jump() -> void:
	play_sfx(sfx_jump, -4.0, randf_range(0.95, 1.05))

func play_land() -> void:
	play_sfx(sfx_land, -6.0, randf_range(0.9, 1.1))

func play_die() -> void:
	play_sfx(sfx_die, -2.0, randf_range(0.95, 1.05))

func play_trap() -> void:
	play_sfx(sfx_trap, -3.0, 1.0)

func play_win() -> void:
	play_sfx(sfx_win, 0.0, 1.0)

func play_click() -> void:
	play_sfx(sfx_click, -4.0, 1.2)

# --- Procedural Audio Generation Helpers ---

func _create_wav(samples: PackedFloat32Array, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	
	var byte_data = PackedByteArray()
	byte_data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s = clampf(samples[i], -1.0, 1.0)
		var val = int(s * 32767.0)
		byte_data.encode_s16(i * 2, val)
	
	wav.data = byte_data
	return wav

func _gen_jump() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.14
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var prog = t / duration
		var freq = lerpf(240.0, 680.0, prog)
		phase += freq * (TAU / rate)
		var env = (1.0 - prog) * (1.0 - prog)
		var wave = sin(phase) * 0.7 + (1.0 if sin(phase) > 0 else -1.0) * 0.3
		samples[i] = wave * env * 0.75
	
	return _create_wav(samples, rate)

func _gen_land() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.08
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var prog = t / duration
		var freq = lerpf(120.0, 50.0, prog)
		phase += freq * (TAU / rate)
		var env = exp(-prog * 8.0)
		var noise = randf_range(-0.2, 0.2)
		var wave = sin(phase) * 0.8 + noise
		samples[i] = wave * env * 0.6
	
	return _create_wav(samples, rate)

func _gen_die() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.35
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var prog = t / duration
		var freq = lerpf(450.0, 70.0, prog * prog)
		phase += freq * (TAU / rate)
		var env = exp(-prog * 4.5)
		var noise = randf_range(-0.5, 0.5) * (1.0 - prog)
		var wave = (1.0 if sin(phase) > 0.0 else -1.0) * 0.5 + noise * 0.5
		samples[i] = wave * env * 0.85
	
	return _create_wav(samples, rate)

func _gen_trap() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.2
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var prog = t / duration
		var freq = lerpf(550.0, 180.0, prog)
		phase += freq * (TAU / rate)
		var env = exp(-prog * 5.0)
		var noise = randf_range(-0.3, 0.3)
		var wave = sin(phase) * 0.6 + noise * 0.4
		samples[i] = wave * env * 0.7
	
	return _create_wav(samples, rate)

func _gen_win() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.45
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	# Arpeggio C5 (523), E5 (659), G5 (784), C6 (1046)
	var notes = [523.25, 659.25, 783.99, 1046.5]
	var note_dur = duration / notes.size()
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var note_idx = mini(int(t / note_dur), notes.size() - 1)
		var note_t = fmod(t, note_dur) / note_dur
		var freq = notes[note_idx]
		phase += freq * (TAU / rate)
		
		var env = exp(-note_t * 3.0)
		var wave = sin(phase) * 0.65 + sin(phase * 2.0) * 0.25
		samples[i] = wave * env * 0.75
	
	return _create_wav(samples, rate)

func _gen_click() -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.04
	var count = int(rate * duration)
	var samples = PackedFloat32Array()
	samples.resize(count)
	
	var phase = 0.0
	for i in range(count):
		var t = float(i) / rate
		var prog = t / duration
		phase += 880.0 * (TAU / rate)
		var env = 1.0 - prog
		samples[i] = sin(phase) * env * 0.5
	
	return _create_wav(samples, rate)
