@tool
class_name OrgDeck extends Node

func add_child(node:Node, force_readable_name:bool=false, internal=0):
	super.add_child(node, force_readable_name, internal)
	observe(node)
	show_only(node)

func _ready():
	for child in get_children():
		observe(child)

func observe(node):
	node.connect("visibility_changed",Callable(self,"on_child_visibility_changed").bind(node))

# TODO: if the visible slide is removed, 
#       and there is another slide, show one.
#func remove_child(node:Node):
#	if node.visible
#	super.remove_child(node)

func on_child_visibility_changed(child):
	if child.visible:
		show_only(child)
	
func show_only(node:Node):
	for child in self.get_children():
		if node != child:
			child.visible = false
	if not node.visible:
		node.visible = true

func hide_all():
	for child in self.get_children(): child.visible = false

func show_slide(name:String):
	if name == '': hide_all()
	else:
		var slide = get_node_or_null(name)
		if slide: show_only(slide)
		else:
			hide_all()
			printerr("no such slide found:", name)
