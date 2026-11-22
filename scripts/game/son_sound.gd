class_name SonSound
extends RefCounted

static func cue(kind: String) -> AudioStreamWAV:
	var rate = 22050
	var duration = 0.25
	if kind == "wind": duration = 1.2
	if kind == "fire": duration = 0.8
	var count = int(rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(count * 2)
	var random = RandomNumberGenerator.new()
	random.seed = 1337 + kind.length()
	var filtered = 0.0
	for i in count:
		var t = float(i) / rate
		var envelope = minf(1.0, t * 25.0) * minf(1.0, (duration - t) * 7.0)
		var sample = 0.0
		if kind == "knock":
			var pulse = exp(-t*18.0) + (exp(-(t-0.11)*25.0) if t > 0.11 else 0.0)
			sample = sin(TAU*115.0*t) * pulse * 0.26
		elif kind == "swipe":
			filtered = lerpf(filtered, random.randf_range(-1.0,1.0), 0.14)
			sample = filtered * sin(PI*t/duration) * 0.16
		elif kind == "wind":
			filtered = lerpf(filtered, random.randf_range(-1.0,1.0), 0.025)
			sample = filtered * 0.16 * envelope
		else:
			filtered = lerpf(filtered, random.randf_range(-1.0,1.0), 0.08)
			sample = filtered * 0.1 * envelope
			if random.randf() > 0.998: sample += random.randf_range(-0.15,0.15)
		bytes.encode_s16(i*2, clampi(int(sample*32767.0),-32767,32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream
