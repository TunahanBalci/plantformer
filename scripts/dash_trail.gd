class_name DashTrail
extends Line2D

const MAX_POINTS: int = 2000

@onready var curve := Curve2D.new()


func _process(delta: float) -> void:
	curve.add_point(get_parent().position)
	if curve.get_baked_points().size() > MAX_POINTS:
		curve.remove_point(0)
	points = curve.get_baked_points()

func stop() -> void:
	set_process(false)
	var tw := get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 3.0)
	await tw.finished
	queue_free()
	
static func	create() -> DashTrail:
	var scn = preload("res://scenes/dash_trail.tscn")

	return scn.instantiate()
