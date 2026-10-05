extends Node3D
const Art = preload("res://world/art.gd")
const Shapes = preload("res://world/shapes.gd")
const Expedition = preload("res://world/expedition.gd")
const BuildingView = preload("res://building/view.gd")
const Placement = preload("res://building/placement.gd")
const PlayerScene = preload("res://player/player.tscn")
const ZombieScene = preload("res://zombies/zombie.tscn")
const Settings = preload("res://combat/presentation.tres")
const ShotAudio = preload("res://combat/audio.gd")
@onready var network = $Network
@onready var camera = $Camera
@onready var hud = $HUD
var state: Dictionary = {}
var me: Dictionary = {}
var actors: Dictionary = {}
var structures: Dictionary = {}
var terrain := Node3D.new()
var props := Node3D.new()
var trails := Node3D.new()
var preview: MeshInstance3D
var world_key := ""
var building := false
var selected_kind := "wall"
var build_offset := Vector3.ZERO
var grid_view: MeshInstance3D
var grid_radius := 0.0
var structure_versions: Dictionary = {}
var rotated := false
var input_timer := 0.0
var shot_timer := 0.0
var selected_world := ""
var selected_community := "forest"
var selected_name := "Agente Godot"
var shot_audio: AudioStreamPlayer
var previous_ammo := -1
var previous_weapon := "pistol"
var selected_structure := ""
var row_dragging := false
var row_start := Vector2.ZERO
var row_ghosts := Node3D.new()
var persistent_props := Node3D.new()
var prop_nodes: Dictionary = {}
var row_signature := ""
var performance_timer := 0.0
var center_on_entry := true
var survival_zoom := 32.0
var sprint_sent := false

func _ready() -> void:
	add_child(terrain)
	add_child(props)
	add_child(trails)
	add_child(row_ghosts)
	add_child(persistent_props)
	shot_audio = ShotAudio.new()
	add_child(shot_audio)
	preview = Shapes.box(self, Settings.wall_size, Vector3.ZERO, Color(0.4, 1, 0.6, 0.45))
	preview.visible = false
	# Preview floor is replaced by the real world's geometry on first snapshot.
	Shapes.box(terrain, Vector3(220, 0.4, 220), Vector3(110, -0.2, 110), Color("263e38"), true)
	for binding in [["left", KEY_A], ["right", KEY_D], ["forward", KEY_W], ["back", KEY_S]]:
		InputMap.add_action(binding[0])
		var event := InputEventKey.new()
		event.physical_keycode = binding[1]
		InputMap.action_add_event(binding[0], event)
	network.snapshot_received.connect(receive_state)
	network.status_changed.connect(func(message): hud.status.text = message)
	network.action_feedback.connect(hud.notify_action)
	hud.population_panel.command.connect(func(action,id):
		if network.connected and me.get("alive",false): network.act(action,{"id":id})
	)
	hud.cosmetic_requested.connect(func(style):
		if network.connected: network.act("cosmetic",{"style":style})
	)
	hud.pause_requested.connect(func(): network.act("pause"))
	hud.weapon_requested.connect(func(kind):
		if network.connected and me.get("alive",false) and not state.get("adventure",{}).get("paused",false): network.act("weapon",{"weapon":kind})
	)
	hud.build_requested.connect(func(): set_build_mode(not building))
	hud.equip_requested.connect(toggle_equipment)
	hud.find_plot_requested.connect(find_plot)
	hud.rebuild_requested.connect(func():
		if playable(): network.act("rebuild_vault")
	)
	network.directory_received.connect(hud.set_worlds)
	hud.refresh_requested.connect(network.refresh_worlds)
	hud.create_requested.connect(network.create_world)
	hud.enter_requested.connect(enter)
	hud.structure_chosen.connect(func(kind): selected_kind=kind; set_build_mode(true))
	hud.management_action.connect(func(action):
		if playable() and not selected_structure.is_empty(): network.act(action,{"id":selected_structure})
	)
	hud.leave_requested.connect(leave)
	hud.reconnect_requested.connect(func():
		if not selected_world.is_empty():
			enter(selected_world, selected_community, selected_name)
	)
	hud.settings.shadows_changed.connect(func(enabled): $Moon.shadow_enabled=enabled)
	$Moon.shadow_enabled=hud.settings.shadows.button_pressed
	network.refresh_worlds()

