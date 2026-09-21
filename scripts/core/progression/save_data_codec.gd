extends RefCounted
class_name SaveDataCodec

static func migrate(data: Dictionary, supported_version: int) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var version: int = int(migrated.get("version", 0))
	if version <= 0:
		migrated["version"] = 1
	if int(migrated.get("version", 1)) > supported_version:
		push_warning("SaveDataCodec: save version %d is newer than supported version %d." % [int(migrated["version"]), supported_version])
	return migrated

static func string_keyed_dict(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key in source.keys():
		out[String(key)] = source[key]
	return out

static func string_array(source: Array) -> Array[String]:
	var out: Array[String] = []
	for value in source:
		out.append(String(value))
	return out

static func parse_string_name_array(source: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if source is not Array:
		return out
	for value in source:
		var id: StringName = StringName(String(value))
		if id != &"":
			out.append(id)
	return out

static func parse_string_array(source: Variant) -> Array[String]:
	var out: Array[String] = []
	if source is not Array:
		return out
	for value in source:
		var text: String = String(value)
		if not text.is_empty():
			out.append(text)
	return out

static func parse_int_array(source: Variant) -> Array[int]:
	var out: Array[int] = []
	if source is not Array:
		return out
	for value in source:
		out.append(int(value))
	return out

static func apply_int_dict(source: Variant, target: Dictionary, allowed_keys: Array[StringName]) -> void:
	if source is not Dictionary:
		return
	var source_dict: Dictionary = source as Dictionary
	for key in allowed_keys:
		if source_dict.has(String(key)):
			target[key] = maxi(0, int(source_dict[String(key)]))

static func apply_bool_dict(source: Variant, target: Dictionary, allowed_keys: Array[StringName]) -> void:
	if source is not Dictionary:
		return
	var source_dict: Dictionary = source as Dictionary
	for key in allowed_keys:
		if source_dict.has(String(key)):
			target[key] = bool(source_dict[String(key)])
