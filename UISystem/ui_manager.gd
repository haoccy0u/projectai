extends CanvasLayer
class_name UIManager

'''
管理ui元素和ui界面
提供方法打开/关闭/切换ui窗口
管理/配置ui资源
处理相关事件输入
'''

@export var ui_path : String = "res://ui_widgets/"

var current_interface : UIBase:
	get:
		if self.get_child_count() == 0:
			return null
		return self.get_child(-1)

func _ready() -> void:
	CoreSystem.logger.info("UI管理器初始化")

func create_interface(name: StringName) -> Control:
	var widget_path = ui_path + name + ".tscn"
	
	# 使用资源系统加载UI场景
	var control = CoreSystem.resource_manager.load(widget_path)
	if not control:
		CoreSystem.logger.category("UI").error("无法加载UI: %s" % widget_path)
		return null
		
	var instance = control.instantiate()
	if "interface_name" in instance:
		instance.interface_name = name
		CoreSystem.logger.category("UI").debug("创建UI: %s" % name)
	return instance

func get_interface(ui_name: StringName) -> Control:
	for interface in get_children():
		if interface.interface_name == ui_name:
			return interface
	return null

func open_interface(ui_name:StringName, msg:Dictionary = {}) -> UIBase:
	CoreSystem.logger.category("UI").info("打开UI: %s" % ui_name)
	
	if current_interface:
		current_interface.hide()
		
	var interface = get_interface(ui_name)
	if interface:
		self.move_child(interface, -1)
	else:
		interface = create_interface(ui_name)
		self.add_child(interface)
		
	interface._opened()
	interface.show()
	return interface

func close_current_interface() -> void:
	var interface = current_interface
	if interface:
		CoreSystem.logger.category("UI").info("关闭UI: %s" % interface.interface_name)
		self.remove_child(interface)
		interface._closed()
		interface.queue_free()
		if current_interface:
			current_interface.show()