func enter(world: String, community: String, agent_name: String) -> void:
	center_on_entry=true
	selected_world = world
	selected_community = community
	selected_name = agent_name
	set_build_mode(false)
	previous_ammo = -1
	await network.enter(world, community, agent_name)

func leave() -> void:
	network.disconnect_world()
	me = {}
	set_build_mode(false)
	hud.journal.hide()
	hud.population_panel.hide()
	hud.settings.hide()
	hud.lobby.show()
	hud.status.text = "Desconectado. La plaza y el inventario se conservan."
	network.refresh_worlds()

func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func receive_state(value: Dictionary) -> void:
	state = value
	me = {}
	for player in state.players:
		if player.id == network.player_id:
			me = player
	if me.is_empty():
		return
	if state.get("phase","")!="active" or (not me.get("alive",false) and state.vault.hp<=0):
		var victory: bool = state.get("phase","")=="victory"
		leave()
		if victory:
			hud.status.text="CURA SINTETIZADA · Comunidad vencedora: "+str(state.get("winner",""))
			hud.notify_action("El Cerco ha terminado. Título: Custodio del Sello. Consulta las monedas de tu cuenta en el diario de otra partida.",true)
			return
		hud.status.text="Partida terminada: tu agente no puede reaparecer. Elige una partida activa o pulsa Nueva partida."
		hud.notify_action("Tu bóveda fue destruida. Elige una partida activa o crea una nueva para jugar.",false)
		return
	if center_on_entry:
		center_on_entry=false
		build_offset=Vector3.ZERO
		camera.focus=Vector3(me.x,0,me.y)
		camera.position=camera.focus+camera.offset
	if previous_ammo >= 0 and int(me.ammo) < previous_ammo and me.get("weapon","pistol")==previous_weapon:
		shot_audio.play()
	previous_ammo = int(me.ammo)
	previous_weapon=str(me.get("weapon","pistol"))
	if not me.get("alive",false) and building: set_build_mode(false)
	if world_key != state.id:
		world_key = state.id
		for actor in actors.values():
			actor.queue_free()
		actors.clear()
		for structure in structures.values():
			structure.queue_free()
		structures.clear()
		structure_versions.clear()
		clear_children(persistent_props)
		prop_nodes.clear()
		grid_radius=0
		make_terrain()
		camera.focus = Vector3(me.x, 0, me.y)
		camera.position = camera.focus + camera.offset
	var radius := 18.0+float(state.vault.get("upgrades",0))*6
	if radius!=grid_radius:
		if is_instance_valid(grid_view): grid_view.queue_free()
		grid_radius=radius
		grid_view=BuildingView.grid(self,Vector3(state.vault.x,0,state.vault.y),radius)
		grid_view.visible=building
	$Moon.light_energy=0.48 if state.get("adventure",{}).get("night",false) else 1.05
	$Moon.light_color=Color("8ea9d1") if state.get("adventure",{}).get("night",false) else Color("ffdea8")
	sync_actors()
	sync_structures()
	sync_props()
	hud.show_state(state, me, building)
	var inspected: Dictionary = {}
	for b in state.walls:
		if b.id==selected_structure: inspected=b
	hud.inspect_structure(state,me,inspected)

func make_terrain() -> void:
	clear_children(terrain)
	var size := float(state.size)
	Art.landscape(terrain, state)
	for obstacle in state.get("obstacles", []):
		Art.obstacle(terrain, obstacle)
	for edge in [Vector3(0.8, 2, size/2), Vector3(size-0.8, 2, size/2)]:
		Shapes.box(terrain, Vector3(2.4, 4, size), edge, Color("3e4b50"), true)
	for edge in [Vector3(size/2, 2, 0.8), Vector3(size/2, 2, size-0.8)]:
		Shapes.box(terrain, Vector3(size, 4, 2.4), edge, Color("3e4b50"), true)
	Art.batch_static(terrain)

