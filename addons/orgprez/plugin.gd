# presentation tool for emacs org files
@tool
extends EditorPlugin

const audioTabScene = preload('res://addons/orgprez/OrgPrezAudioTab.tscn')
var audioTabNode # member variable holding instance of audioTabScene

var org_import
func _enter_tree():
	print("GOT HERE")
	audioTabNode = audioTabScene.instantiate()
	print("GOT HERE2")
	get_editor_interface().get_editor_main_screen().add_child(audioTabNode)
	print("GOT HERE3")
	audioTabNode.connect("audio_path_selected",Callable(self,"_on_audioTab_audio_path_selected"))
	_make_visible(false) # otherwise it shows up checked-screen no matter what tab is active
	org_import = preload("res://addons/orgprez/org_import.gd").new()
	add_import_plugin(org_import)

	var org_path = ProjectSettings.get("global/default_org_file")
	if org_path:
		var org = load(org_path)
		if org:
			edit(org)

func _has_main_screen():
	return true

func _get_plugin_name():
	return "OrgPrez" # used in top-level tab name

func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("AutoKey", "EditorIcons")

func _make_visible(x): # called at startup and when the tab is changed
	if audioTabNode: audioTabNode.visible = x

func handles(object):
	return object is OrgNode

func edit(org):
	# remember directory for saving wave files
	# TODO: make this wav_dir
	# wav_dir = org.resource_path.get_base_dir()
	# if not wav_dir.ends_with('/'): wav_dir += '/'
	# chunks.org_dir = wav_dir  # !! only need for waves, so update chunks code
	# wav_dir += '.wav'

	# tell the audioTabNode to load that org-file
	# chunks.set_org(org) # outln will override this with first node (if one exists)
	# outln.set_org(org)
	# jprez.set_org(org)

	audioTabNode.set_org(org)
	ProjectSettings.set_setting("global/default_org_file", org.resource_path)
	ProjectSettings.save()

func _exit_tree():
	if audioTabNode: audioTabNode.queue_free()
	remove_import_plugin(org_import); org_import = null

func _on_audioTab_audio_path_selected(path):
	var clip : AudioStreamWAV
	if ResourceLoader.exists(path): clip = load(path)
	else:
		clip = AudioStreamWAV.new()
		clip.resource_path = path
	get_editor_interface().edit_resource(clip)
