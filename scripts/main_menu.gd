extends Node2D

const GameEvents = GameFlowMachine.GameEvents

@onready var new_game: Button = $UI/NewGame
@onready var load_game: Button = $UI/LoadGame
@onready var quit: Button = $UI/Quit

func _ready() -> void:
	new_game.pressed.connect(_on_new_game_pressed)
	load_game.pressed.connect(_on_load_game_pressed)
	quit.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
	# 发送事件，可以带参数
	CoreSystem.event_bus.push_event(GameEvents.MENU_NEW_GAME)

func _on_quit_pressed() -> void:
	self.get_tree().quit()

func _on_load_game_pressed() -> void:
	CoreSystem.event_bus.push_event(GameEvents.MENU_LOAD_GAME)
	
