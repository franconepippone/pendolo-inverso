extends Node


var stream: DataStream = DataStream.new()

func _enter_tree() -> void:
	stream.put(0, "hello")
	stream.put(0.1, "there")
	stream.put(0.3, "my")
	stream.put(0.4, "name")
	stream.put(0.5, "is")
	stream.put(0.6, "john")
	stream.put(1, "fuck")
	stream.put(2, "me")
	
	print(stream.datastream)
	
	print(stream.get_at(0))
	print(stream.get_at(.01))
	print(stream.get_at(.01))
	print(stream.get_at(.1))
	print(stream.get_at(.15))
	print(stream.get_at(.31))
	print("_---------")
	print(stream.get_at(0))
	print(stream.get_at(0))
	print(stream.get_at(0.55))
	print(stream.get_at(0.01))
	print(stream.get_at(13))
	print(stream.get_at(13))
