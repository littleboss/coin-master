extends Node
## 程序生成的短音效。不依赖 Pixel 音频资源。process 永远开着，暂停菜单也能点按出声。

const SAMPLE_RATE := 22050
const VOICES := 8

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _peg_gate: float = 0.0

var _ui: AudioStreamWAV
var _toss: AudioStreamWAV
var _peg: AudioStreamWAV
var _slot: AudioStreamWAV
var _miss: AudioStreamWAV
var _jack_a: AudioStreamWAV
var _jack_b: AudioStreamWAV
var _jack_c: AudioStreamWAV


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = _tone(880.0, 0.05, 0.35, 2.8)
	_toss = _tone(180.0, 0.09, 0.45, 1.4)
	_peg = _tone(1240.0, 0.035, 0.28, 4.0)
	_slot = _tone(660.0, 0.10, 0.40, 2.2)
	_miss = _tone(110.0, 0.12, 0.35, 1.6)
	_jack_a = _tone(523.25, 0.09, 0.42, 1.8)
	_jack_b = _tone(659.25, 0.09, 0.42, 1.8)
	_jack_c = _tone(783.99, 0.16, 0.48, 1.5)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)


func _process(delta: float) -> void:
	if _peg_gate > 0.0:
		_peg_gate = maxf(0.0, _peg_gate - delta)


func play_ui() -> void:
	_play(_ui, 0.7)


func play_toss() -> void:
	_play(_toss, 0.85)


func play_peg() -> void:
	if _peg_gate > 0.0:
		return
	_peg_gate = 0.045
	_play(_peg, 0.55)


func play_slot(multiplier: int) -> void:
	if multiplier >= 10:
		play_jackpot()
		return
	if multiplier >= 2:
		_play(_slot, 0.9)
		return
	if multiplier >= 1:
		_play(_slot, 0.7)


func play_miss() -> void:
	_play(_miss, 0.65)


func play_jackpot() -> void:
	_play(_jack_a, 0.9)
	_play_later(_jack_b, 0.09, 0.9)
	_play_later(_jack_c, 0.18, 1.0)


func _play_later(stream: AudioStreamWAV, delay: float, volume: float) -> void:
	var t := get_tree().create_timer(delay, true, false, true)
	t.timeout.connect(func() -> void: _play(stream, volume))


func _play(stream: AudioStreamWAV, volume: float) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.volume_db = linear_to_db(clampf(volume, 0.05, 1.0))
	p.play()


func _tone(freq: float, duration: float, amp: float, decay: float) -> AudioStreamWAV:
	var n := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / float(SAMPLE_RATE)
		var env := exp(-decay * t) * (1.0 - t / duration)
		var s := sin(TAU * freq * t) * amp * env
		# 一点点二次谐波，听起来不像纯蜂鸣。
		s += 0.22 * sin(TAU * freq * 2.0 * t) * amp * env
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = v & 0xff
		bytes[i * 2 + 1] = (v >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = bytes
	return wav
