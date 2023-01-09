class_name OrgPrezStepper extends Window

signal orgprez_line_changed(scene, cmd)
signal orgprez_node_changed(orgNode)

var script_engine: Node

var org : OrgNode : set = set_org
const OT = Org.Track
var sync_pending = false
var playing = false
var step_ready = false
var old_slide = 0
var tracks: Array
var track_ready: Array
var this_audio_chunk
var next_audio_chunk
var slide_just_changed = false

@onready var ChunkList = find_child("ChunkList")
@onready var Outline:OrgPrezOutline = find_child("Outline")

func _ready():
	Outline.connect("node_selected",Callable(ChunkList,"set_org"))
	Outline.connect("node_selected",Callable(self,"_on_outline_node_selected"))
	$AudioStreamPlayer.connect("finished",Callable(self,"_on_audio_finished"))

func set_org(o:OrgNode):
	org = o
	ChunkList.org_dir = org.get_dir()
	Outline.set_org(org)
	tracks = []; track_ready = []
	for t in Org.Track.values():
		tracks.push_back(OrgCursor.new(org))
		tracks[t].find_next(t)
		track_ready.push_back(true) # everything's ready to go at the start
	this_audio_chunk = tracks[OT.AUDIO].this_chunk()
	next_audio_chunk = tracks[OT.AUDIO].next_chunk()
	show_debug_state()

func _on_audio_finished():
	track_ready[OT.AUDIO] = true
	this_audio_chunk = next_audio_chunk
	next_audio_chunk = tracks[OT.AUDIO].find_next(OT.AUDIO)

func _on_script_finished(_id, _result):
	track_ready[OT.EVENT] = true
	tracks[OT.EVENT].find_next(OT.EVENT)

func _on_macro_finished():
	track_ready[OT.MACRO] = true

func track_to_step():
	# find the hindmost cursor:
	var hindmost_index = next_audio_chunk.index if next_audio_chunk else INF
	var hindmost_track = null
	for track in OT.values():
		if track_ready[track]:
			var chunk = this_audio_chunk if track == OT.AUDIO else tracks[track].this_chunk()
			if not chunk: continue
			if chunk.index < hindmost_index:
				hindmost_track = track
				hindmost_index = chunk.index
	# if hindmost_track != null: print("hindmost track:", OT.keys()[hindmost_track])
	return hindmost_track

func _process(_dt):
	# no stepping past @sync until all tracks are ready:
	# (this generally means wait for the audio to finish before starting next step)
	if sync_pending:
		sync_pending = false
		for track in OT.values():
			if not track_ready[track]: sync_pending = true
	# only one step per frame:
	if playing or step_ready:
		step_ready = playing
		match track_to_step():
			OT.EVENT: process_event_track()
			OT.MACRO: process_macro_track()
			OT.AUDIO: process_audio_track()
			null: step_ready = true
		show_debug_state()

func show_debug_state():
	# draw the cursors checked the tree control
	ChunkList.clear_highlights()
	ChunkList.highlight_chunk(tracks[OT.EVENT].this_chunk(), Color.ROYAL_BLUE)
	ChunkList.highlight_chunk(tracks[OT.MACRO].this_chunk(), Color.DARK_SLATE_GRAY)
	ChunkList.highlight_chunk(this_audio_chunk, Color.GOLDENROD if track_ready[OT.AUDIO] else Color.DARK_GOLDENROD)
	ChunkList.highlight_chunk(next_audio_chunk, Color.SIENNA)

func process_event_track():
	if track_ready[OT.EVENT] and track_ready[OT.MACRO]:
		var event_chunk = tracks[OT.EVENT].this_chunk()
		if not event_chunk: return
		if this_audio_chunk == null or event_chunk.index < this_audio_chunk.index:
			var script:String = tracks[OT.EVENT].this_chunk().lines_to_string()
			if script == '@sync':
				# we handle this one separately from script_engine because it's really about the stepper.
				sync_pending = true
				tracks[OT.EVENT].find_next(OT.EVENT)
			elif script_engine:
				script_engine.execute(0, script)
				track_ready[OT.EVENT] = false

func process_audio_track():
	if track_ready[OT.AUDIO] and track_ready[OT.MACRO] and track_ready[OT.EVENT]:
		if this_audio_chunk:
			if this_audio_chunk.file_exists(org.get_dir()):
				track_ready[OT.AUDIO] = false
				var sample : AudioStreamWAV = load(org.get_dir() + this_audio_chunk.suggest_path())
				$AudioStreamPlayer.stream = sample
				$AudioStreamPlayer.play()
				if this_audio_chunk.jpxy.x > old_slide:
					slide_just_changed = true
					Outline.get_node("Tree").get_selected().get_next().select(0)
					# !! do i need next line? maybe it just works..?
					# emit_signal('orgprez_node_changed', Outline.get_current_org_node())
				old_slide = this_audio_chunk.jpxy.x

func process_macro_track():
	if track_ready[OT.MACRO] and track_ready[OT.EVENT]:
		# fire if that chunk comes before the *next* audio track.
		var macro_chunk = tracks[OT.MACRO].this_chunk()
		if not macro_chunk: return
		if next_audio_chunk == null or macro_chunk.index < next_audio_chunk.index:
			track_ready[OT.MACRO] = false
			var ix = macro_chunk.jpxy
			emit_signal('orgprez_line_changed', ix.x, ix.y)
			var next_macro = tracks[OT.MACRO].find_next(OT.MACRO)
			if not next_macro: track_ready[OT.MACRO] = false

func _on_PlayButton_pressed():
	playing = not playing

func _on_StepButton_pressed():
	step_ready = true

func reset_ready_flags():
	track_ready[OT.AUDIO] = true
	track_ready[OT.EVENT] = true
	track_ready[OT.MACRO] = true

func _on_ChunkList_chunk_selected(chunk):
	if slide_just_changed:
		slide_just_changed = false
		return
	if not len(tracks): return
	for track in Org.Track.values():
		reset_ready_flags()
		var track_chunk = tracks[track].goto_index(chunk.index, track)
		if track == OT.AUDIO:
			this_audio_chunk = track_chunk
			next_audio_chunk = tracks[track].find_next(track)
		old_slide = this_audio_chunk.jpxy.x
	var ix = chunk.jpxy
	emit_signal('orgprez_line_changed', ix.x, ix.y)
	show_debug_state()

func _on_outline_node_selected(orgNode):
	emit_signal("orgprez_node_changed", orgNode)

func get_current_org_node():
	return Outline.get_current_org_node()
