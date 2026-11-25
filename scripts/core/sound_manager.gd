extends Node

var players: Dictionary = {}
var music_player: AudioStreamPlayer = null
var is_gameplay_mode: bool = false
var music_vol_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_procedural_sounds()
	_setup_music_player()
	# GameManager autoload tartibda keyinroq yuklanadi, shuning uchun deferred ulaymiz.
	_connect_gameplay_mode.call_deferred()

func _exit_tree() -> void:
	if music_vol_tween and music_vol_tween.is_valid():
		music_vol_tween.kill()
	if music_player:
		music_player.stop()
	for p in players.values():
		if p is AudioStreamPlayer:
			p.stop()

func _connect_gameplay_mode() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.level_started.connect(func(_lvl): set_gameplay_mode(true))

func _get_target_music_db() -> float:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.music_enabled:
		return -80.0
	var vol_linear: float = sm.music_volume if sm else 0.8
	if vol_linear <= 0.01:
		return -80.0
	var base_db: float = linear_to_db(vol_linear)
	if is_gameplay_mode:
		base_db -= 8.0 # O'yin va pauzada yumshoq fon ovozi
	return clampf(base_db, -80.0, 6.0)

func set_gameplay_mode(in_gameplay: bool) -> void:
	is_gameplay_mode = in_gameplay
	update_music_volume(true)

