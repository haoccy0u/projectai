extends BaseStateMachine
class_name GameFlowMachine

## 游戏流程状态机
## 管理游戏的主要状态：主菜单、游戏中和暂停

# 游戏事件定义
const GameEvents = {
	MENU_NEW_GAME = &"menu_new_game",
	MENU_LOAD_GAME = &"menu_load_game",
	PAUSE_GAME = &"pause_game",
	RESUME_GAME = &"resume_game",
	RETURN_TO_MENU = &"return_to_menu"
}

func _ready() -> void:	
	#初始化主状态机
	add_state(&"menu", MenuState.new())
	add_state(&"game", GameState.new())
	add_state(&"pause", PauseState.new())
	CoreSystem.logger.info("状态机初始化完成")

#Region 主菜单状态
class MenuState extends BaseState:
	func _enter(_msg := {}) -> void:
		CoreSystem.logger.info("进入主菜单状态")
		# 只在主菜单状态才监听开始游戏和退出游戏事件
		var event_bus = CoreSystem.event_bus
		event_bus.subscribe(GameEvents.MENU_NEW_GAME, _on_new_game)
		event_bus.subscribe(GameEvents.MENU_LOAD_GAME, _on_load_game)
		CoreSystem.scene_manager.change_scene_async(
			"res://scenes/main_menu.tscn",
			{},
			false,
			CoreSystem.SceneManager.TransitionEffect.FADE
		)

	func _exit() -> void:
		# 退出状态时取消订阅
		var event_bus = CoreSystem.event_bus
		event_bus.unsubscribe(GameEvents.MENU_NEW_GAME, _on_new_game)
		event_bus.unsubscribe(GameEvents.MENU_LOAD_GAME, _on_load_game)

	func _on_new_game(_data := {}) -> void:
		switch_to(&"game")
	
	func _on_load_game(_data := {}) -> void:
		pass

#EndRegion

#Region 游戏状态
class GameState extends BaseStateMachine:
	func _ready() -> void:
		# 添加子状态
		add_state(&"map", MapState.new())
		add_state(&"explore", ExploreState.new())
		add_state(&"dialog", DialogState.new())
		add_state(&"endday", EndDayState.new())
		CoreSystem.logger.info("游戏状态初始化完成")
	
	func _enter(_msg := {}) -> void:
		CoreSystem.logger.info("进入游戏状态")
		CoreSystem.event_bus.subscribe(GameEvents.PAUSE_GAME, _on_pause_game)
		
		# 如果没有当前状态，则启动默认状态
		if current_state == null:
			# 使用start方法初始化子状态,如果是从暂停恢复，不使用过渡效果
			if _msg.get("resume", false):
				start(&"map", {"transition_effect": CoreSystem.SceneManager.TransitionEffect.NONE}, true)
			else:
				start(&"map", {"transition_effect": CoreSystem.SceneManager.TransitionEffect.FADE}, false)

	func _exit() -> void:
		CoreSystem.event_bus.unsubscribe(GameEvents.PAUSE_GAME, _on_pause_game)
		stop()

	func _on_pause_game(_data := {}) -> void:
		# 传递resume标记，以便从暂停恢复时能够回到之前的状态
		switch_to(&"pause", {"resume": true})

# 游戏状态子状态
	class MapState extends BaseState:
		func _enter(msg := {}) -> void:
			CoreSystem.logger.info("进入地图状态")
			# 订阅对话状态切换事件
			CoreSystem.event_bus.subscribe("switch_to_dialogue", _on_switch_to_dialogue)
			# 根据传入的参数决定过渡效果
			var transition_effect = msg.get("transition_effect", CoreSystem.SceneManager.TransitionEffect.FADE)
			# 切换到地图场景，保存到栈
			CoreSystem.scene_manager.change_scene_async(
				"res://scenes/game_map.tscn",
				{},  # 场景数据
				true,  # 保存到栈
				transition_effect
			)

		func _exit() -> void:
			# 取消订阅事件
			CoreSystem.event_bus.unsubscribe("switch_to_dialogue", _on_switch_to_dialogue)

		func _on_switch_to_dialogue(_data := {}) -> void:
			switch_to(&"dialog")

		func _handle_input(event: InputEvent) -> void:
			if event.is_action_pressed("ui_accept"):
				switch_to(&"explore")
			elif event.is_action_pressed("ui_focus_next"):
				switch_to(&"dialog")

	class ExploreState extends BaseState:
		func _enter(_msg := {}) -> void:
			CoreSystem.logger.info("进入探索状态")
		
		func _handle_input(event: InputEvent) -> void:
			pass

	class DialogState extends BaseState:
		func _enter(_msg := {}) -> void:
			CoreSystem.logger.info("进入对话状态")
			# 切换到对话场景，使用淡入效果
			CoreSystem.scene_manager.change_scene_async(
				"res://scenes/game_dialogue.tscn",
				{},  # 场景数据
				true,  # 保存到栈
				CoreSystem.SceneManager.TransitionEffect.FADE
			)

		func _handle_input(event: InputEvent) -> void:
			pass

	class EndDayState extends BaseState:
		func _enter(_msg := {}) -> void:
			CoreSystem.logger.info("进入结束一天状态")

		func _handle_input(event: InputEvent) -> void:
			pass

#EndRegion

#Region 暂停状态
class PauseState extends BaseState:
	func _enter(_msg := {}) -> void:
		CoreSystem.logger.info("进入暂停状态")
		CoreSystem.event_bus.subscribe(GameEvents.RESUME_GAME, _on_resume_game)
		CoreSystem.event_bus.subscribe(GameEvents.RETURN_TO_MENU, _on_return_to_menu)
		
		# 不需要保存到栈，因为游戏场景还在
		CoreSystem.scene_manager.change_scene_async(
			"res://scenes/pause.tscn",
			{},
			false,
			CoreSystem.SceneManager.TransitionEffect.NONE
		)

	func _exit() -> void:
		CoreSystem.event_bus.unsubscribe(GameEvents.RESUME_GAME, _on_resume_game)
		CoreSystem.event_bus.unsubscribe(GameEvents.RETURN_TO_MENU, _on_return_to_menu)

	func _on_resume_game(_msg := {}) -> void:
		# 恢复到游戏状态，并传递resume标记和过渡效果设置
		switch_to(&"game", {
			"resume": true,
			"transition_effect": CoreSystem.SceneManager.TransitionEffect.NONE
		})

	func _on_return_to_menu(_msg := {}) -> void:
		switch_to(&"menu")
#EndRegion
