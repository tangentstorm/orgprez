@tool
class_name OrgPrezAudioTab extends VBoxContainer

signal audio_path_selected(path)

@onready var chunklist = find_child("ChunkList")
@onready var outline = find_child("Outline")
@onready var editor = find_child("CodeEditor")
@onready var prompter:LineEdit = find_child("Prompter")
@onready var update_button = find_child("UpdateButton")
@onready var repl = find_child("REPL")

var org:OrgNode : set = set_org
var current_chunk: OrgChunk
@onready var current_track = Org.Track.AUDIO : set = set_current_track
var last_caret_position = INF

func set_current_track(t):
	current_track = t
	#repl.visible = false;
	#match t:
		#Org.Track.AUDIO: wavepanel.visible = true
		#Org.Track.MACRO: repl.visible = true

func set_org(o:OrgNode):
	org = o
	chunklist.org_dir = org.get_dir()
	outline.set_org(org)

func _on_headline_selected(org):
	chunklist.set_org(org)
	if org != null: editor.text = org.slide_text()

func _on_chunk_selected(chunk:OrgChunk):
	current_chunk = chunk
	self.current_track = chunk.track
	prompter.text = chunk.lines_to_string()
	last_caret_position = INF
	update_button.disabled = true

func _on_audio_chunk_selected(chunk:OrgChunk):
	var wavepath = org.get_dir() + chunk.suggest_path()
	emit_signal("audio_path_selected", wavepath)

func _on_macro_chunk_selected(chunk:OrgChunk):
	return

func _on_Prompter_text_changed(new_text):
	update_button.disabled = false

func _process(_dt):
	if current_track == Org.Track.MACRO:
		if prompter.caret_column != last_caret_position:
			# !! in jprez, modifying led notifies red to play the macro.
			# !! the following implements a jprez macro debugger.
			if prompter.text.begins_with(": . "):
				pass
				#var j = "notify__red '%s'" % prompter.text.left(prompter.caret_column).replace("'", "''")
				#repl.JI.cmd(j)
				#repl.refresh()
		last_caret_position = prompter.caret_column

func _on_UpdateButton_pressed():
	var chunk = current_chunk
	var old_path = chunk.suggest_path() if chunk.track == Org.Track.AUDIO else ''
	chunk.lines = []
	for line in prompter.text.split("\n"):
		chunk.lines.push_back(line)
	if current_track == Org.Track.AUDIO:
		var new_path = chunk.suggest_path()
		var d = DirAccess.open(org.get_dir())
		assert(d) #,"couldn't open org directory %s ?!" % org.get_dir())
		if d.file_exists(old_path):
			if d.file_exists(new_path):
				print("old_path:", old_path)
				print("new_path:", new_path)
				printerr('both old and new paths already exist!')
			else: assert(d.rename(old_path, new_path) == OK) #,"couldn't rename %s to %s" % [old_path, new_path])
	else: pass
	org.save()

func _on_macro_track_selected(chunk:OrgChunk):
	self.current_track = Org.Track.MACRO
