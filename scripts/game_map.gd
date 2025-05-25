extends GameSceneBase

@onready var ui_manager: UIManager = $UIManager
@onready var player_ui: Control = $UIManager/PlayerUI
@onready var button: Button = $UIManager/Button

func _ready() -> void:
	# 连接按钮信号
	button.pressed.connect(_on_dialogue_button_pressed)

func _on_dialogue_button_pressed() -> void:
	# 切换到对话状态
	CoreSystem.event_bus.push_event("switch_to_dialogue")
