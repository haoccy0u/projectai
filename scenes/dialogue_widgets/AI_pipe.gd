extends Node
class_name AIPipe

# 单例实现
static var instance: AIPipe = null

static func get_instance() -> AIPipe:
	return instance

func _init():
	if instance == null:
		instance = self
	else:
		push_error("AIPipe已经存在")

#Region 1. AI进程通信接口
# WebSocket连接
var _websocket: WebSocketPeer = null
var _is_connected: bool = false

# AI进程状态
var _ai_process_status := {
	"is_connected": false,
	"is_processing": false
}

func _process(_delta: float) -> void:
	if _websocket:
		_websocket.poll()
		var state = _websocket.get_ready_state()
		match state:
			WebSocketPeer.STATE_CONNECTING:
				_handle_connecting_state()
			WebSocketPeer.STATE_OPEN:
				_handle_open_state()
			WebSocketPeer.STATE_CLOSED:
				_handle_closed_state()

func connect_to_ai_process() -> void:
	_websocket = WebSocketPeer.new()
	var err = _websocket.connect_to_url("ws://localhost:8080")
	if err != OK:
		update_ai_status({"error": "连接失败"})
		return
	_ai_process_status.is_connected = false

func disconnect_from_ai_process() -> void:
	if _websocket:
		_websocket.close()
		_websocket = null
	_ai_process_status.is_connected = false

func send_to_ai(message: Dictionary) -> void:
	if not _websocket or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		update_ai_status({"error": "未连接到AI服务"})
		return
	
	var json_str = JSON.stringify(message)
	_websocket.send_text(json_str)
	_ai_process_status.is_processing = true

# 内部WebSocket状态处理方法
func _handle_connecting_state() -> void:
	if not _ai_process_status.is_connected:
		update_ai_status({"status": "connecting"})

func _handle_open_state() -> void:
	# 首次连接处理
	if not _ai_process_status.is_connected:
		_ai_process_status.is_connected = true
		update_ai_status({"status": "connected"})
	
	# 检查并处理接收到的消息
	while _websocket.get_available_packet_count() > 0:
		var packet = _websocket.get_packet()
		var text = packet.get_string_from_utf8()
		
		var response = JSON.parse_string(text)
		if response:
			_ai_process_status.is_processing = false
			CoreSystem.logger.info("[AIPipe] 收到WebSocket消息: %s" % str(response))
			broadcast_ai_response(response)
		else:
			CoreSystem.logger.error("消息解析失败")

func _handle_closed_state() -> void:
	if _ai_process_status.is_connected:
		_ai_process_status.is_connected = false
		update_ai_status({"status": "disconnected"})

func receive_from_ai() -> Dictionary:
	return {}
#EndRegion

#Region 2. 消息暂存系统
# 消息队列
var _message_queue: Array[Dictionary] = []
var _message_history: Array[Dictionary] = []

# 消息管理方法
func queue_message(message: Dictionary) -> void:
	pass

func get_message_history() -> Array:
	return []

func clear_message_queue() -> void:
	pass
#EndRegion

#Region 3. 游戏通信接口
# 事件定义
const EVENT_AI_DIALOGUE = "ai_dialogue_message"    # 对话消息
const EVENT_AI_MAP = "ai_map_message"             # 地图消息
const EVENT_AI_SCENE = "ai_scene_message"         # 场景消息
const EVENT_AI_STATUS = "ai_status_change"        # AI状态变化
const EVENT_AI_ERROR = "ai_error_occurred"        # AI错误

#消息类型定义
const MESSAGE_TYPE_DIALOGUE = "dialogue"
const MESSAGE_TYPE_MAP = "map"
const MESSAGE_TYPE_SCENE = "scene"


# 游戏通信方法
func broadcast_ai_response(response: Dictionary) -> void:
	# 检查消息类型
	if not response.has("type"):
		CoreSystem.logger.warning("收到未知类型的消息")
		return
		
	match response["type"]:
		MESSAGE_TYPE_DIALOGUE:
			var dialogue_data = {
				"speaker": response["speaker"],
				"content": response["content"],
				"is_player": response.get("is_player", false)
			}
			# 保存到消息历史
			_message_history.append(dialogue_data)
			CoreSystem.logger.info("[AIPipe] 广播对话事件: %s" % str(dialogue_data))
			CoreSystem.event_bus.push_event(EVENT_AI_DIALOGUE, [dialogue_data])
		MESSAGE_TYPE_MAP:
			pass # 预留地图消息处理
		MESSAGE_TYPE_SCENE:
			pass # 预留场景消息处理
		_:
			CoreSystem.logger.warning("未处理的消息类型: " + response["type"])

func update_ai_status(status: Dictionary) -> void:
	CoreSystem.logger.debug("AI状态更新: %s" % str(status))
	# 确保事件数据格式正确
	if status.has("status") or status.has("error"):
		CoreSystem.event_bus.push_event(EVENT_AI_STATUS, [status])
		CoreSystem.logger.debug("已推送状态更新事件")

func handle_game_event(event_name: String, payload: Array) -> void:
	pass

# 修改对话消息处理方法
func _handle_dialogue_message(message: Dictionary) -> void:
	CoreSystem.logger.debug("开始处理对话消息: %s" % str(message))
	
	if not (message.has("speaker") and message.has("content")):
		CoreSystem.logger.warning("对话消息格式错误")
		return
	
	var dialogue_data = {
		"speaker": message["speaker"],
		"content": message["content"],
		"is_player": message.get("is_player", false)
	}
	
	CoreSystem.logger.debug("准备广播对话消息: %s" % str(dialogue_data))
	_message_history.append(dialogue_data)
	CoreSystem.event_bus.push_event(EVENT_AI_DIALOGUE, [dialogue_data])
	CoreSystem.logger.debug("对话消息已广播")
#EndRegion
