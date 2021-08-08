extends Control

var sceneChanged := false
var mySeed = randomize()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	$Btns/Name.text = "player" + str(int(rand_range(100, 999)))


remote func setName(id: int, name: String):
	Globals.playerInfo[id] = {
		'name': name,
		'host': id == 1 || id == 0,
	}


func changeScene():
	rpc_unreliable('setName', get_tree().get_network_unique_id(), $Btns/Name.text)
	setName(get_tree().get_network_unique_id(), $Btns/Name.text)
	if !sceneChanged:
		sceneChanged = true
		var game = preload("res://WaitRoom.tscn").instance()
		get_tree().get_root().add_child(game)
		hide()


func getTypedPort():
	if $Btns/Port.text.length() >= 4:
		return $Btns/Port.text
	return "6969"


#func _gui_input(event):
#	$Label.text = str(event.accumulate())


### === SIGNALS === ###
func _on_Host_pressed():
	var net = NetworkedMultiplayerENet.new()
	net.create_server(int(getTypedPort()), 8)
	get_tree().set_network_peer(net)
	Globals.playerId += [get_tree().get_network_unique_id()]
	print("hosting on: " + getTypedPort())
	changeScene()

func _on_Join_pressed():
	var net = NetworkedMultiplayerENet.new()
	net.create_client($Btns/IP.text, int(getTypedPort()))
	get_tree().set_network_peer(net)
	Globals.playerId += [get_tree().get_network_unique_id()]

func _player_connected(id):
	Globals.playerId += [id]
	changeScene()

func _on_Sensitivity_value_changed(value):
	Globals.game.sensitivity = value








