extends RefCounted
## Only preferences; this is not the later run/save-slot schema.
var path := "user://settings.cfg"
var volume := 0.35
var shake_enabled := true

func load_values() -> void:
	volume = 0.35
	shake_enabled = true
	var config := ConfigFile.new()
	if config.load(path) != OK or config.get_value("meta", "schema", 0) != 1:
		return
	var saved_volume = config.get_value("audio", "volume", volume)
	if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
		volume = clampf(float(saved_volume), 0, 1)
	var saved_shake = config.get_value("display", "shake", shake_enabled)
	if saved_shake is bool:
		shake_enabled = saved_shake

func save_values() -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "schema", 1)
	config.set_value("audio", "volume", clampf(volume, 0, 1))
	config.set_value("display", "shake", shake_enabled)
	var result := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if result != OK:
		return result
	result = config.save(path + ".tmp")
	if result != OK:
		return result
	return DirAccess.rename_absolute(path + ".tmp", path)
