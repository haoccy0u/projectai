extends Node
class_name GameController

## 游戏主控制器
## 负责场景管理和游戏流程控制

const SceneManager = CoreSystem.SceneManager

@onready var scene_manager : SceneManager = CoreSystem.scene_manager
@onready var state_machine_manager : CoreSystem.StateMachineManager = CoreSystem.state_machine_manager
#场景路径

var SCENE_PATHS = [
	FileDirHandler.get_object_script_dir(self) + "/scenes/main_menu.tscn",
	FileDirHandler.get_object_script_dir(self) + "/scenes/game_map.tscn",
	FileDirHandler.get_object_script_dir(self) + "/scenes/game_scene.tscn",
	FileDirHandler.get_object_script_dir(self) + "/scenes/game_dialogue.tscn",
]

#预加载场景
var _preloaded_scenes : Dictionary = {}

func _ready() -> void:
	_init_scene_manager()
	_init_state_machine()
	_init_input_system()
	CoreSystem.logger.info("main初始化完成")
	
func _init_state_machine() -> void:
	var game_flow_machine = GameFlowMachine.new()
	state_machine_manager.register_state_machine(&"gameflow", game_flow_machine, self, &"menu")

func _init_scene_manager() -> void:
	for scene_path in SCENE_PATHS:
		_preloaded_scenes[scene_path] = false
		scene_manager.preload_scene(scene_path)
	
func _init_input_system() -> void:

	pass
