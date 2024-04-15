extends Node2D

@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/GridContainer/PortField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var sync_lost_label = $CanvasLayer/SyncLostLabel
@onready var server = $ServerPlayer
@onready var peer = $ClientPlayer

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SyncManager.sync_started.connect(_on_SyncManager_sync_stopped)
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)


func _on_server_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(int(port_field.text), 1)
	if error :
		print(error)
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Listening..."

func _on_client_button_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Connecting..."

func _on_player_connected(peer_id):
	message_label.text = "Connected!"
	print("connected")
	SyncManager.add_peer(peer_id)
	
	server.set_multiplayer_authority(1)
	if multiplayer.is_server():
		peer.set_multiplayer_authority(peer_id)
	else:
		peer.set_multiplayer_authority(multiplayer.multiplayer_peer.get_unique_id())
	
	if multiplayer.is_server():
		message_label.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(2).timeout
		SyncManager.start()

func _on_player_disconnected(peer_id):
	message_label.text = "Disconnected"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected() -> void:
	_on_player_disconnected(1)

func _on_ResetButton_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	get_tree().reload_current_scene()

func _on_SyncManager_sync_started() -> void:
	print("sync manager started")
	message_label.text = "Started!"

func _on_SyncManager_sync_stopped() -> void:
	pass

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	message_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = false
	
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()
