extends Node3D

# UI ELEMENTS
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var hostB: Button = $CanvasLayer/Host
@onready var joinB: Button = $CanvasLayer/Join
@onready var id_prompt: LineEdit = $CanvasLayer/id_Prompt
@onready var id_label: Label = $InGameCanvas/id_label
var lobby_id: int = 0

var peer: SteamMultiplayerPeer
@export var player_scene: PackedScene
var is_host: bool = false
var is_joining: bool = false

func _ready() -> void:
	#hostB.disabled = true
	#joinB.disabled = true

	var init_result = Steam.steamInit(480, true)
	print("Init result: ", init_result)
	print("Steam running: ", Steam.isSteamRunning())
	print("Steam ID: ", Steam.getSteamID())

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.relay_network_status.connect(_on_relay_network_status)
	Steam.initRelayNetworkAccess()

	hostB.pressed.connect(_on_host_pressed)
	joinB.pressed.connect(_on_join_pressed)
	id_prompt.text_changed.connect(_on_id_prompt_text_changed)

func _process(_delta: float) -> void:
	Steam.run_callbacks()

func _on_relay_network_status(available: int, _type: int, _old_state: int, _relay_error: int, _ping: String):
	print("Relay status: ", available)
	if available == 1:
		hostB.disabled = false
		joinB.disabled = false

func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	is_host = true
	canvas_layer.hide()

func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		if not multiplayer.peer_connected.is_connected(_add_player):
			multiplayer.peer_connected.connect(_add_player)
			multiplayer.peer_disconnected.connect(_remove_player)
		_add_player(multiplayer.get_unique_id())
		print("lobby_id: ", lobby_id)
		id_label.text = "ID: " + str(lobby_id)

func join_lobby(lobby_id: int):
	is_joining = true
	Steam.joinLobby(lobby_id)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int):
	if !is_joining:
		return
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_add_player):
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
	id_label.text = "ID: " + str(lobby_id)
	print("lobby_entered: ", lobby_id)
	is_joining = false

func _add_player(id: int = 1):
	print("Adding player with id: ", id, " my id is: ", multiplayer.get_unique_id())
	if has_node(str(id)):
		return
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = Vector3(0, 1, 0)
	call_deferred("add_child", player)

func _remove_player(id: int):
	if !self.has_node(str(id)):
		return
	self.get_node(str(id)).queue_free()

func _on_host_pressed():
	host_lobby()

func _on_join_pressed():
	join_lobby(id_prompt.text.to_int())

func _on_id_prompt_text_changed(new_text):
	joinB.disabled = (new_text.length() == 0)
