extends Node2D
class_name PoolManager

## Generic object pooling for performance optimization on mobile.

var _pools: Dictionary = {}

func get_node_from_pool(scene: PackedScene) -> Node:
	var path = scene.resource_path
	if not _pools.has(path):
		_pools[path] = []
	
	var pool = _pools[path]
	if pool.size() > 0:
		var node = pool.pop_back()
		if is_instance_valid(node):
			node.visible = true
			node.set_process(true)
			node.set_physics_process(true)
			if node.has_method("reset_pool_state"):
				node.reset_pool_state()
			return node
	
	var node = scene.instantiate()
	if not node.has_signal("tree_exiting"):
		# Ensure we don't leak if the node is freed normally
		node.tree_exiting.connect(func(): _on_node_exiting(path, node))
	return node

func return_to_pool(node: Node, scene_path: String):
	if not is_instance_valid(node): return
	
	# Immediately disable processing and visibility
	node.visible = false
	node.set_process(false)
	node.set_physics_process(false)
	
	# Safely disable monitoring if it's an Area2D
	if node.has_method("set_deferred"):
		node.set_deferred("monitoring", false)
		node.set_deferred("monitorable", false)
	
	# Defer the tree manipulation to avoid "flushing queries" error
	_do_return_to_pool.call_deferred(node, scene_path)

func _do_return_to_pool(node: Node, scene_path: String):
	if not is_instance_valid(node): return
	
	# Reparent to pool manager to keep scene tree clean
	if node.get_parent():
		node.get_parent().remove_child(node)
	
	if not node.is_inside_tree():
		add_child(node)
	
	if not _pools.has(scene_path):
		_pools[scene_path] = []
	
	# Ensure we don't add the same node twice
	if not node in _pools[scene_path]:
		_pools[scene_path].append(node)

func _on_node_exiting(path: String, node: Node):
	if _pools.has(path):
		_pools[path].erase(node)
