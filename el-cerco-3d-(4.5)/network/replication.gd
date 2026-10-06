extends RefCounted

static func apply(previous: Dictionary, sequence: int, frame: Dictionary) -> Dictionary:
	if frame.get("wire",0)!=1: return {"error":"Formato de estado desconocido"}
	if frame.get("state") is Dictionary: return {"state":frame.state,"sequence":int(frame.seq)}
	if previous.is_empty() or int(frame.get("base",-1))!=sequence or int(frame.get("seq",-1))!=sequence+1:
		return {"error":"Falta una actualización del mundo"}
	var state := previous.duplicate()
	for key in frame.get("remove",[]): state.erase(key)
	state.merge(frame.get("set",{}),true)
	for key in frame.get("objects",{}):
		var patch: Dictionary = frame.objects[key]
		var value: Dictionary = state.get(key,{}).duplicate()
		for field in patch.get("remove",[]): value.erase(field)
		value.merge(patch.get("set",{}),true)
		state[key]=value
	for key in frame.get("entities",{}):
		var patch: Dictionary = frame.entities[key]
		var rows := {}
		for item in state.get(key,[]): rows[str(item.id)]=item
		for id in patch.get("remove",[]): rows.erase(str(id))
		for change in patch.get("upsert",[]):
			var id: String = str(change.id)
			var item: Dictionary = rows.get(id,{"id":id}).duplicate()
			for field in change.get("remove",[]): item.erase(field)
			item.merge(change.get("set",{}),true)
			rows[id]=item
		var items := []
		for id in patch.get("order",rows.keys()):
			if not rows.has(str(id)): return {"error":"Colección de entidades incompleta"}
			items.append(rows[str(id)])
		state[key]=items
	return {"state":state,"sequence":int(frame.seq)}
