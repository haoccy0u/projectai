extends Control

var MessageScene: PackedScene

@onready var message_container = $DialogueArea/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var input_field = $DialogueArea/MarginContainer/VBoxContainer/Input

# 事件名称定义
const EVENT_SEND_MESSAGE = "dialogue_send_message"
const EVENT_CREATE_MESSAGE = "dialogue_create_message"

func _ready():
	CoreSystem.logger.info("初始化对话区域...")
	
	# 检查节点引用
	CoreSystem.logger.debug("检查节点引用...")
	if not message_container:
		CoreSystem.logger.error("message_container节点未找到，尝试手动获取...")
		message_container = get_node("DialogueArea/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer")
		if not message_container:
			CoreSystem.logger.error("message_container节点仍未找到，初始化失败")
			return
	CoreSystem.logger.debug("message_container节点已找到")
	
	if not input_field:
		CoreSystem.logger.error("input_field节点未找到，尝试手动获取...")
		input_field = get_node("DialogueArea/MarginContainer/VBoxContainer/Input")
		if not input_field:
			CoreSystem.logger.error("input_field节点仍未找到，初始化失败")
			return
	CoreSystem.logger.debug("input_field节点已找到")
	
	# 加载消息场景
	CoreSystem.logger.debug("开始加载消息场景...")
	MessageScene = load("res://scenes/dialogue_widgets/message.tscn")
	if not MessageScene:
		CoreSystem.logger.error("无法加载消息场景")
		return
	CoreSystem.logger.debug("消息场景加载成功")
		
	# 初始化AI连接
	_setup_ai_connection()
	# 订阅AI对话消息事件
	CoreSystem.event_bus.subscribe(AIPipe.EVENT_AI_DIALOGUE, _on_ai_dialogue)
	CoreSystem.event_bus.subscribe(AIPipe.EVENT_AI_STATUS, _on_ai_status_change)
	CoreSystem.logger.debug("事件订阅完成")
	# 注册输入动作
	_setup_input()
	CoreSystem.logger.info("对话区域初始化完成")

func _setup_input() -> void:
	CoreSystem.logger.debug("设置输入系统...")
	
	# 使用输入管理器注册提交动作
	var input_manager = CoreSystem.input_manager
	
	# 创建回车键事件
	var enter_event = InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	
	# 创建小键盘回车事件
	var kp_enter_event = InputEventKey.new()
	kp_enter_event.keycode = KEY_KP_ENTER
	
	# 注册动作和按键映射
	if not InputMap.has_action("dialogue_submit"):
		InputMap.add_action("dialogue_submit")
		InputMap.action_add_event("dialogue_submit", enter_event)
		InputMap.action_add_event("dialogue_submit", kp_enter_event)
	
	# 更新输入状态
	input_manager.input_state.update_action("dialogue_submit", false, 0.0)
	# 连接信号
	if not input_manager.action_triggered.is_connected(_on_action_triggered):
		input_manager.action_triggered.connect(_on_action_triggered)
	
	# 设置输入框初始状态 - 移除输入锁
	input_field.editable = true  # 始终允许输入
	input_field.text = ""
	
	CoreSystem.logger.debug("输入动作'dialogue_submit'已注册")

func _setup_ai_connection() -> void:
	CoreSystem.logger.debug("初始化AI连接...")
	
	# 获取AIPipe实例
	var ai_pipe = AIPipe.get_instance()
	if not ai_pipe:
		CoreSystem.logger.error("AIPipe实例不存在")
		return
	
	# 连接到AI进程
	ai_pipe.connect_to_ai_process()
	CoreSystem.logger.debug("已发起AI连接请求")
	
	# 添加初始化消息
	_create_message("System", "正在连接AI服务...", false)

func _on_ai_status_change(payload: Array) -> void:
	if payload.is_empty():
		CoreSystem.logger.warning("收到空的AI状态变更payload")
		return
		
	var status_data = payload[0]
	var status = status_data.get("status", "")
	CoreSystem.logger.info("AI状态变更: %s" % status)
	
	match status:
		"connected":
			CoreSystem.logger.debug("准备创建连接成功消息")
			_create_message("System", "AI服务已连接", false)
			CoreSystem.logger.debug("AI服务连接成功消息已创建")
		"disconnected":
			_create_message("System", "AI服务已断开", false)
			CoreSystem.logger.warning("AI服务已断开")
		"connecting":
			_create_message("System", "正在连接AI服务...", false)
			CoreSystem.logger.debug("正在连接AI服务...")
	
	if status_data.has("error"):
		var error_msg = status_data["error"]
		_create_message("System", "错误: " + error_msg, false)
		CoreSystem.logger.error("AI服务错误: %s" % error_msg)

