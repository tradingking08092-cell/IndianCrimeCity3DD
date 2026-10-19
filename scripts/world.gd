extends Node3D

var hero: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var status_label: Label
var driving := false
var speed := 0.0
var move_input := Vector2.ZERO
var look_delta := Vector2.ZERO
var yaw := 0.0
var pitch := -0.25
var touch_start := Vector2.ZERO
var joystick_id := -1
var camera_id := -1
var joystick_center := Vector2(125, 570)
var joystick_radius := 80.0
var jump_requested := false
var interact_requested := false
var time := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 7345
	_build_environment()
	_build_city()
	_build_player()
	_build_car()
	_build_ui()
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 70
	add_child(camera)
	_update_camera(1.0)

func _material(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _box(parent: Node3D, pos: Vector3, scale: Vector3, mat: Material, collidable := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = scale
	mesh.mesh = b
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	if collidable:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var shape := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = scale
		shape.shape = s
		body.add_child(shape)
	return mesh

func _build_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color("88b9e2")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("b9d0ed")
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color("b1c6d7")
	e.fog_density = 0.006
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	_box(self, Vector3(0,-0.55,0), Vector3(520,1,520), _material(Color("638a64")), true)

func _build_city() -> void:
	var asphalt := _material(Color("292f37"))
	var sidewalk := _material(Color("b5b5b0"))
	var stripe := _material(Color("efdeb3"))
	var wall_colors := [Color("b5b6b2"), Color("8c9ba7"), Color("d0bd9f"), Color("879399"), Color("c3b7ac")]
	var glass := _material(Color("4b788c"), 0.18, 0.2)
	for k in range(-2,3):
		var v := float(k) * 75.0
		_box(self, Vector3(v,0.02,0), Vector3(17,0.12,430), asphalt)
		_box(self, Vector3(0,0.025,v), Vector3(430,0.12,17), asphalt)
		for j in range(-21,22):
			if j % 3 == 0:
				_box(self, Vector3(v,0.11,j*10.0), Vector3(0.18,0.025,4), stripe)
				_box(self, Vector3(j*10.0,0.11,v), Vector3(4,0.025,0.18), stripe)
	for x in range(-2,2):
		for z in range(-2,2):
			var cx := x*75.0+37.5
			var cz := z*75.0+37.5
			_box(self, Vector3(cx,0.09,cz), Vector3(56,0.16,56), sidewalk)
			for i in range(2):
				for j in range(2):
					var px := cx+(i-0.5)*27.0
					var pz := cz+(j-0.5)*27.0
					var h := rng.randf_range(12,46)
					var width := rng.randf_range(14,20)
					_box(self, Vector3(px,h/2.0+0.18,pz), Vector3(width,h,width), _material(wall_colors[rng.randi_range(0,wall_colors.size()-1)]), true)
					for floor_idx in range(2,int(h/3.0)):
						var yy := floor_idx*3.0+0.4
						for side in [-1,1]:
							_box(self, Vector3(px,yy,pz+side*(width/2+0.012)), Vector3(width*0.68,1.45,0.045), glass)
							_box(self, Vector3(px+side*(width/2+0.012),yy,pz), Vector3(0.045,1.45,width*0.68), glass)
	for x in range(-2,3):
		for z in range(-2,3):
			if (x+z)%2 == 0:
				_tree(Vector3(x*75.0+13,0,z*75.0+13))
				_tree(Vector3(x*75.0-13,0,z*75.0-13))

func _tree(pos: Vector3) -> void:
	_box(self,pos+Vector3(0,2.5,0),Vector3(0.65,5,0.65),_material(Color("68513d")))
	var leaves := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.8
	sphere.height = 5.6
	leaves.mesh = sphere
	leaves.material_override = _material(Color("326d42"))
	leaves.position = pos+Vector3(0,6,0)
	add_child(leaves)

func _build_player() -> void:
	hero = CharacterBody3D.new()
	hero.name = "Player"
	hero.position = Vector3(4,1.1,3)
	add_child(hero)
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.0
	col.shape = capsule
	hero.add_child(col)
	_box(hero,Vector3(0,-0.1,0),Vector3(0.8,1.2,0.42),_material(Color("253345")))
	_box(hero,Vector3(0,0.72,0),Vector3(0.55,0.55,0.55),_material(Color("d2a079")))
	_box(hero,Vector3(-0.25,-0.85,0),Vector3(0.26,0.6,0.3),_material(Color("1a2633")))
	_box(hero,Vector3(0.25,-0.85,0),Vector3(0.26,0.6,0.3),_material(Color("1a2633")))

func _build_car() -> void:
	car = CharacterBody3D.new()
	car.name = "SportCar"
	car.position = Vector3(4,0.8,-8)
	add_child(car)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.5,1.2,4.6)
	col.shape = shape
	car.add_child(col)
	_box(car,Vector3.ZERO,Vector3(2.4,0.75,4.5),_material(Color("bd2631"),0.25,0.4))
	_box(car,Vector3(0,0.65,-0.2),Vector3(1.95,0.8,2.2),_material(Color("274756"),0.12,0.35))
	var wheel_mat := _material(Color("181b20"))
	for sx in [-1,1]:
		for sz in [-1,1]:
			_box(car,Vector3(sx*1.25,-0.36,sz*1.45),Vector3(0.34,0.78,0.85),wheel_mat)
	for sx in [-1,1]:
		_box(car,Vector3(sx*0.85,0.04,-2.26),Vector3(0.5,0.22,0.06),_material(Color("fff4c5")))
		_box(car,Vector3(sx*0.85,0.04,2.26),Vector3(0.5,0.22,0.06),_material(Color("c9151b")))

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(layer)
	status_label = Label.new()
	status_label.text = "INDIAN CRIME CITY 3D   •   EXPLORE THE CITY"
	status_label.position = Vector2(18,14)
	status_label.add_theme_font_size_override("font_size",22)
	layer.add_child(status_label)
	var hint := Label.new()
	hint.text = "Left: move / steer     Right: look     DRIVE: enter / exit car"
	hint.position = Vector2(20,50)
	hint.add_theme_font_size_override("font_size",17)
	layer.add_child(hint)
	_button(layer,"JUMP",Vector2(1100,530),func(): jump_requested = true)
	_button(layer,"DRIVE",Vector2(1100,445),func(): interact_requested = true)
	_button(layer,"RUN",Vector2(970,530),func(): speed = 1.0)

func _button(parent: Control, label: String, pos: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.position = pos
	b.custom_minimum_size = Vector2(105,65)
	b.add_theme_font_size_override("font_size",22)
	b.pressed.connect(action)
	parent.add_child(b)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 420 and event.position.y > 260 and joystick_id == -1:
				joystick_id = event.index
				touch_start = event.position
			elif event.position.x > 420 and camera_id == -1:
				camera_id = event.index
		else:
			if event.index == joystick_id:
				joystick_id = -1
				move_input = Vector2.ZERO
			if event.index == camera_id:
				camera_id = -1
	if event is InputEventScreenDrag:
		if event.index == joystick_id:
			move_input = ((event.position-touch_start)/95.0).limit_length(1.0)
		elif event.index == camera_id:
			yaw -= event.relative.x*0.004
			pitch = clamp(pitch-event.relative.y*0.003,-0.65,0.25)
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x*0.004
		pitch = clamp(pitch-event.relative.y*0.003,-0.65,0.25)

func _physics_process(delta: float) -> void:
	time += delta
	var keyboard := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	var movement := move_input if move_input.length() > 0.08 else keyboard
	if interact_requested or Input.is_key_pressed(KEY_E) and not _last_e:
		if driving:
			driving = false
			hero.position = car.position+car.global_transform.basis.x*3.2+Vector3.UP
			hero.visible = true
		elif hero.position.distance_to(car.position) < 6.0:
			driving = true
			hero.visible = false
		interact_requested = false
	_last_e = Input.is_key_pressed(KEY_E)
	if driving:
		var forward := -car.global_transform.basis.z
		var acceleration := -movement.y
		speed = move_toward(speed,acceleration*23.0,delta*12.0)
		car.rotate_y(-movement.x*delta*1.8*clamp(abs(speed)/10.0,0.15,1.0))
		car.velocity = -car.global_transform.basis.z*speed
		car.velocity.y = -2.0
		car.move_and_slide()
		status_label.text = "INDIAN CRIME CITY 3D  |  DRIVING  %d km/h" % int(abs(speed)*3.6)
	else:
		var basis := Basis(Vector3.UP,yaw)
		var direction := basis*Vector3(movement.x,0,movement.y)
		hero.velocity.x = direction.x* (9.0 if Input.is_key_pressed(KEY_SHIFT) else 6.0)
		hero.velocity.z = direction.z* (9.0 if Input.is_key_pressed(KEY_SHIFT) else 6.0)
		if not hero.is_on_floor():
			hero.velocity.y -= 18.0*delta
		elif jump_requested or Input.is_key_pressed(KEY_SPACE):
			hero.velocity.y = 7.0
		jump_requested = false
		hero.move_and_slide()
		if direction.length() > 0.1:
			hero.rotation.y = atan2(-direction.x,-direction.z)
		status_label.text = "INDIAN CRIME CITY 3D  |  WALK TO RED CAR AND TAP DRIVE"
	_update_camera(delta)

var _last_e := false
func _update_camera(delta: float) -> void:
	if camera == null:
		return
	var target := car.global_position if driving else hero.global_position
	var distance := 9.0 if driving else 5.5
	var offset := Basis(Vector3.UP,yaw)*Vector3(0,3.0+(-pitch*4.0),distance)
	var desired := target+offset
	camera.global_position = camera.global_position.lerp(desired,clamp(delta*6.0,0.0,1.0))
	camera.look_at(target+Vector3.UP*0.7,Vector3.UP)
