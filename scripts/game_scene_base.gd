extends Node
class_name GameSceneBase

# 使用GameFlowMachine中定义的事件常量
const GameEvents = GameFlowMachine.GameEvents

func _ready() -> void:
	# 启用输入处理
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC键
		_on_pause_requested()

func _on_pause_requested() -> void:
	# 发送暂停事件
	_before_pause()
	CoreSystem.event_bus.push_event(GameEvents.PAUSE_GAME)

# 子类可以重写这个方法来添加额外的暂停逻辑
func _before_pause() -> void:
	pass