func sync_actors() -> void:
	var keep := {}
	for kind in ["players", "zombies", "workers"]:
		for entity in state.get(kind,[]):
			var key: String = kind + str(entity.id)
			keep[key] = true
			if not actors.has(key):
				var actor = ZombieScene.instantiate() if kind == "zombies" else PlayerScene.instantiate()
				actor.worker=kind=="workers"
				add_child(actor)
				actors[key] = actor
			actors[key].update_state(entity)
			if kind=="workers": actors[key].caption.visible=Vector2(entity.x-me.x,entity.y-me.y).length()<8
	for key in actors.keys():
		if not keep.has(key):
			actors[key].queue_free()
			actors.erase(key)

func sync_structures() -> void:
	var keep := {}
	for wall in state.walls:
		var key: String = wall.id
		keep[key] = true
		var signature := str(wall.get("kind","wall"))+str(wall.get("open",false))
		if structures.has(key) and structure_versions.get(key,"")!=signature:
			structures[key].queue_free()
			structures.erase(key)
		if not structures.has(key):
			structures[key]=BuildingView.create(self,state,wall)
			structure_versions[key]=signature
		if wall.get("kind","")=="turret" and structures[key].has_node("TurretHead"):
			structures[key].get_node("TurretHead").rotation.y=-float(wall.get("aim",0))
	for c in state.communities:
		var key: String = "vault-" + str(c.id)
		keep[key] = true
		if not structures.has(key):
			var base := Node3D.new()
			base.position = Vector3(c.x, 0, c.y)
			add_child(base)
			Art.vault(base)
			structures[key] = base
		structures[key].scale.y = 1 if c.vault.hp > 0 else 0.2
	for key in structures.keys():
		if not keep.has(key):
			structures[key].queue_free()
			structures.erase(key)

