extends Node2D

# 场景引用
const DialogueAreaScene = preload("res://scenes/dialogue_widgets/dialogue_area.tscn")
@onready var canvas_layer: CanvasLayer = $CanvasLayer

# 节点引用
var dialogue_area: Control
var ai_pipe: AIPipe

func _ready():
	CoreSystem.logger.info("初始化对话场景...")
	
	# 初始化AI管道
	_setup_ai_pipe()
	
	# 初始化对话区域
	_setup_dialogue_area()
	
	CoreSystem.logger.info("对话场景初始化完成")

func _setup_ai_pipe() -> void:
	CoreSystem.logger.debug("设置AI管道...")
	
	# 检查是否已存在AIPipe实例
	if not AIPipe.get_instance():
		# 实例化AIPipe
		ai_pipe = AIPipe.new()
		add_child(ai_pipe)
		CoreSystem.logger.debug("AI管道已创建")
	else:
		ai_pipe = AIPipe.get_instance()
		CoreSystem.logger.debug("使用现有AI管道实例")

func _setup_dialogue_area() -> void:
	CoreSystem.logger.debug("设置对话区域...")
	
	# 实例化对话区域
	dialogue_area = DialogueAreaScene.instantiate()
	_setup_dialogue_layout()
	canvas_layer.add_child(dialogue_area)
	
	# 设置对话区域位置和大小

	
	CoreSystem.logger.debug("对话区域已创建")

func _setup_dialogue_layout() -> void:
	# 这里可以添加对话区域的布局设置
	# 例如：位置、大小、锚点等
	pass

func _exit_tree() -> void:
	CoreSystem.logger.debug("清理对话场景...")
	
	# 如果AI管道是在这个场景创建的，我们需要清理它
	if ai_pipe and ai_pipe.get_parent() == self:
		ai_pipe.queue_free()
	
	CoreSystem.logger.info("对话场景已清理完成")

# 公共方法，用于外部访问对话区域
func get_dialogue_area() -> Control:
	return dialogue_area

# 公共方法，用于外部访问AI管道
func get_ai_pipe() -> AIPipe:
	return ai_pipe
