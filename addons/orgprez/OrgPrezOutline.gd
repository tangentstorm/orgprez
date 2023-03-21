@tool
class_name OrgPrezOutline extends VBoxContainer

@onready var tree : Tree = $Tree

signal node_selected(org_node)
signal headline_changed()

func set_org(org:OrgNode):
	tree.clear()
	org.add_to_tree(tree, null)
	# extra line at the end so we can 'insert' before end
	var blank = tree.create_item(); blank.set_text(0, '')
	tree.set_selected(blank, 0)

func get_org_tree()->Tree:
	return tree

func _on_tree_item_selected():
	var org = get_org_tree().get_selected().get_metadata(0)
	emit_signal("node_selected", org)

func _on_tree_item_edited():
	var item = get_org_tree().get_selected()
	var node = item.get_metadata(0)
	node.head = item.get_text(0)
	emit_signal("headline_changed")

func get_current_org_node() -> OrgNode:
	if not get_org_tree(): return null
	if not get_org_tree().get_selected(): return null
	return get_org_tree().get_selected().get_metadata(0)
