extends Node

# Autoload / Global Audio Manager with procedural synthesized retro SFX
# Generates AudioStreamWAV in-memory without external audio assets.

var sfx_focus: AudioStreamWAV
var sfx_select: AudioStreamWAV
var sfx_cancel: AudioStreamWAV
var sfx_flip_up: AudioStreamWAV
var sfx_flip_down: AudioStreamWAV
var sfx_gem: AudioStreamWAV
var sfx_hit: AudioStreamWAV
var sfx_clear: AudioStreamWAV

var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS # Can play sounds during pause
	for i in range(POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_players.append(p)
	
	_generate_sounds()

func _generate_sounds() -> void:
	sfx_focus = _create_beep_sfx(660.0, 0.04, 0.25)
	sfx_select = _create_two_tone_sfx(523.25, 783.99, 0.08, 0.3)
	sfx_cancel = _create_two_tone_sfx(659.25, 440.0, 0.08, 0.3)
	sfx_flip_up = _create_sweep_sfx(300.0, 800.0, 0.15, 0.4)
	sfx_flip_down = _create_sweep_sfx(700.0, 260.0, 0.15, 0.4)
	sfx_gem = _create_arpeggio_sfx([523.25, 659.25, 783.99, 1046.50], 0.04, 0.35)
	sfx_hit = _create_noise_sfx(0.18, 0.4)
	sfx_clear = _create_arpeggio_sfx([440.0, 554.37, 659.25, 880.0, 1108.73], 0.07, 0.4)

func play_sfx(stream: AudioStreamWAV, pitch_scale: float = 1.0) -> void:
	if not stream:
		return
	for p in audio_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale
			p.play()
			return
	# If all busy, steal the first one
	var p0 = audio_players[0]
	p0.stream = stream
	p0.pitch_scale = pitch_scale
	p0.play()

func play_focus() -> void:
	play_sfx(sfx_focus)

func play_select() -> void:
	play_sfx(sfx_select)

func play_cancel() -> void:
	play_sfx(sfx_cancel)

func play_flip(up: bool) -> void:
	play_sfx(sfx_flip_up if up else sfx_flip_down)

func play_gem() -> void:
	play_sfx(sfx_gem)

func play_hit() -> void:
	play_sfx(sfx_hit)

func play_clear() -> void:
	play_sfx(sfx_clear)

# ----------------- Procedural Sound Generators -----------------

func _create_wav(data: PackedByteArray, sample_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	return wav

func _create_beep_sfx(freq: float, duration: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	for i in range(total_samples):
		var t = float(i) / rate
		var env = 1.0 - (float(i) / total_samples) # Linear decay
		var sample = sin(2.0 * PI * freq * t) * env * vol
		bytes[i] = clampi(int((sample + 1.0) * 127.5), 0, 255)
	return _create_wav(bytes, rate)

func _create_two_tone_sfx(f1: float, f2: float, duration: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration * 2.0)
	var half = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	for i in range(total_samples):
		var t = float(i) / rate
		var freq = f1 if i < half else f2
		var env = 1.0 - (float(i) / total_samples) * 0.7
		var sample = sin(2.0 * PI * freq * t) * env * vol
		bytes[i] = clampi(int((sample + 1.0) * 127.5), 0, 255)
	return _create_wav(bytes, rate)

func _create_sweep_sfx(start_f: float, end_f: float, duration: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase = 0.0
	for i in range(total_samples):
		var p = float(i) / total_samples
		var freq = lerp(start_f, end_f, p)
		phase += 2.0 * PI * freq / rate
		var env = sin(p * PI) * vol # Bell envelope
		var sample = sin(phase) * env
		bytes[i] = clampi(int((sample + 1.0) * 127.5), 0, 255)
	return _create_wav(bytes, rate)

func _create_arpeggio_sfx(notes: Array, note_duration: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var note_samples = int(rate * note_duration)
	var total_samples = note_samples * notes.size()
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	for n_idx in range(notes.size()):
		var freq = notes[n_idx]
		var base_i = n_idx * note_samples
		for i in range(note_samples):
			var t = float(i) / rate
			var env = 1.0 - (float(i) / note_samples) * 0.8
			var sample = (sin(2.0 * PI * freq * t) + 0.3 * sin(4.0 * PI * freq * t)) * env * vol
			bytes[base_i + i] = clampi(int((sample + 1.0) * 127.5), 0, 255)
	return _create_wav(bytes, rate)

func _create_noise_sfx(duration: float, vol: float) -> AudioStreamWAV:
	var rate = 22050
	var total_samples = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	for i in range(total_samples):
		var env = (1.0 - float(i) / total_samples) ** 2.0
		var noise = (randf() * 2.0 - 1.0) * env * vol
		bytes[i] = clampi(int((noise + 1.0) * 127.5), 0, 255)
	return _create_wav(bytes, rate)
