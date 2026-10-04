extends AudioStreamPlayer
## Original synthesized placeholder, no external sound assets.
func _ready() -> void:
	volume_db = -20
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_8_BITS
	sound.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(2205)
	var noise := RandomNumberGenerator.new()
	noise.seed = 71
	for i in range(samples.size()):
		var time := float(i) / sound.mix_rate
		var envelope := exp(-time * 60)
		var value := (noise.randf_range(-1, 1) * 0.7 + sin(time * TAU * 130) * 0.3) * envelope
		# AudioStreamWAV expects signed 8-bit PCM, represented as byte bits.
		samples[i] = int(clampf(value * 100, -127, 127)) & 255
	sound.data = samples
	stream = sound
