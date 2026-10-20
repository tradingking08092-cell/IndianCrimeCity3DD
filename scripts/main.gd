extends Node3D

var player: CharacterBody3D
var car: CharacterBody3D
var camera: Camera3D
var hud: Label
var in_car := false
var car_speed := 0.0
var jump_request := false
var touch_vector := Vector2.ZERO
var touch_steer := 0.0
var throttle := false
var brake := false
var joystick_id := -1
var joystick_start := Vector2.ZERO
var joystick_position := Vector2.ZERO
var held_touches := {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 45
	make_city()
	make_player()
	make_car()
	make_camera()
	make_ui()

func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m

func block(parent: Node3D, position: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
	var root: Node3D
	if solid:
		root = StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	else:
		root = Node3D.new()
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material(color)
	root.add_child(mesh)
	root.position = position
	parent.add_child(root)
	return root

func make_city() -> void:
	block(self, Vector3(0,-0.55,0), Vector3(250,1,250), Color(0.23,0.42,0.25))
	for i in range(-2,3):
		block(self, Vector3(i*40,-0.025,0), Vector3(13,0.08,240), Color(0.12,0.13,0.15), false)
		block(self, Vector3(0,-0.02,i*40), Vector3(240,0.08,13), Color(0.12,0.13,0.15), false)
		for j in range(-12,13):
			block(self, Vector3(i*40,0.03,j*9), Vector3(0.22,0.02,3.2), Color(0.95,0.85,0.45), false)
			block(self, Vector3(j*9,0.03,i*40), Vector3(3.2,0.02,0.22), Color(0.95,0.85,0.45), false)
	for x in range(-2,2):
		for z in range(-2,2):
			for a in range(2):
				for b in range(2):
					var h := rng.randf_range(7,26)
					var px := x*40+14+a*13
					var pz := z*40+14+b*13
					block(self, Vector3(px,h/2,pz), Vector3(9,h,9), Color.from_hsv(rng.randf_range(0.53,0.65),0.22,rng.randf_range(0.45,0.8)))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50,-35,0)
	light.light_energy = 1.2
	add_child(light)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55,0.75,0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8,0.85,1)
	env.ambient_light_energy = 0.8
	world.environment = env
	add_child(world)

func make_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0,1,3)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collision.shape = capsule
	player.add_child(collision)
	var body := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.35
	capsule_mesh.height = 1.8
	body.mesh = capsule_mesh
	body.material_override = material(Color(0.1,0.35,0.9))
	player.add_child(body)
	add_child(player)

func make_car() -> void:
	car = CharacterBody3D.new()
	car.position = Vector3(3,0.75,0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2,1.2,4)
	collision.shape = shape
	car.add_child(collision)
	block(car,Vector3.ZERO,Vector3(2,0.9,4),Color(0.9,0.12,0.1),false)
	block(car,Vector3(0,0.7,0.25),Vector3(1.6,0.7,2),Color(0.1,0.18,0.25),false)
	for x in [-1.0,1.0]:
		for z in [-1.25,1.25]:
			block(car,Vector3(x,-0.3,z),Vector3(0.3,0.7,0.8),Color(0.04,0.04,0.05),false)
	add_child(car)

func make_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 70
	add_child(camera)

func make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20,15)
	hud.add_theme_font_size_override("font_size",26)
	layer.add_child(hud)
	var help := Label.new()
	help.text = "LEFT: Move / Steer     RIGHT: JUMP / ENTER / GAS / BRAKE"
	help.position = Vector2(15,65)
	help.add_theme_font_size_override("font_size",19)
	layer.add_child(help)

func _physics_process(delta: float) -> void:
	var axis := touch_vector
	if axis.length() < 0.1:
		axis = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
	if in_car:
		var acceleration := (float(throttle) - float(brake)) * 16.0
		if Input.is_key_pressed(KEY_W): acceleration = 16.0
		if Input.is_key_pressed(KEY_S): acceleration = -16.0
		car_speed = move_toward(car_speed,clampf(car_speed+acceleration*delta,-12,25),4*delta)
		if not throttle and not brake and not Input.is_key_pressed(KEY_W) and not Input.is_key_pressed(KEY_S):
			car_speed = move_toward(car_speed,0,8*delta)
		car.rotate_y(-axis.x*delta*1.5*clampf(abs(car_speed)/10,0,1))
		car.velocity = -car.global_transform.basis.z * car_speed
		car.move_and_slide()
	else:
		var movement := Vector3(axis.x,0,axis.y)
		if movement.length() > 1: movement = movement.normalized()
		player.velocity.x = movement.x * 7
		player.velocity.z = movement.z * 7
		player.velocity.y -= 22*delta
		if jump_request and player.is_on_floor(): player.velocity.y = 9
		jump_request = false
		player.move_and_slide()
		if movement.length() > 0.1: player.rotation.y = atan2(-movement.x,-movement.z)
	var target := car.global_position if in_car else player.global_position
	var offset := car.global_transform.basis * Vector3(0,5,10) if in_car else Vector3(0,4.5,8)
	camera.global_position = camera.global_position.lerp(target+offset, minf(1,delta*6))
	camera.look_at(target+Vector3.UP*1.0)
	hud.text = "INDIAN CRIME CITY 3D  |  %s  |  Speed: %d" % ["DRIVING" if in_car else "WALKING",int(abs(car_speed)*4)]

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			held_touches[event.index] = event.position
			if event.position.x < get_viewport().get_visible_rect().size.x*0.45 and joystick_id == -1:
				joystick_id = event.index
				joystick_start = event.position
				joystick_position = event.position
			else:
				press_button(event.position)
		else:
			held_touches.erase(event.index)
			if event.index == joystick_id:
				joystick_id = -1
				touch_vector = Vector2.ZERO
			throttle = false
			brake = false
	elif event is InputEventScreenDrag and event.index == joystick_id:
		joystick_position = event.position
		touch_vector = (joystick_position-joystick_start)/85.0
		touch_vector = touch_vector.limit_length(1)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E: toggle_car()
		if event.keycode == KEY_SPACE: jump_request = true

func press_button(pos: Vector2) -> void:
	var size := get_viewport().get_visible_rect().size
	if pos.y < size.y*0.5:
		toggle_car()
	elif in_car:
		if pos.x > size.x*0.75: throttle = true
		else: brake = true
	else:
		jump_request = true

func toggle_car() -> void:
	if in_car:
		in_car = false
		player.global_position = car.global_position+car.global_transform.basis.x*2.5+Vector3.UP*0.5
		player.visible = true
	elif player.global_position.distance_to(car.global_position) < 5:
		in_car = true
		player.visible = false
