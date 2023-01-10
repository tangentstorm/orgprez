@tool
class_name OrgPrezOutline extends VBoxContainer

@onready var tree : Tree = $Tree

signal node_selected(org_node)

func set_org(org:OrgNode):
	tree.clear()
	org.add_to_tree(tree, null)
	# extra line at the end so we can 'insert' before end
	var blank = tree.create_item(); blank.set_text(0, '')
	tree.set_selected(blank, true)

func get_org_tree()->Tree:
	return tree

func _on_Tree_item_selected():
	var org = get_org_tree().get_selected().get_metadata(0)
	emit_signal("node_selected", org)

func get_current_org_node() -> OrgNode:
	return get_org_tree().get_selected().get_metadata(0)
