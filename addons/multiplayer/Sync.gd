extends Node
class_name Sync

@export var initial: PackedStringArray = []
@export var synced: PackedStringArray = []
@export var unreliable_synced: PackedStringArray = []
@export var interpolated_synced: PackedStringArray = []

@export var process_only_network_master = false
@export var use_ids_for_spawning = true

var synced_last = {}
var unreliable_synced_last = {}
var interpolated_synced_last = {}
var interpolated_synced_target = {}
var is_synced_copy = false
var spawned_at_game_start = false

func _ready():
	var game = get_node("/root/NetworkGame")
	var node = get_parent()
	node.add_to_group("synced")
	
	# execute after the nodes we are syncing
	process_priority = 1000
	
	set_process(synced.size() > 0 or unreliable_synced.size() > 0 or interpolated_synced.size() > 0)
	
	if use_ids_for_spawning and not is_synced_copy and get_tree().get_multiplayer().has_multiplayer_peer():
		node.name += "_" + preload("uuid.gd").v4()
	if node.has_method("_network_ready"):
		node._network_ready(not is_synced_copy)
	
	for property in synced:
		_add_prop(node, synced_last, property)
	for property in unreliable_synced:
		_add_prop(node, unreliable_synced_last, property)
	for property in interpolated_synced:
		node.rset_config(property, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
		interpolated_synced_last[property] = null
	
	if get_tree().get_multiplayer().has_multiplayer_peer() and not is_synced_copy:
		game.server_spawn_object_on_clients(node)
	
	# wait until our parent is also ready, then configure its process
	await get_tree().process_frame
	if process_only_network_master:
		var is_master = node.is_multiplayer_authority()
		node.set_process(is_master)
		node.set_process_input(is_master)
		node.set_physics_process(is_master)

func _add_prop(node, array, property):
	node.rset_config(property, MultiplayerPeer.TRANSFER_MODE_RELIABLE)
	array[property] = null

func add_property(array_name, property):
	var last = null
	match array_name:
		'unreliable_synced':
			last = unreliable_synced_last
			var temp_array = Array(unreliable_synced)
			temp_array.append(property)
			unreliable_synced = PackedStringArray(temp_array)
		'synced':
			last = synced_last
			var temp_array = Array(synced)
			temp_array.append(property)
			synced = PackedStringArray(temp_array)
	_add_prop(get_parent(), last, property)
	set_process(true)

func remove():
	var node = get_parent()
	if node.is_multiplayer_authority():
		# we just queue free, next _exit_tree will handle syncing
		node.queue_free()

func _exit_tree():
	var node = get_parent()
	if node.is_multiplayer_authority():
		rpc("clients_remove")
		check_note_removal()

@rpc("any_peer") func clients_remove():
	check_note_removal()
	get_parent().queue_free()

func check_note_removal():
	if spawned_at_game_start:
		get_node("/root/NetworkGame").despawned_initial_paths.append(get_parent().get_path())

func _process(delta):
	var node = get_parent()
	if not node.is_multiplayer_authority():
		for property in interpolated_synced_target:
			get_parent().set(property,
				lerp(get_parent().get(property), interpolated_synced_target[property], delta * 10))
		return
	
	for property in synced:
		var value = node.get(property)
		if not synced_last.has(property) or value != synced_last[property]:
			node.rset(property, value)
			synced_last[property] = value
	
	for property in unreliable_synced:
		var value = node.get(property)
		if not unreliable_synced_last.has(property) or value != unreliable_synced_last[property]:
			node.rset(property, value, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)
			unreliable_synced_last[property] = value
	
	for property in interpolated_synced:
		var value = node.get(property)
		# if value != interpolated_synced_last[property]:
		#node.rset_unreliable(property, value)
		rpc("interp_set", property, value, MultiplayerPeer.TRANSFER_MODE_UNRELIABLE)
		interpolated_synced_last[property] = value

@rpc("any_peer") func interp_set(property, value):
	var n = get_parent()
	interpolated_synced_target[property] = value

func get_sync_state():
	var state = {}
	
	for property in initial:
		state[property] = get_parent().get(property)
	for property in synced:
		var value = get_parent().get(property)
		state[property] = value
		synced_last[property] = value
	for property in unreliable_synced:
		var value = get_parent().get(property)
		state[property] = value
		unreliable_synced_last[property] = value
	for property in interpolated_synced:
		var value = get_parent().get(property)
		state[property] = value
		interpolated_synced_last[property] = value
	
	if get_multiplayer_authority() > 0:
		state['__network_master_id'] = get_multiplayer_authority()
	return state
