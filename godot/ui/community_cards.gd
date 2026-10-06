extends VBoxContainer
const MenuSkin = preload("res://ui/illustrated_theme.gd")
const ART = preload("res://assets/ui/submenu_reference.png")
const IDS = ["forest", "mountain", "city", "underground"]
const ROW_Y = [284, 467, 646, 825]
var source: OptionButton
var cards: Array[Button] = []

func atlas(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ART
	texture.region = rect
	return texture

func rebuild(option: OptionButton) -> void:
	source = option
	for child in get_children():
		remove_child(child)
		child.queue_free()
	cards.clear()
	for index in range(source.item_count):
		var card := Button.new()
		card.name = "Community_" + str(source.get_item_metadata(index))
		card.custom_minimum_size = Vector2(0, 72)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.clip_contents = true
		card.tooltip_text = source.get_item_text(index)
		add_child(card)
		cards.append(card)
		var art_index := IDS.find(str(source.get_item_metadata(index)))
		if art_index < 0: art_index = index % 4
		var landscape := TextureRect.new()
		landscape.texture = atlas(Rect2(630, ROW_Y[art_index], 497, 148))
		landscape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		landscape.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(landscape)
		landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		landscape.offset_left = 330
		landscape.offset_top = 5
		landscape.offset_right = -5
		landscape.offset_bottom = -5
		var shade := ColorRect.new()
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment(){COLOR=vec4(0.12,0.17,0.065,1.0-smoothstep(0.32,0.82,UV.x));}"
		var material := ShaderMaterial.new()
		material.shader = shader
		shade.material = material
		card.add_child(shade)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var crest := TextureRect.new()
		crest.texture = atlas(Rect2(97, ROW_Y[art_index] + 4, 146, 142))
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.position = Vector2(12, 6)
		crest.size = Vector2(60, 60)
		crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(crest)
		var caption := Label.new()
		var text := source.get_item_text(index)
		caption.text = text.get_slice(" · ", 0)
		caption.position = Vector2(86, 7)
		caption.add_theme_font_size_override("font_size", 24)
		caption.add_theme_constant_override("outline_size", 4)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(caption)
		var count := Label.new()
		count.text = "●  " + text.get_slice(" · ", 1)
		count.position = Vector2(89, 38)
		count.add_theme_font_size_override("font_size", 20)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(count)
		card.pressed.connect(func():
			source.select(index)
			source.item_selected.emit(index)
			update_highlight()
		)
		card.mouse_entered.connect(func(): card.modulate = Color(1.08, 1.08, 1.03))
		card.mouse_exited.connect(func(): card.modulate = Color.WHITE)
	update_highlight()

func update_highlight() -> void:
	for index in range(cards.size()):
		cards[index].set_pressed_no_signal(index == source.selected)
		if index == source.selected:
			cards[index].add_theme_stylebox_override("normal", MenuSkin.box(Color("394c20"), Color("ffda43"), 4))
		else:
			cards[index].add_theme_stylebox_override("normal", MenuSkin.box(Color("354422"), Color("929b4a"), 3))