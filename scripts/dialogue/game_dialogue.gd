extends Node2D

# 场景引用
const DialogueAreaScene = preload("res://scripts/dialogue/dialogue_area.tscn")
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var ai_pipe: AIPipe = $AIPipe

# 节点引用
var dialogue_area: Control

# 事件名称定义
const EVENT_SEND_MESSAGE = "dialogue_send_message"    # 发送消息事件
const EVENT_AI_DIALOGUE = "ai_dialogue_message"    # 接收AI对话消息
const EVENT_AI_STATUS = "ai_status_change"        # AI状态变化

# 消息缓存系统
class MessageCache:
	var messages: Array[Dictionary] = []
	
	func add(message: Dictionary) -> void:
		messages.append({
			"message": message,
			"timestamp": Time.get_unix_time_from_system()
		})
		CoreSystem.logger.info("[MessageCache] 新增消息: %s" % str(message))
	
	func process_all(callback: Callable) -> void:
		CoreSystem.logger.info("[MessageCache] 开始处理缓存消息，共 %d 条" % messages.size())
		for item in messages:
			callback.call(item.message)
		clear()
	
	func clear() -> void:
		var count = messages.size()
		messages.clear()
		CoreSystem.logger.info("[MessageCache] 清理缓存消息，共清理 %d 条" % count)

var _message_cache := MessageCache.new()
var _is_ready: bool = false

func _ready():
	CoreSystem.logger.info("初始化对话场景...")
	
	# 初始化对话区域
	_setup_dialogue_area()
	
	# 连接AIPipe信号
	if ai_pipe:
		ai_pipe.connection_state_changed.connect(_on_connection_state_changed)
		ai_pipe.message_received.connect(_on_message_received)
	else:
		CoreSystem.logger.error("无法找到AIPipe节点")
	
	# 标记系统就绪
	_is_ready = true
	_process_cached_messages()
	
	CoreSystem.logger.info("对话场景初始化完成")

func _setup_dialogue_area() -> void:
	CoreSystem.logger.debug("设置对话区域...")
	
	# 实例化对话区域
	dialogue_area = DialogueAreaScene.instantiate()
	
	# 连接消息发送信号
	dialogue_area.message_sent.connect(_on_message_sent)
	
	canvas_layer.add_child(dialogue_area)
	
	CoreSystem.logger.debug("对话区域已创建")

func _process_cached_messages() -> void:
	CoreSystem.logger.info("处理缓存消息...")
	_message_cache.process_all(func(message: Dictionary):
		_handle_message(message)
	)

func _handle_message(message: Dictionary) -> void:
	if not message.has("type"):
		return
		
	match message["type"]:
		"dialogue":
			dialogue_area.create_message(
				message.get("speaker", "AI"),
				message.get("content", ""),
				message.get("is_player", false)
			)

func _exit_tree() -> void:
	CoreSystem.logger.debug("清理对话场景...")
	
	# 断开AIPipe信号
	if ai_pipe:
		ai_pipe.connection_state_changed.disconnect(_on_connection_state_changed)
		ai_pipe.message_received.disconnect(_on_message_received)
	
	# 断开对话区域信号
	if dialogue_area:
		dialogue_area.message_sent.disconnect(_on_message_sent)
	
	CoreSystem.logger.info("对话场景已清理完成")

# 公共方法，用于外部访问对话区域
func get_dialogue_area() -> Control:
	return dialogue_area

# 信号处理方法
func _on_message_sent(text: String) -> void:
	if text.strip_edges().is_empty():
		return
		
	# 显示玩家消息
	dialogue_area.create_message("Player", text, true)
	
	# 发送到AI处理
	if ai_pipe:
		ai_pipe.send_message(text)

func _on_connection_state_changed(status: Dictionary) -> void:
	var status_text = status.get("status", "")
	var error_text = status.get("error", "")
	
	if not _is_ready:
		_message_cache.add({
			"type": "dialogue",
			"speaker": "System",
			"content": _get_status_message(status_text, error_text),
			"is_player": false
		})
		return
	
	dialogue_area.create_message(
		"System",
		_get_status_message(status_text, error_text),
		false
	)

func _on_message_received(message: Dictionary) -> void:
	if not _is_ready:
		_message_cache.add(message)
		return
	
	_handle_message(message)

func _get_status_message(status: String, error: String = "") -> String:
	match status:
		"connected":
			return "AI服务已连接"
		"disconnected":
			return "AI服务已断开"
		"connecting":
			return "正在连接AI服务..."
		"error":
			return "错误: " + error if error else "发生错误"
		_:
			return "未知状态"
