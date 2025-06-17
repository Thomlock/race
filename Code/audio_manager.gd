extends Node

var num_players = 64
var bus = "master"

var available3D = []  # The available players.
var queue : Array[AudioStream] = []  # The queue of sounds to play.
var queue_volumes = []	# volumes of streams to play
var queue_nodes = [] # nodes asking for the streams to play

func _ready():
	# Create the pool of AudioStreamPlayer nodes.
	for i in num_players:
		var player = AudioStreamPlayer3D.new()
		add_child(player)
		available3D.append(player)
		player.finished.connect(_on_stream_finished.bind(player))
		player.bus = bus
		player.max_polyphony = 64


func _on_stream_finished(stream):
	# When finished playing a stream, make the player available again.
	available3D.append(stream)


func play3D(sound_stream : AudioStream, node: Node3D, volume : float = 0):
	queue.append(sound_stream)
	#print(sound_stream)
	queue_nodes.append(node)
	#print(node)
	#print(node.position)
	queue_volumes.append(volume)
	#print(volume)



func _process(delta):
	# Play a queued sound if any players are available.
	if not queue.is_empty() and not available3D.is_empty():
		var player : AudioStreamPlayer3D = available3D.pop_front()
		player.stream = queue.pop_front()
		player.volume_db = queue_volumes.pop_front()
		var node = queue_nodes.pop_front()
		player.position = node.position
		if(node.has_method("_on_audio_stream_player_finished")):
			player.finished.connect(node._on_audio_stream_player_finished.bind(player.stream))
		player.play()
		
