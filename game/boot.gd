extends Node

func _ready() -> void:
	var scene := "res://game/probe.tscn" if "--probe" in OS.get_cmdline_user_args() else "res://game/prototype.tscn"
	add_child((load(scene) as PackedScene).instantiate())
