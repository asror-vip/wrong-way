extends Node

var players: Dictionary = {}
var music_player: AudioStreamPlayer = null
var is_gameplay_mode: bool = false
var music_vol_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_procedural_sounds()
	_setup_music_player()
	
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
	players["die"] = _create_player(_generate_tone(360.0, 60.0, 0.28, "sawtooth", 0.16))
	players["trap"] = _create_player(_generate_tone(440.0, 130.0, 0.15, "triangle", 0.14))
	players["win"] = _create_player(_generate_win_chord())
	players["land"] = _create_player(_generate_tone(180.0, 90.0, 0.06, "triangle", 0.08))
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
		players[sound_name].play()

func play_click() -> void: play("click")
func play_jump() -> void: play("jump")
func play_die() -> void: play("die")
func play_trap() -> void: play("trap")
func play_win() -> void: play("win")
func play_land() -> void: play("land")

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