func _on_action_triggered(action_name: String, _event: InputEvent) -> void:
	if not input_field.editable:
		return
		
	if action_name == "dialogue_submit" and input_field.has_focus():
		var text = input_field.text.strip_edges()
		if not text.is_empty():
			CoreSystem.logger.debug("触发提交动作: %s" % text)
			_on_text_submitted(text)

#Region 消息创建
func _on_ai_dialogue(payload: Array) -> void:
	CoreSystem.logger.debug("收到对话消息事件")
	if payload.is_empty():
		CoreSystem.logger.warning("对话消息payload为空")
		return
		
	var dialogue_data = payload[0]
	CoreSystem.logger.debug("对话消息数据: %s" % str(dialogue_data))
	
	# 检查消息容器状态
	if not message_container:
		CoreSystem.logger.error("消息容器不存在")
		return
	
	CoreSystem.logger.debug("当前消息容器子节点数: %d" % message_container.get_child_count())
	
	_create_message(
		dialogue_data["speaker"],
		dialogue_data["content"],
		dialogue_data["is_player"]
	)

func _create_message(speaker_name: String, content: String, is_player: bool) -> void:
	# 检查消息容器是否存在
	if not message_container:
		CoreSystem.logger.error("消息容器不存在，无法创建消息")
		CoreSystem.logger.error("消息容器路径: %s" % $DialogueArea/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer)
		return
		
	if not MessageScene:
		CoreSystem.logger.error("消息场景未加载")
		return
		
	CoreSystem.logger.debug("开始创建消息: %s - %s" % [speaker_name, content])
	
	# 实例化消息场景
	var message_instance = MessageScene.instantiate()
	if not message_instance:
		CoreSystem.logger.error("无法实例化消息场景")
		return
	
	# 设置消息内容前先确认节点路径
	CoreSystem.logger.debug("消息实例节点结构: %s" % message_instance.get_path())
	
	# 设置消息内容
	var speaker_label = message_instance.get_node("MarginContainer/VBoxContainer/SpeakerName")
	var content_label = message_instance.get_node("MarginContainer/VBoxContainer/RichTextLabel")
	
	CoreSystem.logger.debug("获取到的节点引用 - speaker_label: %s, content_label: %s" % [speaker_label, content_label])
	
	if not speaker_label or not content_label:
		CoreSystem.logger.error("消息场景中缺少必要的节点")
		CoreSystem.logger.error("speaker_label: %s, content_label: %s" % [speaker_label, content_label])
		return
	
	speaker_label.text = speaker_name
	content_label.text = content
	
	# 添加消息到容器前确认容器状态
	CoreSystem.logger.debug("消息容器子节点数量: %d" % message_container.get_child_count())
	
	# 添加消息到容器
	message_container.add_child(message_instance)
	CoreSystem.logger.debug("消息已添加到容器，当前子节点数量: %d" % message_container.get_child_count())
	
	# 自动滚动到底部
	await get_tree().create_timer(0.1).timeout
	var scroll_container = message_container.get_parent()
	if scroll_container and scroll_container.get_v_scroll_bar():
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value
		CoreSystem.logger.debug("已滚动到底部")

#EndRegion

#Region 文本提交
func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty():
		CoreSystem.logger.debug("尝试提交空文本，已忽略")
		return
		
	CoreSystem.logger.debug("提交文本: %s" % text)
	
	# 获取AI管道实例
	var ai_pipe = AIPipe.get_instance()
	if not ai_pipe:
		CoreSystem.logger.error("无法发送消息：AI管道不存在")
		_create_message("System", "错误：无法连接到AI服务", false)
		return
		
	if not ai_pipe._ai_process_status.is_connected:
		CoreSystem.logger.warning("AI服务未连接，消息可能无法发送")
		_create_message("System", "警告：AI服务未连接，消息可能无法发送", false)
	
	# 创建玩家消息
	_create_message("Player", text, true)
	
	# 尝试发送到AI处理
	ai_pipe.send_to_ai({
		"type": AIPipe.MESSAGE_TYPE_DIALOGUE,
		"content": text
	})
	
	CoreSystem.logger.debug("消息已发送至AI处理")
	
	# 清空输入框
	input_field.text = ""
	# 保持输入框焦点
	input_field.grab_focus()

func _exit_tree() -> void:
	CoreSystem.logger.debug("清理对话区域资源...")
	
	# 取消订阅事件
	CoreSystem.event_bus.unsubscribe(AIPipe.EVENT_AI_DIALOGUE, _on_ai_dialogue)
	CoreSystem.event_bus.unsubscribe(AIPipe.EVENT_AI_STATUS, _on_ai_status_change)
	# 断开输入信号连接
	CoreSystem.input_manager.action_triggered.disconnect(_on_action_triggered)
	
	CoreSystem.logger.info("对话区域已清理完成")

#EndRegion
