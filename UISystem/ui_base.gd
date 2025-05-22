extends Control
class_name UIBase

'''
UI基类
引用uimanager
界面名称
打开和关闭时的回调函数
'''

var interface_name: StringName = ""
var ui_manager: UIManager :
	get:
		return get_parent()

func _opened() -> void:
	pass
	
func _closed() -> void:
	pass
