extends Control

var elapsed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	for i in range(16):
		var x = fposmod(float(i * 137 + 53), maxf(size.x,1.0))
		var y = fposmod(float(i * 97) + elapsed * (5.0 + float(i % 3)), maxf(size.y,1.0))
		draw_circle(Vector2(x,y), 0.8, Color(0.7,0.7,0.66,0.16))
