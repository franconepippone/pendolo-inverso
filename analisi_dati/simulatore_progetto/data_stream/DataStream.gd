extends RefCounted
class_name DataStream

var datastream: Array[DataFrame] = []
var _last_idx: int = 0
var _last_timestamp: float = 0

# the datatype internally stored by the stream array
class DataFrame:
	var timestamp: float
	var payload: Variant
	
	func _init(timestamp: float, payload: Variant):
		self.timestamp = timestamp
		self.payload = payload


## register new payload for the given timestamp. Timestamp must be grater than the one of the last added object.
func put(timestamp: float, payload: Variant) -> bool:
	if datastream.size() > 0:
		if timestamp <= self.datastream[-1].timestamp:
			return false
		
	self.datastream.append(DataFrame.new(timestamp, payload))
	return true


## retrieves the frame stored at the given timestamp if timestamp is reachable, 
## otherwise clamps timestamp to maximum or minimum value of the stream.
## Optimized for consecutive calls with a growing timestamp
func get_at(timestamp: float) -> DataFrame:
	if datastream.size() == 0:
		return null
	# se torna indietro nel tempo, cerca dall'inizio
	if timestamp < _last_timestamp:
		_last_idx = 0
	
	_last_timestamp = timestamp
	
	for i in range(_last_idx, len(datastream)):
		#print(i)
		if datastream[i].timestamp >= timestamp:
			_last_idx = i 	# aggiorna _last_idx, per una ricerca più rapida
			return datastream[i]
	
	#print("NEXT")
	# se non lo trova da _last_idx alla fine, cerca dall'inizio fino a _last_idx
	for i in range(0, _last_idx):
		#print(i)
		if datastream[i].timestamp >= timestamp:
			_last_idx = i
			return datastream[i]
	
	#print("LAST")
	# se non lo trova neanche prima restituisce l'ultimo valore
	_last_idx = datastream.size() - 1
	return datastream[-1]

## returns timestamp of the last added element
func get_last_time() -> float:
	if datastream.size() == 0:
		return 0
	
	return datastream[-1].timestamp
	

## returns timestamp of the first added element
func get_first_time() -> float:
	if datastream.size() == 0:
		return 0
	
	return datastream[0].timestamp

func clear():
	self._last_idx = 0
	self._last_timestamp = 0
	self.datastream.clear()
