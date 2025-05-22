extends SceneBase

const GameEvents = GameFlowMachine.GameEvents
@onready var save_game: Button = $CanvasLayer/Control/VBoxContainer/Save
@onready var load_game: Button = $CanvasLayer/Control/VBoxContainer/Load
@onready var main_menu: Button = $CanvasLayer/Control/VBoxContainer/MainMenu
@onready var resume: Button = $CanvasLayer/Control/VBoxContainer/Resume

func _ready() -> void:
		# 连接按钮信号
	resume.pressed.connect(_on_resume_pressed)
	main_menu.pressed.connect(_on_menu_pressed)

func _on_resume_pressed() -> void:
	CoreSystem.event_bus.push_event(GameEvents.RESUME_GAME)

func _on_menu_pressed() -> void:
	CoreSystem.event_bus.push_event(GameEvents.RETURN_TO_MENU)
