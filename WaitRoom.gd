extends Control

remote var start := false


func _ready():
	if !Globals.playerInfo[get_tree().get_network_unique_id()].host:
		$BtnStart.hide()


func _process(delta):
	$Label.text = (
		str(Globals.playerInfo) + '\n' +
		str(Globals.playerId) + '\n' +
		str(start)
	)
	
	if start:
		var game = preload("res://Game.tscn").instance()
		get_tree().get_root().add_child(game)
		queue_free()

remote func changeToGame():
	start = true

func _on_BtnStart_pressed():
	rpc_unreliable('changeToGame')
	start = true










