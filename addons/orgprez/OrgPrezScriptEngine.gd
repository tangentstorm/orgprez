class_name OrgPrezScriptEngine extends Node
# simple interpreter for the '@event(x,y,z) lines in presentations.
# these lines trigger the corresponding cmd_event(x,y,z) methods checked this node.
# the methods return true if they trigger an animation,
# or false if they finish immediately
# ether way, they trigger the script_finished signal when done.

signal script_finished(id, result)
signal macro_finished(id, result)

var script_id:int
var script_result
var timer:Timer
var user_scene:Node : set = set_user_scene
var scene_title:Node
var commander:Node

func set_user_scene(node):
	user_scene = node
	if node:
		commander = user_scene.get_node_or_null('OrgCommands')
		if not commander: commander = node
		scene_title = user_scene.find_child("OrgSceneTitle")
		if scene_title:
			scene_title.connect("animation_finished",Callable(self,"_on_animation_finished"))
	else:
		commander = null
		scene_title = null

func _ready():
	timer = Timer.new(); add_child(timer)
	timer.connect("timeout",Callable(self,"_on_timer_timeout"))

func make_tween()->Tween:
	var tween = get_tree().get_root().create_tween()
	tween.connect("step_finished",Callable(self,"_on_tween_step"))
	tween.connect("finished",Callable(self,"_on_tween_finished"))
	return tween

func _on_animation_finished():
	emit_signal("script_finished", script_id, script_result)

func _on_timer_timeout():
	_on_animation_finished()

func _on_tween_finished():
	_on_animation_finished()

func _on_tween_step(ix:int):
	pass #print("step_finished", ix)

func execute(id:int, script:String):
	script_id = id
	script_result = null
	var e = Expression.new()
	assert(script.begins_with('@')) #,'event lines must start with "@"')
	script = 'cmd_' + script.right(-1)
	# TODO: check that there's actually a '('
	var meth = script.split('(')[0]
	if OK == e.parse(script):
		var target = self
		if commander and commander.has_method(meth): target = commander
		var animated = e.execute([], target)
		if not animated: call_deferred("_on_animation_finished")
	else: printerr("OrgPrezScriptEngine parse error: ", script)

func run_macro(id:int, macro:String):
	var res = null
	if commander and commander.has_method('run_macro'):
		# !! make sure you also emit a "macro_finished" signal
		res = commander.run_macro(macro)
	else:
		print("ignoring macro:", macro)
		emit_signal("macro_finished", id, res)

### helper methods ###########################################


func _tween(node:Node, prop:String, a, z, ms)->bool:
	if not node: return IMMEDIATE
	if ms==0: node.set(prop, z)
	else:
		print("tweening ", prop, ' ms:', ms)
		node.set(prop, a)
		make_tween().set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_LINEAR)\
			.tween_property(node, prop, z, ms*0.001)
	return ANIMATED if ms > 0 else IMMEDIATE

func _find(node_path, cmd):
	var node = user_scene.get_node_or_null(node_path)
	if node == null: printerr('not found: @%s("%s"):' % [cmd, node_path])
	return node

### commands #################################################

const ANIMATED = true
const IMMEDIATE = false
const SHOW = Color(1,1,1,1)
const HIDE = Color.TRANSPARENT

func cmd_move(node_path:String, x, y, ms=0)->bool:
	var node = _find(node_path, 'move')
	if node == null: return IMMEDIATE
	var prop = 'position' if node is Control else 'position'
	var xy0 = node.get(prop)
	var xy1 = Vector2(x, y)
	return _tween(node, prop, xy0, xy1, ms)

func cmd_show(node_path:String, ms=0)->bool:
	var node = _find(node_path, 'show')
	return _tween(node, 'modulate', HIDE, SHOW, ms)

func cmd_hide(node_path:String, ms=0)->bool:
	var node = _find(node_path, 'hide')
	return _tween(node, 'modulate', SHOW, HIDE, ms)

func cmd_title(text:String)->bool:
	if scene_title == null: return false
	scene_title.reveal(text)
	return ANIMATED

func cmd_pause(ms=0):
	timer.wait_time = ms * 0.001
	timer.one_shot = true
	timer.start()
	return ANIMATED