func sync_props() -> void:
	clear_children(props)
	clear_children(trails)
	var keep := {}
	for resource in state.get("resources",[]):
		if Vector2(resource.x-me.x,resource.y-me.y).length()>48: continue
		var key: String = "resource-"+str(resource.id)
		keep[key]=true
		if not prop_nodes.has(key):
			var root := Node3D.new()
			persistent_props.add_child(root)
			root.position=Vector3(resource.x,0,resource.y)
			var shape := Node3D.new()
			shape.name="Shape"
			root.add_child(shape)
			if resource.kind=="tree":
				var rng := RandomNumberGenerator.new()
				rng.seed=hash(resource.id)
				Art.tree(shape,Vector3.ZERO,rng)
			else: Art.stone(shape,Vector3(0,0.6,0),Vector3(1.6,1.2,1.6),Color("a2aaa9"))
			Art.batch_static(shape)
			var caption := Shapes.label(root,"",5 if resource.kind=="tree" else 2)
			caption.name="ResourceLabel"
			caption.font_size=25
			prop_nodes[key]=root
		var node: Node3D = prop_nodes[key]
		node.get_node("Shape").scale=Vector3.ONE if resource.hits>0 else Vector3(1,0.12,1)
		var label: Label3D = node.get_node("ResourceLabel")
		label.visible=Vector2(resource.x-me.x,resource.y-me.y).length()<18
		label.text=("ÁRBOL · Q y clic" if resource.kind=="tree" else "PIEDRA · Q y clic")+" · %d/5" % resource.hits if resource.hits>0 else "AGOTADO"
	for site in state.get("adventure",{}).get("sites",[]):
		if Vector2(site.x-me.x,site.y-me.y).length()>48: continue
		var key: String = "site-"+str(site.id)
		keep[key]=true
		if not prop_nodes.has(key):
			var root := Node3D.new()
			persistent_props.add_child(root)
			root.position=Vector3(site.x,0,site.y)
			Expedition.create(root,site)
			prop_nodes[key]=root
		var incident: Dictionary = state.get("adventure",{}).get("incident",{}) if state.get("adventure",{}).get("incident") is Dictionary else {}
		var label: Label3D = prop_nodes[key].get_node("SiteLabel")
		var remaining := maxi(0,int(ceil((float(site.get("readyAt",0))-Time.get_unix_time_from_system()*1000)/1000)))
		label.text=str(site.name)+(" · E" if remaining==0 else " · %d s" % remaining)
		if incident.get("siteId","")==site.id:
			label.text=str(incident.title)+" · E · %d s" % maxi(0,int(incident.endsAt-state.adventure.elapsed))
			label.modulate=Color("ffca71")
		else: label.modulate=Color.WHITE
	for passage in state.get("adventure",{}).get("passages",[]):
		if Vector2(passage.x-me.x,passage.y-me.y).length()>48: continue
		var key: String = "passage-"+str(passage.id)
		keep[key]=true
		if not prop_nodes.has(key):
			var root := Node3D.new()
			persistent_props.add_child(root)
			root.position=Vector3(passage.x,0,passage.y)
			Shapes.cylinder(root,1.8,0.12,Vector3(0,0.07,0),Color("606a6e"))
			Shapes.cylinder(root,1.35,0.14,Vector3(0,0.08,0),Color("171e28"))
			for i in range(5): Shapes.box(root,Vector3(0.9,0.08,0.16),Vector3(0,0.2,-0.9+i*0.4),Color("a78b62"))
			Art.batch_static(root,true)
			var label := Shapes.label(root,str(passage.name)+" · E · 25 resistencia",2.8,Color("c5a9eb"))
			label.font_size=22
			prop_nodes[key]=root
	for drop in state.drops:
		var key: String = "drop-"+str(drop.id)
		keep[key]=true
		if not prop_nodes.has(key):
			var root := Node3D.new()
			persistent_props.add_child(root)
			root.position=Vector3(drop.x,0,drop.y)
			Art.crate(root,Vector3.ZERO)
			var caption := Shapes.label(root,"E · SUMINISTROS",1.3,Color("e9d39c"))
			caption.font_size=20
			prop_nodes[key]=root
	var story: Dictionary = state.get("story", {})
	if story.has("radio"):
		keep["radio"]=true
		if not prop_nodes.has("radio"):
			var root := Node3D.new()
			persistent_props.add_child(root)
			Art.wreck(root,Vector3(story.radio.x,0,story.radio.y))
			prop_nodes["radio"]=root
	for mage in story.get("mages", []):
		var key: String = "mage-"+str(mage.name)
		keep[key]=true
		if not prop_nodes.has(key):
			var root := Node3D.new()
			persistent_props.add_child(root)
			Shapes.cylinder(root,0.65,1.6,Vector3(0,0.8,0),Color("8b72ba"))
			Shapes.box(root,Vector3(0.6,0.6,0.6),Vector3(0,1.9,0),Color("ddc8af"))
			Shapes.label(root,mage.name+" · E",2.8)
			prop_nodes[key]=root
		var actor: Node3D = prop_nodes[key]
		actor.position = Vector3(mage.x, 0, mage.y)
	for key in prop_nodes.keys():
		if not keep.has(key):
			prop_nodes[key].queue_free()
			prop_nodes.erase(key)
	if me.get("intro", false) and story.has("seal"):
		Shapes.cylinder(props, 2.8, 0.3, Vector3(story.seal.x, 0.15, story.seal.y), Color("8f75bc"))
	for shot in state.shots:
		var length := float(shot.length)
		var trail := Shapes.box(trails, Vector3(length, Settings.trail_width, Settings.trail_width), Vector3(shot.x+cos(shot.angle)*length/2, 1.35, shot.y+sin(shot.angle)*length/2), Settings.muzzle_color)
		trail.rotation.y = -shot.angle
	for z in state.zombies:
		if z.get("warning", 0) > 0:
			Shapes.cylinder(props, 7 if z.get("finalBoss",false) else float(z.get("abilityRadius",6)), 0.05, Vector3(z.x, 0.07, z.y), Color(Color(str(z.get("abilityTint","#ec7769"))),0.28))
		if z.get("charmUntil", 0) > Time.get_unix_time_from_system() * 1000:
			Shapes.cylinder(props, 1, 0.07, Vector3(z.x, 0.09, z.y), Color(0.6, 0.3, 1, 0.6))
	for p in state.players:
		var effects: Dictionary = p.get("magic", {}).get("effects", {})
		if p.alive and effects.get("shield", 0) > Time.get_unix_time_from_system() * 1000:
			Shapes.cylinder(props, 1.05, 2.7, Vector3(p.x, 1.35, p.y), Color(0.3, 0.8, 1, 0.18))
	for effect in state.get("effects", []):
		var tint := Color(0.7, 0.45, 1, 0.35)
		if effect.power == "heal":
			tint = Color(0.4, 1, 0.5, 0.35)
		var radius := 0.5 + (0.7-float(effect.life)) * 4
		Shapes.cylinder(props, radius, 0.1, Vector3(effect.x, 0.12, effect.y), tint)

