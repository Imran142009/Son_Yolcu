extends Control

var appearance: Dictionary = {}
var silhouette := false
const INK := Color(0.62,0.61,0.58,0.9)
const SHADOW := Color(0.14,0.16,0.18,1.0)

func _ready() -> void:
	custom_minimum_size = Vector2(124, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center = Vector2(size.x/2.0, 62)
	var color = SHADOW if silhouette else INK
	# Deliberately simple outlines rather than painted faces.
	draw_arc(center, 28, 0, TAU, 48, color, 1.4, true)
	draw_line(center + Vector2(-19,23), center + Vector2(-35,42), color, 1.5, true)
	draw_line(center + Vector2(19,23), center + Vector2(35,42), color, 1.5, true)
	draw_line(center + Vector2(-35,42), center + Vector2(-41,69), color, 1.5, true)
	draw_line(center + Vector2(35,42), center + Vector2(41,69), color, 1.5, true)
	draw_line(center + Vector2(-41,69), center + Vector2(41,69), color, 1.5, true)
	var hair = int(appearance.get("hair",0))
	if hair == 0:
		draw_arc(center + Vector2(0,-7), 24, PI, TAU, 20, color, 3.0, true)
	elif hair == 1:
		draw_line(center + Vector2(-27,-3), center + Vector2(-20,-24), color, 3.0, true)
		draw_line(center + Vector2(-20,-24), center + Vector2(21,-23), color, 3.0, true)
		draw_line(center + Vector2(21,-23), center + Vector2(27,5), color, 3.0, true)
	elif hair == 2:
		draw_arc(center + Vector2(0,-6), 27, PI, TAU, 30, color, 2.0, true)
		draw_line(center + Vector2(-27,-6), center + Vector2(-30,15), color, 2.0, true)
		draw_line(center + Vector2(27,-6), center + Vector2(30,15), color, 2.0, true)
	if int(appearance.get("hat",0)) == 1:
		draw_line(center + Vector2(-28,-21), center + Vector2(28,-21), color, 2.0, true)
		draw_line(center + Vector2(-20,-21), center + Vector2(-17,-34), color, 2.0, true)
		draw_line(center + Vector2(-17,-34), center + Vector2(17,-34), color, 2.0, true)
		draw_line(center + Vector2(17,-34), center + Vector2(20,-21), color, 2.0, true)
	if not silhouette:
		draw_circle(center + Vector2(-9,-2), 1.6, color)
		draw_circle(center + Vector2(9,-2), 1.6, color)
		draw_line(center + Vector2(-4,11), center + Vector2(4,11), color, 1.0, true)
		if int(appearance.get("coat",0)) == 1:
			draw_line(center + Vector2(-6,27), center + Vector2(0,40), color, 1.0, true)
			draw_line(center + Vector2(6,27), center + Vector2(0,40), color, 1.0, true)
