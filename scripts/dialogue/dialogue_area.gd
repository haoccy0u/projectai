extends Control

# 定义信号
signal message_sent(text: String)

var MessageScene: PackedScene

@onready var message_container = $DialogueArea/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var input_field = $DialogueArea/MarginContainer/VBoxContainer/HBoxContainer/Input
@onready var send_button = $DialogueArea/MarginContainer/VBoxContainer/HBoxContainer/send

func _ready():
	CoreSystem.logger.info("初始化对话区域...")
	
	# 加载消息场景
	MessageScene = preload("res://scripts/dialogue/message.tscn")
	if not MessageScene:
		CoreSystem.logger.error("无法加载消息场景")
		return
	
	# 检查节点引用
	if not _check_node_references():
		return
	
	# 连接发送按钮信号
	send_button.pressed.connect(_on_send_button_pressed)
	
	CoreSystem.logger.info("对话区域初始化完成")

func _check_node_references() -> bool:
	if not message_container:
		CoreSystem.logger.error("message_container节点未找到")
		return false
		
	if not input_field:
		CoreSystem.logger.error("input_field节点未找到")
		return false
		
	if not send_button:
		CoreSystem.logger.error("send_button节点未找到")
		return false
		
	return true

# 创建并显示消息
func create_message(speaker: String, content: String, is_player: bool) -> void:
	var message = MessageScene.instantiate()
	if not message:
		CoreSystem.logger.error("无法实例化消息场景")
		return
	
	# 设置消息内容
	var speaker_label = message.get_node("MarginContainer/VBoxContainer/SpeakerName")
	var content_label = message.get_node("MarginContainer/VBoxContainer/RichTextLabel")
	
	if not speaker_label or not content_label:
		CoreSystem.logger.error("消息场景结构不正确")
		return
	
	speaker_label.text = speaker
	content_label.text = content
	
	# 添加到容器
	message_container.add_child(message)
	
	# 在下一帧自动滚动到底部
	scroll_to_bottom.call_deferred()

# 自动滚动到底部
func scroll_to_bottom() -> void:
	var scroll = message_container.get_parent() as ScrollContainer
	if scroll and scroll.get_v_scroll_bar():
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# 发送按钮点击事件
func _on_send_button_pressed() -> void:
	var text = input_field.text
	if text.strip_edges().is_empty():
		return
	
	# 发送信号
	message_sent.emit(text)
	# 清空输入
	input_field.text = ""

func _exit_tree() -> void:
	if send_button:
		send_button.pressed.disconnect(_on_send_button_pressed)