func playable() -> bool:
	return network.connected and not me.is_empty() and not hud.lobby.visible and not hud.journal.visible and not hud.settings.visible and not hud.population_panel.visible and me.get("alive", false) and state.get("phase", "") == "active" and not state.get("adventure",{}).get("paused",false)

func _process(delta: float) -> void:
	performance_timer+=delta
	if performance_timer>=0.5:
		performance_timer=0
		hud.performance.text="%d FPS" % Engine.get_frames_per_second()
	input_timer -= delta
	shot_timer -= delta
	if not me.is_empty():
		camera.focus = Vector3(me.x, 0, me.y)+build_offset
	preview.visible = building and playable()
	row_ghosts.visible = building and playable()
	if not playable():
		row_dragging=false
		shot_timer=maxf(shot_timer,0.15)
	if not network.connected or me.is_empty():
		return
	var aim: Vector3 = camera.ground_point()
	var angle := atan2(aim.z-float(me.y), aim.x-float(me.x))
	if building and playable():
		var pan := Input.get_vector("left","right","forward","back")
		build_offset += Vector3(pan.x,0,pan.y).rotated(Vector3.UP,atan2(camera.offset.x,camera.offset.z))*delta*18
		build_offset=build_offset.limit_length(grid_radius+8)
	if input_timer <= 0:
		input_timer = Settings.input_interval
		var direction := Input.get_vector("left", "right", "forward", "back") if playable() and not building else Vector2.ZERO
		var world_direction := Vector3(direction.x, 0, direction.y).rotated(Vector3.UP, atan2(camera.offset.x, camera.offset.z))
		network.send_input(Vector2(world_direction.x, world_direction.z), angle)
		var sprinting := playable() and not building and Input.is_physical_key_pressed(KEY_SHIFT) and direction.length()>0
		if sprinting!=sprint_sent:
			sprint_sent=sprinting
			network.act("sprint",{"enabled":sprinting})
	if not playable():
		return
	var grid := Placement.snap(state,Vector2(aim.x,aim.z),selected_kind,rotated)
	if building:
		var d := Placement.definition(state,selected_kind)
		preview.mesh.size=Vector3(d.width,d.height,d.depth)
		preview.position = Vector3(grid.x, d.height/2, grid.y)
		preview.rotation.y = PI/2 if rotated else 0
		var reason := Placement.reason(state,me,grid,selected_kind,rotated)
		preview.material_override.albedo_color = Color(0.3,1,0.5,0.5) if reason.is_empty() else Color(1,0.2,0.2,0.5)
		hud.build_hint.text="%s · %d materiales\n%s\n%s" % [d.name,d.cost,Placement.recipe_text(d)+" · "+d.get("description",""),"Clic: colocar · Encaje automático · G: girar" if reason.is_empty() else reason]
		if not row_dragging and row_ghosts.get_child_count()>0: clear_children(row_ghosts)
		if row_dragging:
			preview.visible=false
			var end := Vector2(aim.x,aim.z)
			var difference := end-row_start
			var vertical := absf(difference.y)>absf(difference.x)
			var length_axis := difference.y if vertical else difference.x
			var count := mini(20,1+int(floor(absf(length_axis)/3.2+0.5)))
			var shadow: Dictionary = state.duplicate(true)
			var payer: Dictionary = me.duplicate(true)
			var points: Array[Vector2] = []
			var row_reason := ""
			for i in range(count):
				var point := row_start+(Vector2.DOWN if vertical else Vector2.RIGHT)*i*3.2*(1 if length_axis>=0 else -1)
				points.append(point)
				var problem := Placement.reason(shadow,payer,point,selected_kind,vertical)
				if not problem.is_empty() and row_reason.is_empty(): row_reason=problem
				shadow.walls.append({"x":point.x,"y":point.y,"kind":selected_kind,"rot":1 if vertical else 0,"communityId":me.communityId})
				Placement.pay_preview(payer,d)
			if absf(length_axis)/3.2>=19.5: row_reason="Máximo 20 piezas por fila"
			var signature := str(points)+selected_kind+str(vertical)+row_reason
			if row_signature!=signature or row_ghosts.get_child_count()==0:
				row_signature=signature
				clear_children(row_ghosts)
				for point in points:
					var ghost := Shapes.box(row_ghosts,Vector3(d.width,d.height,d.depth),Vector3(point.x,d.height/2,point.y),Color(0.3,1,0.5,0.4) if row_reason.is_empty() else Color(1,0.2,0.2,0.4))
					ghost.rotation.y=PI/2 if vertical else 0
			hud.build_hint.text="Fila: %d piezas · %d materiales\nSoltar: construir · Clic derecho: cancelar\n%s" % [count,count*d.cost,row_reason]
		else:
			hud.build_hint.text+="\nMayús + arrastrar: fila de defensas"
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and shot_timer <= 0 and get_viewport().gui_get_hovered_control() == null:
		if me.get("equipped","weapon")=="tool":
			shot_timer=0.85
			var target: Dictionary = {}
			var closest := 2.6
			for resource in state.get("resources",[]):
				var distance := Vector2(resource.x-aim.x,resource.y-aim.z).length()
				if distance<closest:
					closest=distance
					target=resource
			if target.is_empty(): hud.notify_action("Apunta a la base del árbol o de la roca. Acércate para recoger.",false)
			else: network.act("harvest",{"id":target.id})
		elif me.ammo>0 and me.reload<=0:
			shot_timer = float(state.get("adventure",{}).get("weapon",{}).get("cooldown",Settings.shot_interval))
			network.act("shoot", {"angle": angle})

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P and network.connected:
			network.act("pause")
			return
		if event.physical_keycode == KEY_O:
			hud.toggle_population()
		if event.physical_keycode == KEY_J:
			hud.toggle_journal()
		if event.physical_keycode == KEY_ESCAPE:
			set_build_mode(false)
			hud.journal.hide()
			hud.settings.hide()
			hud.population_panel.hide()
	if not playable():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		if row_dragging:
			row_dragging=false
		else:
			var inspected := hovered_structure()
			selected_structure=str(inspected.get("id",""))
			hud.inspect_structure(state,me,inspected)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and building:
		var point: Vector3 = camera.ground_point()
		var target := Placement.snap(state,Vector2(point.x,point.z),selected_kind,rotated)
		if event.shift_pressed and selected_kind in ["wall","gate","spikes"]:
			row_start=target
			row_dragging=true
		else:
			var reason := Placement.reason(state,me,target,selected_kind,rotated)
			if reason.is_empty(): network.act("build", {"kind":selected_kind,"x":target.x,"y":target.y,"rot":1 if rotated else 0})
			else: hud.notify_action(reason,false)
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if building and event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_8:
		row_dragging=false
		var index: int = event.physical_keycode-KEY_1
		if index<hud.catalog_ids.size(): selected_kind=hud.catalog_ids[index]
		return
	match event.physical_keycode:
		KEY_B: set_build_mode(not building)
		KEY_G: rotated = not rotated
		KEY_R: network.act("reload")
		KEY_SPACE: network.act("dodge")
		KEY_K: network.act("rebuild_vault")
		KEY_Q: toggle_equipment()
		KEY_C: network.act("craft")
		KEY_V: network.act("scavenge")
		KEY_H: network.act("consume",{"item":"food"})
		KEY_Y: network.act("consume",{"item":"water"})
		KEY_N: network.act("consume",{"item":"medical"})
		KEY_E:
			var hovered := hovered_structure()
			if not hovered.is_empty() and hovered.get("kind","wall")!="wall":
				network.act("use",{"id":hovered.id})
			else: network.act("interact")
		KEY_U: network.act("upgrade")
		KEY_T: network.act("deposit")
		KEY_F, KEY_X:
			var nearest: Dictionary = {}
			var distance := 5.0
			for wall in state.walls:
				var d := Vector2(wall.x-me.x, wall.y-me.y).length()
				if wall.get("communityId", "forest") == me.communityId and d < distance:
					nearest = wall
					distance = d
			if not nearest.is_empty():
				network.act("repair" if event.physical_keycode == KEY_F else "dismantle", {"id": nearest.id})
		KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
			var powers := ["heal", "haste", "fury", "resist", "control", "shield"]
			network.act("cast", {"power": powers[event.physical_keycode-KEY_2]})

