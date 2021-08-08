extends Spatial


func _ready():
	var playerInstance = preload("res://Player.tscn")
	for i in len(Globals.playerId):
		var id = Globals.playerId[i]
		var _p = playerInstance.instance()
		_p.set_name(str(id))
		_p.set_network_master(id)
		_p.global_transform.origin = get_node("PlayersPositions/Pos" + str(i + 1)).global_transform.origin
		add_child(_p)





