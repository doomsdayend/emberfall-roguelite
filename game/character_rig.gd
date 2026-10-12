extends Skeleton2D
## Editable skeleton/attachment contract. No final artwork is supplied here.

const SPEC_PATH := "res://assets/source/emberblade-rig-spec.json"
var bones: Dictionary = {}
var attachments: Dictionary = {}
var specification: Dictionary = {}

func build() -> void:
	assert(bones.is_empty(), "Rig may only be built once")
	specification = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
	for entry in specification.bones:
		var bone := Bone2D.new()
		bone.name = entry.id
		bone.position = Vector2(entry.position[0], entry.position[1])
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(entry.length)
		var parent: Node = self if entry.parent == "" else bones[entry.parent]
		parent.add_child(bone)
		bone.rest = bone.transform
		bones[entry.id] = bone
	for entry in specification.attachments:
		var marker := Marker2D.new()
		marker.name = "slot_" + entry.id
		marker.position = Vector2(entry.position[0], entry.position[1])
		bones[entry.parent].add_child(marker)
		attachments[entry.id] = marker

func reset_pose() -> void:
	for bone: Bone2D in bones.values():
		bone.transform = bone.rest