func set_build_mode(enabled: bool) -> void:
	if enabled and (me.is_empty() or not me.get("alive",false) or state.get("phase","")!="active"):
		hud.notify_action("Espera a reaparecer para construir.",false)
		return
	if enabled and not building:
		survival_zoom=camera.size
		camera.size=maxf(42,grid_radius*2.3)
	elif not enabled and building: camera.size=survival_zoom
	row_dragging=false
	clear_children(row_ghosts)
	building=enabled
	if enabled and not me.is_empty():
		build_offset=Vector3(state.vault.x-me.x,0,state.vault.y-me.y)
		hud.notify_action("Construye dentro del borde AZUL y fuera del centro ROJO. El plano VERDE confirma un lugar válido.",true)
	if not enabled: build_offset=Vector3.ZERO
	if is_instance_valid(grid_view): grid_view.visible=enabled
	if is_instance_valid(hud) and is_instance_valid(hud.build_panel): hud.build_panel.visible=enabled
	if not enabled:
		selected_structure=""
		if is_instance_valid(hud): hud.inspector.hide()

func toggle_equipment() -> void:
	if not playable(): return
	set_build_mode(false)
	network.act("equip",{"item":"weapon" if me.get("equipped","weapon")=="tool" else "tool"})

func find_plot() -> void:
	if not playable() or not building: return
	var center := Vector2(state.vault.x,state.vault.y)
	var last_reason := "No queda espacio libre. Amplía tu base con U junto a la bóveda."
	for radius in range(7,int(grid_radius)-1):
		for i in range(32):
			var angle := i*TAU/32
			var point := (center+Vector2(cos(angle),sin(angle))*radius).snapped(Vector2(0.2,0.2))
			var reason := Placement.reason(state,me,point,selected_kind,rotated)
			if reason.is_empty():
				build_offset=Vector3(point.x-me.x,0,point.y-me.y)
				camera.focus=Vector3(point.x,0,point.y)
				camera.position=camera.focus+camera.offset
				Input.warp_mouse(camera.unproject_position(camera.focus))
				hud.notify_action("Lugar disponible encontrado. Haz clic en el plano verde para construir.",true)
				return
			if reason.contains("Materiales") or reason.contains("base") or reason.contains("Bóveda"): last_reason=reason
	hud.notify_action(last_reason,false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and row_dragging:
		row_dragging=false
		if playable() and building and get_viewport().gui_get_hovered_control()==null:
			var end: Vector3 = camera.ground_point()
			network.act("build_row",{"kind":selected_kind,"x":row_start.x,"y":row_start.y,"endX":end.x,"endY":end.z})
		get_viewport().set_input_as_handled()

func hovered_structure() -> Dictionary:
	var point: Vector3 = camera.ground_point()
	for b in state.get("walls",[]):
		var h := Placement.half(state,b)
		if absf(b.x-point.x)<h.x+0.3 and absf(b.y-point.z)<h.y+0.3 and b.communityId==me.get("communityId",""):
			return b
	return {}
