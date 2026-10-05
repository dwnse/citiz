extends RefCounted
static func definition(w: Dictionary, kind: String) -> Dictionary:
	for item in w.get("buildingCatalog", []):
		if item.id == kind: return item
	return {"id":"wall","name":"Muro","cost":20,"width":3.2,"depth":1.2,"height":2.4}

static func half(w: Dictionary, b: Dictionary) -> Vector2:
	var d := definition(w,b.get("kind","wall"))
	return Vector2(d.depth,d.width)/2 if b.get("rot",0)==1 else Vector2(d.width,d.depth)/2

static func snap(w: Dictionary, point: Vector2, kind: String, rotated: bool) -> Vector2:
	var center := Vector2(w.vault.x,w.vault.y)
	var best := center+(point-center).snapped(Vector2(0.8,0.8))
	var distance := 1.25
	var h := half(w,{"kind":kind,"rot":1 if rotated else 0})
	for b in w.walls:
		if b.communityId != w.communityId: continue
		var bh := half(w,b)
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var candidate: Vector2 = Vector2(b.x,b.y)+direction*(h+bh)
			var d := point.distance_to(candidate)
			if d<distance:
				best=candidate
				distance=d
	return best.snapped(Vector2(0.2,0.2))

static func reason(w: Dictionary, p: Dictionary, point: Vector2, kind: String, rotated: bool) -> String:
	var d := definition(w,kind)
	if p.is_empty() or not p.get("alive",false): return "No puedes construir ahora"
	if not can_pay(p,d): return "Falta receta: "+recipe_text(d)+" · Recuperados sustituyen materiales"
	var v: Dictionary = w.vault
	var radius := 18+int(v.get("upgrades",0))*6
	var center := Vector2(v.x,v.y)
	if v.hp<=0: return "Bóveda destruida: no puedes construir en esta base"
	if point.distance_to(center)>=radius: return "Coloca DENTRO del borde AZUL · Radio %d m · U junto a la bóveda amplía" % radius
	if point.distance_to(center)<=4: return "El círculo ROJO protege la bóveda · Coloca fuera de ese círculo"
	if Vector2(p.x,p.y).distance_to(center)>radius+6: return "Acércate a tu base"
	if absf(point.x-50)<3 or (not w.get("legacy",false) and (absf(point.x-160)<3 or absf(point.y-105)<3)): return "Corredor público reservado"
	var h := half(w,{"kind":kind,"rot":1 if rotated else 0})
	if point.x-h.x<2 or point.y-h.y<2 or point.x+h.x>w.size-2 or point.y+h.y>w.size-2: return "Fuera del mapa"
	var story: Dictionary = w.get("story",{})
	if story.has("seal") and point.distance_to(Vector2(story.seal.x,story.seal.y))<7: return "Zona de historia reservada"
	var count := 0
	for b in w.walls:
		if b.communityId == p.communityId: count+=1
		var bh := half(w,b)
		if absf(b.x-point.x)<h.x+bh.x-0.001 and absf(b.y-point.y)<h.y+bh.y-0.001: return "Se solapa con otra estructura"
	if count>=80: return "Límite de estructuras"
	for o in w.get("obstacles",[]):
		if absf(o.x-point.x)<o.sx+h.x and absf(o.y-point.y)<o.sy+h.y: return "Obstáculo en el terreno"
	for r in w.get("resources",[]):
		if r.hits>0 and absf(r.x-point.x)<h.x+1 and absf(r.y-point.y)<h.y+1: return "Tala o extrae el recurso antes de construir aquí"
	for q in w.players+w.zombies:
		if q.get("alive",true) and absf(q.x-point.x)<h.x+0.65 and absf(q.y-point.y)<h.y+0.65: return "Hay alguien en el plano"
	return ""

static func valid(w: Dictionary, p: Dictionary, point: Vector2) -> bool:
	return reason(w,p,point,"wall",false).is_empty()

static func recipe_text(d: Dictionary) -> String:
	var names := {"timber":"madera","stone":"piedra","scrap":"chatarra"}
	var parts: PackedStringArray = []
	for key in d.get("recipe",{}): parts.append("%d %s" % [d.recipe[key],names.get(key,key)])
	return " + ".join(parts) if not parts.is_empty() else "%d materiales" % d.cost

static func can_pay(p: Dictionary,d: Dictionary) -> bool:
	if not p.has("materials") or not d.has("recipe"): return p.wood>=d.cost
	var reclaimed := int(p.materials.get("reclaimed",0))
	for key in d.recipe: reclaimed-=maxi(0,int(d.recipe[key])-int(p.materials.get(key,0)))
	return reclaimed>=0

static func pay_preview(p: Dictionary,d: Dictionary) -> void:
	if p.has("materials") and d.has("recipe"):
		for key in d.recipe:
			var n := mini(int(p.materials.get(key,0)),int(d.recipe[key]))
			p.materials[key]=int(p.materials.get(key,0))-n
			p.materials.reclaimed-=int(d.recipe[key])-n
	p.wood-=d.cost
