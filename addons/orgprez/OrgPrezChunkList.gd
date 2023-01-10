@tool
extends VBoxContainer
# visual representation of OrgChunk list

enum Col { INDEX, JPXY, TEXT }

signal audio_chunk_selected(chunk)
signal macro_chunk_selected(chunk)
signal event_chunk_selected(chunk)
signal chunk_selected(chunk)

@export var org_dir:String = 'res://'
@onready var tree : Tree = $Tree
@onready var track_names = Org.Track.keys()

func set_org(org:OrgNode):
	tree.clear()
	var root = tree.create_item()
	for col in Col.values():
		tree.set_column_custom_minimum_width(col, 60)
		tree.set_column_expand(col, false)
	tree.set_column_custom_minimum_width(Col.INDEX, 32)
	tree.set_column_expand(Col.TEXT, true)
	if not org: return
	for chunk in org.chunks:
		var item : TreeItem = tree.create_item(root)
		item.set_text(Col.INDEX, str(chunk.index))
		# item.set_text(Col.TRACK, track_names[chunk.track][0].to_lower())
		item.set_text(Col.JPXY, ' %d %d'%[chunk.jpxy.x, chunk.jpxy.y]); item.set_custom_color(Col.JPXY, Color.DARK_GRAY)
		for c in [Col.INDEX]: item.set_text_alignment(c, HORIZONTAL_ALIGNMENT_RIGHT)
		item.set_text(Col.TEXT, chunk.to_string())
		item.set_meta('chunk', chunk)
		var color = Color.WHITE
		match chunk.track:
			Org.Track.AUDIO:
				if not chunk.file_exists(org_dir): color = Color.ORANGE_RED
			Org.Track.MACRO: color = Color.LIGHT_SEA_GREEN
			Org.Track.EVENT: color = Color.CORNFLOWER_BLUE
		item.set_custom_color(Col.TEXT, color)

	var first = tree.get_root().get_children()
	if first: first.select(Col.TEXT)

func _on_Tree_item_selected():
	var chunk = tree.get_selected().get_meta('chunk')
	if not chunk: return
	match chunk.track:
		Org.Track.AUDIO: emit_signal("audio_chunk_selected", chunk)
		Org.Track.MACRO: emit_signal("macro_chunk_selected", chunk)
		Org.Track.EVENT: emit_signal("event_chunk_selected", chunk)
	emit_signal("chunk_selected", chunk)

func clear_highlights():
	if not tree or not tree.get_root(): return
	for item in tree.get_root().get_children():
		item.clear_custom_bg_color(0)

func highlight_chunk(chunk, color):
	if not chunk or not tree.get_root(): return
	var items = tree.get_root().get_children()
	for item in items:
		var item_chunk = item.get_meta('chunk')
		if item_chunk.index == chunk.index:
			item.set_custom_bg_color(0, color)
			tree.scroll_to_item(item)
			break
		item = item.get_next()
