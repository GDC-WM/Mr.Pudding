extends Area2D

#EntityAttacker is an Area2D that scans for EntityHurtboxes and tries to deal damage to them.
#If uses_action is true and up_time > 0, this will be an interactible hitbox controlled by the player.

#Name of the action used to activate this hitbox if uses_action is true and up_time > 0. 
#See ProjectSettings->InputMap for action names. 
#"attack" is bound to X on the keyboard by default.
@export var action:String = "attack"
#If false, inputs will not be recorded on this object
@export var uses_action:bool = true

#The amount of time after try_attack is called that this hitbox is active. If zero, try_attack will permanently enable the hitbox.
@export var up_time:float = 0.5
#The amount of time after up_time is over before the hitbox can be enabled again.
#Puts some space between the player's attacks.
@export var down_time:float = 0.25

#Reference to the entity that owns this attacker. 
@export_node_path("Node2D") var entity_path := NodePath("../")
var entity:Node2D

#Reference to the timer that is used to time attacks according to up_time and down_time
@export_node_path("Timer") var timer_path := NodePath("Timer")
var timer:Timer

#Reference to another object that takes care of damage calculations
@export_node_path("DamageSource") var damage_source_path := NodePath("DamageSource")
var damage_source:DamageSource

#available is true when the hitbox can be enabled with action
var available = true
#enabled is true when the hitbox is up and ready to damage things
var enabled = true

func _ready():
	reconnect()
	disable()
	if (!uses_action):
		set_process_input(false)
	connect("body_entered",_on_body_entered)

#turn all the NodePaths into concrete references
func reconnect():
	entity = get_node(entity_path)
	if (up_time > 0): timer = get_node(timer_path)
	damage_source = get_node(damage_source_path)

#listen for the action to enable the hitbox
func _input(event):
	if event.is_action_pressed(action):
		try_attack()

#try to enable the hitbox, possibly starting the up_time timer
func try_attack():
	if !available: return
	
	available = false
	enable()
	
	if (up_time > 0):
		timer.connect("timeout", stop_attack, 4)
		timer.start(up_time)

#disable the hitbox and start the down_time timer
func stop_attack():
	disable()
	timer.connect(
		"timeout", 
		func (): available = true, #nasty nasty lambdas
		4
	)
	timer.start(down_time)

func disable():
	visible = false
	enabled = false
	
func enable():
	visible = true
	enabled = true
	(func (): for b in get_overlapping_bodies():
		_on_body_entered(b)
	).call_deferred()

func _on_body_entered(body):
	if !enabled: return
	
	if body is EntityHurtbox:
		body.deal_damage(damage_source.calc_damage())