func update_music_volume(animate: bool = false) -> void:
	if not music_player: return
	var target_db := _get_target_music_db()
	if music_vol_tween and music_vol_tween.is_valid():
		music_vol_tween.kill()
		
	if animate and music_player.playing:
		music_vol_tween = create_tween()
		music_vol_tween.tween_property(music_player, "volume_db", target_db, 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		music_player.volume_db = target_db

func update_sfx_volume() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	var vol_linear: float = sm.sfx_volume if sm else 1.0
	var target_db: float = -80.0 if vol_linear <= 0.01 else linear_to_db(vol_linear)
	for p in players.values():
		if p is AudioStreamPlayer:
			p.volume_db = target_db

func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Master"
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = _get_target_music_db()
	add_child(music_player)
	
	music_player.finished.connect(func():
		var sm = get_node_or_null("/root/SaveManager")
		if sm == null or sm.music_enabled:
			music_player.play()
	)
	
	_load_bgm()
	
	# Start music if enabled
	call_deferred("_check_initial_music")

func _check_initial_music() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm == null or sm.music_enabled:
		play_music()

func _load_bgm() -> void:
	var path := "res://assets/audio/bgm_ambient.wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream is AudioStreamWAV:
			var bytes_per_frame: int = 4 if stream.stereo else 2
			var total_frames: int = stream.data.size() / bytes_per_frame
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = total_frames
		music_player.stream = stream

func play_music() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and not sm.music_enabled:
		return
	if music_player:
		if music_player.stream == null:
			_load_bgm()
		if music_player.stream and not music_player.playing:
			music_player.volume_db = _get_target_music_db()
			music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func set_music_enabled(enabled: bool) -> void:
	if enabled:
		play_music()
	else:
		stop_music()

func set_music_volume_pause(_is_paused: bool) -> void:
	# Foydalanuvchi talabi: Pauza menyusida ham o'yin ichidagi past ovoz o'zgarmasdan tursin
	pass

func _create_procedural_sounds() -> void:
	players["click"] = _create_player(_generate_tone(450.0, 800.0, 0.04, "sine", 0.08))
	players["jump"] = _create_player(_generate_tone(240.0, 650.0, 0.14, "square", 0.09))
	players["dash"] = _create_player(_generate_tone(580.0, 220.0, 0.12, "sine", 0.14))
	players["die"] = _create_player(_generate_tone(360.0, 60.0, 0.28, "sawtooth", 0.16))
	players["trap"] = _create_player(_generate_tone(440.0, 130.0, 0.15, "triangle", 0.14))
	players["win"] = _create_player(_generate_win_chord())
	players["land"] = _create_player(_generate_tone(180.0, 90.0, 0.06, "triangle", 0.08))
	players["flicker"] = _create_player(_generate_tone(720.0, 140.0, 0.14, "sawtooth", 0.09))
	players["glitch"] = _create_player(_generate_glitch_sound())
	players["whisper_boom"] = _create_player(_generate_tone(92.0, 32.0, 0.55, "triangle", 0.19))
	players["thunder"] = _create_player(_generate_thunder_sound())
	players["portal"] = _create_player(_generate_tone(290.0, 840.0, 0.26, "sine", 0.12))
	players["reverse_chime"] = _create_player(_generate_reverse_chime())
	# Biome-specific procedural trap SFX (lightweight, crisp, anti-click ramped, balanced RMS)
	players["biome_stone_shatter"] = _create_player(_generate_noise_impact(0.24, 130.0, 48.0, 0.22, 0.27, 101))
	players["biome_snow_burst"] = _create_player(_generate_noise_impact(0.26, 175.0, 85.0, 0.45, 0.24, 202))
	players["biome_ice_shatter"] = _create_player(_generate_ice_shatter())
	players["biome_vine_snap"] = _create_player(_generate_vine_snap())
	players["biome_sand_crumble"] = _create_player(_generate_noise_impact(0.25, 220.0, 110.0, 0.58, 0.23, 404))
	players["biome_lava_burst"] = _create_player(_generate_lava_burst())
	players["biome_frost_snap"] = _create_player(_generate_smooth_tone(1280.0, 620.0, 0.11, "sine", 0.12))
	players["biome_vine_whip"] = _create_player(_generate_smooth_tone(310.0, 690.0, 0.12, "triangle", 0.13))
	players["biome_desert_click"] = _create_player(_generate_smooth_tone(520.0, 190.0, 0.12, "triangle", 0.14))
	players["biome_magma_hiss"] = _create_player(_generate_noise_impact(0.16, 160.0, 65.0, 0.72, 0.21, 505))
	update_sfx_volume()

func _create_player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func play(sound_name: String) -> void:
	if is_inside_tree():
		var sm = get_node_or_null("/root/SaveManager")
		if sm and not sm.sfx_enabled:
			return
	if players.has(sound_name):
		var p: AudioStreamPlayer = players[sound_name]
		if sound_name == "jump" or sound_name == "land" or sound_name == "dash":
			p.pitch_scale = randf_range(0.93, 1.08)
		else:
			p.pitch_scale = 1.0
		p.play()

func play_click() -> void: play("click")
func play_jump() -> void: play("jump")
func play_dash() -> void: play("dash")
func play_die() -> void: play("die")
func play_trap() -> void: play("trap")
func play_win() -> void: play("win")
func play_land() -> void: play("land")

func play_biome_trap(action: String, chapter: int = -1) -> void:
	if is_inside_tree():
		var sm = get_node_or_null("/root/SaveManager")
		if sm and not sm.sfx_enabled:
			return
	var ch := chapter
	if ch <= 0 and is_inside_tree():
		var gm = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_current_chapter"):
			ch = int(gm.get_current_chapter())
	ch = clampi(ch, 1, 5)

	var sound_key := "trap"
	match action:
		"boulder_shatter":
			match ch:
				2: sound_key = "biome_snow_burst"
				3: sound_key = "biome_vine_snap"
				4: sound_key = "biome_sand_crumble"
				5: sound_key = "biome_lava_burst"
				_: sound_key = "biome_stone_shatter"
		"ice_shatter", "stalactite_impact":
			match ch:
				2: sound_key = "biome_ice_shatter"
				3: sound_key = "biome_vine_snap"
				4: sound_key = "biome_sand_crumble"
				5: sound_key = "biome_lava_burst"
				_: sound_key = "biome_stone_shatter"
		"slam", "impact":
			match ch:
				2: sound_key = "biome_snow_burst"
				3: sound_key = "biome_vine_snap"
				4: sound_key = "biome_sand_crumble"
				5: sound_key = "biome_lava_burst"
				_: sound_key = "biome_stone_shatter"
		"crumble":
			match ch:
				2: sound_key = "biome_ice_shatter"
				3: sound_key = "biome_vine_snap"
				4: sound_key = "biome_sand_crumble"
				5: sound_key = "biome_lava_burst"
				_: sound_key = "biome_stone_shatter"
		"spring":
			match ch:
				2: sound_key = "biome_frost_snap"
				3: sound_key = "biome_vine_whip"
				4: sound_key = "biome_desert_click"
				5: sound_key = "biome_magma_hiss"
				_: sound_key = "jump"
		"beam":
			match ch:
				2: sound_key = "biome_frost_snap"
				3: sound_key = "biome_vine_whip"
				4: sound_key = "biome_desert_click"
				5: sound_key = "biome_magma_hiss"
				_: sound_key = "trap"
		_: # "trigger" / default
			match ch:
				2: sound_key = "biome_frost_snap"
				3: sound_key = "biome_vine_whip"
				4: sound_key = "biome_desert_click"
				5: sound_key = "biome_magma_hiss"
				_: sound_key = "trap"

	if players.has(sound_key):
		var p: AudioStreamPlayer = players[sound_key]
		p.pitch_scale = randf_range(0.94, 1.07)
		p.play()
	else:
		play("trap")

func _generate_tone(f_start: float, f_end: float, duration: float, type: String, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2) # 16-bit (har bir sample 2 bayt)
	
	var phase := 0.0
	for i in range(samples_count):
		var t := float(i) / rate
		var prog := t / duration
		var freq: float = lerp(f_start, f_end, prog)
		phase += 2.0 * PI * freq / rate
		
		var raw_sample := 0.0
		match type:
			"sine":
				raw_sample = sin(phase)
			"square":
				raw_sample = 1.0 if sin(phase) >= 0.0 else -1.0
			"sawtooth":
				raw_sample = 2.0 * (phase / (2.0 * PI) - floor(phase / (2.0 * PI) + 0.5))
			"triangle":
				raw_sample = 2.0 * abs(2.0 * (phase / (2.0 * PI) - floor(phase / (2.0 * PI) + 0.5))) - 1.0
				
		var env := (1.0 - prog) * gain
		var sample_val := clampi(int(raw_sample * env * 32767.0), -32768, 32767)
		
		# Little-endian 16-bit
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_win_chord() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.6
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	
	var freqs: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(samples_count):
		var t := float(i) / rate
		var total_sample := 0.0
		for j in range(freqs.size()):
			var note_t: float = t - (float(j) * 0.08)
			if note_t >= 0.0 and note_t <= 0.2:
				phases[j] += 2.0 * PI * freqs[j] / rate
				var env := (1.0 - (note_t / 0.2)) * 0.12
				total_sample += sin(phases[j]) * env
				
		var sample_val := clampi(int(total_sample * 32767.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
		
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_glitch_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.32
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var phase := 0.0
	var step_freqs := [880.0, 210.0, 1240.0, 155.0, 660.0, 95.0, 1420.0, 180.0]
	for i in range(samples_count):
		var t := float(i) / rate
		var prog := t / duration
		var seg := mini(int(prog * float(step_freqs.size())), step_freqs.size() - 1)
		var freq: float = step_freqs[seg]
		phase += 2.0 * PI * freq / rate
		var sq := 1.0 if sin(phase) >= 0.0 else -1.0
		var env := (1.0 - prog * 0.85) * 0.12
		var sample_val := clampi(int(sq * env * 32767.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_thunder_sound() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.65
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var lp := 0.0
	var sub_phase := 0.0
	var seed_val: int = 1337
	for i in range(samples_count):
		var t := float(i) / rate
		var prog := t / duration
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(seed_val) / 1073741824.0) - 1.0
		lp = lerpf(lp, noise, 0.18 if prog < 0.2 else 0.06)
		sub_phase += 2.0 * PI * lerpf(85.0, 34.0, prog) / rate
		var crack := lp * pow(1.0 - prog, 1.4) * 0.24
		var rumble := sin(sub_phase) * (1.0 - prog) * 0.14
		var sample_val := clampi(int((crack + rumble) * 32767.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_reverse_chime() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.42
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var p1 := 0.0
	var p2 := 0.0
	for i in range(samples_count):
		var t := float(i) / rate
		var prog := t / duration
		p1 += 2.0 * PI * 392.0 / rate
		p2 += 2.0 * PI * 554.37 / rate # Tritone for uncanny aura
		var env := pow(prog, 1.8) * (1.0 - maxf(0.0, (prog - 0.85) / 0.15)) * 0.13
		var s := (sin(p1) * 0.6 + sin(p2) * 0.4) * env
		var sample_val := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


func _generate_smooth_tone(f_start: float, f_end: float, duration: float, type: String, gain: float) -> AudioStreamWAV:
	var rate := 22050
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var phase := 0.0
	var attack_samples := 66.0 # ~3ms anti-click attack ramp
	for i in range(samples_count):
		var prog := float(i) / float(maxi(1, samples_count))
		var freq: float = lerpf(f_start, f_end, prog)
		phase += TAU * freq / rate
		var raw_sample := 0.0
		match type:
			"sine":
				raw_sample = sin(phase)
			"triangle":
				raw_sample = 2.0 * absf(2.0 * (phase / TAU - floor(phase / TAU + 0.5))) - 1.0
			_:
				raw_sample = sin(phase)
		var atk := minf(1.0, float(i) / attack_samples)
		var env := atk * (1.0 - prog) * gain
		var sample_val := clampi(int(raw_sample * env * 32767.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_noise_impact(duration: float, f_start: float, f_end: float, brightness: float, gain: float, init_seed: int) -> AudioStreamWAV:
	var rate := 22050
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var lp := 0.0
	var phase := 0.0
	var seed_val: int = init_seed
	var attack_samples := 66.0
	for i in range(samples_count):
		var prog := float(i) / float(maxi(1, samples_count))
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(seed_val) / 1073741824.0) - 1.0
		lp = lerpf(lp, noise, clampf(brightness, 0.08, 0.92))
		var freq := lerpf(f_start, f_end, prog)
		phase += TAU * freq / rate
		var atk := minf(1.0, float(i) / attack_samples)
		var env := atk * pow(1.0 - prog, 1.55) * gain
		var s := (lp * 0.65 + sin(phase) * 0.45 * (1.0 - prog)) * env
		var val := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_ice_shatter() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.24
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	var seed_val: int = 707
	var attack_samples := 55.0
	for i in range(samples_count):
		var prog := float(i) / float(samples_count)
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(seed_val) / 1073741824.0) - 1.0
		p1 += TAU * 1760.0 / rate
		p2 += TAU * 2489.0 / rate
		p3 += TAU * 3322.0 / rate
		var atk := minf(1.0, float(i) / attack_samples)
		var chime := (sin(p1) * 0.45 + sin(p2) * 0.35 + sin(p3) * 0.20) * pow(1.0 - prog, 1.8)
		var crack := noise * pow(maxf(0.0, 1.0 - prog * 2.6), 1.6) * 0.55
		var s := (chime + crack) * atk * 0.17
		var val := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_vine_snap() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.22
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var phase := 0.0
	var lp := 0.0
	var seed_val: int = 303
	var attack_samples := 55.0
	for i in range(samples_count):
		var prog := float(i) / float(samples_count)
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(seed_val) / 1073741824.0) - 1.0
		lp = lerpf(lp, noise, 0.36)
		var snap_freq := lerpf(480.0, 140.0, minf(1.0, prog * 3.0))
		phase += TAU * snap_freq / rate
		var atk := minf(1.0, float(i) / attack_samples)
		var crack := sin(phase) * pow(maxf(0.0, 1.0 - prog * 2.8), 1.4) * 0.65
		var rustle := lp * pow(1.0 - prog, 1.2) * 0.50
		var s := (crack + rustle) * atk * 0.23
		var val := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav

func _generate_lava_burst() -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.30
	var samples_count := int(rate * duration)
	var data := PackedByteArray()
	data.resize(samples_count * 2)
	var phase := 0.0
	var lp := 0.0
	var seed_val: int = 909
	var attack_samples := 66.0
	for i in range(samples_count):
		var prog := float(i) / float(samples_count)
		seed_val = (seed_val * 1103515245 + 12345) & 0x7FFFFFFF
		var noise := (float(seed_val) / 1073741824.0) - 1.0
		lp = lerpf(lp, noise, 0.65)
		phase += TAU * lerpf(115.0, 38.0, prog) / rate
		var atk := minf(1.0, float(i) / attack_samples)
		var boom := sin(phase) * pow(1.0 - prog, 1.3) * 0.65
		var sizzle := lp * pow(1.0 - prog, 1.1) * 0.45
		var s := (boom + sizzle) * atk * 0.19
		var val := clampi(int(s * 32767.0), -32768, 32767)
		data[i * 2] = val & 0xFF
		data[i * 2 + 1] = (val >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav
