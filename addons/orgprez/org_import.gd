# importer for orgprez-flavored .org files
# https://docs.godotengine.org/en/stable/tutorials/plugins/editor/import_plugins.html
@tool
extends EditorImportPlugin

func _get_importer_name():
	return "org.prez"

func _get_visible_name():
	return "orgprez screenplay (*.org)"

func _get_recognized_extensions():
	return ["org"]

func _get_save_extension():
	return "res"

func _get_resource_type():
	return "Resource"

enum Presets { DEFAULT }

func _get_preset_count():
	return Presets.size()

func _get_preset_name(preset):
	match preset:
		Presets.DEFAULT: return "Default"
		_: return "Unknown"

func _get_import_options(preset:String, index:int)->Array[Dictionary]:
	return []

func _get_import_order()->int:
	return 0

func _get_option_visibility(path, opt, opts):
	return true

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	# TODO: error trapping
	var org:OrgNode = Org.from_path(source_file)
	ResourceSaver.save(org, "%s.%s" % [save_path, _get_save_extension()])
	return org
