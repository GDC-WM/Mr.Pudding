extends Area2D

@export var action:String = "attack"
@export var uses_action:bool = true

@export var up_time:float = 0
@export var down_time:float = 0

@export_node_path("Node2D") var entity_path := NodePath("../")
var entity:Node2D

@export_node_path("Timer") var timer_path := NodePath("Timer")
var timer:Timer

@export_node_path("DamageSource") var damage_source_path := NodePath("DamageSource")
var damage_source:DamageSource

var available = true
var enabled = true

func _ready():
	reconnect()
	disable()
	if (!uses_action):
		set_process_input(false)

func reconnect():
	entity = get_node(entity_path)
	if (up_time > 0): timer = get_node(timer_path)
	damage_source = get_node(damage_source_path)
	connect("body_entered",_on_body_entered)

func _input(event):
	if event.is_action_pressed(action):
		try_attack()

func try_attack():
	if !available: return
	
	available = false
	enable()
	
	if (up_time > 0):
		timer.connect("timeout", stop_attack, 4)
		timer.start(up_time)

func _on_body_entered(body):
	if !enabled: return
	
	if body is EntityHurtbox:
		body.deal_damage(damage_source.calc_damage())

func stop_attack():
	disable()
	timer.connect("timeout", make_available, 4)
	timer.start(down_time)

func make_available():
	available = true

func disable():
	visible = false
	enabled = false
	
func enable():
	visible = true
	enabled = true
	(func (): for b in get_overlapping_bodies():
		_on_body_entered(b)
	).call_deferred()
	
