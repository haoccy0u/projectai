extends Node
class_name AIPipe
## AI对话管道，负责与AI服务通信

# 信号定义
signal connection_state_changed(status: Dictionary)
signal message_received(message: Dictionary)

# 常量
const WEBSOCKET_URL = "ws://localhost:8080"

# 消息类型
enum MessageType {
	DIALOGUE,
	MAP,
	SCENE
}

# 连接状态
enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	ERROR
}

# 私有变量
var _websocket: WebSocketPeer = null
var _connection_state: ConnectionState = ConnectionState.DISCONNECTED

# 生命周期方法
func _ready() -> void:
	if not Engine.is_editor_hint():
		connect_to_server()

func _process(_delta: float) -> void:
	if _websocket:
		_websocket.poll()
		_handle_websocket_state()

# 公共方法
## 连接到AI服务器
func connect_to_server() -> void:
	if _websocket != null:
		disconnect_from_server()
	
	_websocket = WebSocketPeer.new()
	var err = _websocket.connect_to_url(WEBSOCKET_URL)
	if err != OK:
		_handle_connection_state_change(ConnectionState.ERROR, "连接失败")
		return
	
	_handle_connection_state_change(ConnectionState.CONNECTING)

## 断开与服务器的连接
func disconnect_from_server() -> void:
	if _websocket:
		_websocket.close()
		_websocket = null
	_handle_connection_state_change(ConnectionState.DISCONNECTED)

## 发送消息到AI服务
func send_message(content: String, type: MessageType = MessageType.DIALOGUE) -> void:
	if not _is_connected():
		_handle_connection_state_change(ConnectionState.ERROR, "未连接到AI服务")
		return
	
	var message := {
		"type": _message_type_to_string(type),
		"content": content,
		"is_player": true
	}
	
	_send_to_server(message)

# 私有方法
func _handle_websocket_state() -> void:
	var state = _websocket.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_CONNECTING:
			if _connection_state != ConnectionState.CONNECTING:
				_handle_connection_state_change(ConnectionState.CONNECTING)
		
		WebSocketPeer.STATE_OPEN:
			if _connection_state != ConnectionState.CONNECTED:
				_handle_connection_state_change(ConnectionState.CONNECTED)
			_process_incoming_messages()
		
		WebSocketPeer.STATE_CLOSED:
			if _connection_state != ConnectionState.DISCONNECTED:
				_handle_connection_state_change(ConnectionState.DISCONNECTED)

func _process_incoming_messages() -> void:
	while _websocket.get_available_packet_count() > 0:
		var packet = _websocket.get_packet()
		var text = packet.get_string_from_utf8()
		
		var response = JSON.parse_string(text)
		if response:
			CoreSystem.logger.info("[AIPipe] 收到消息: %s" % str(response))
			if response.has("type"):
				message_received.emit(response)
		else:
			CoreSystem.logger.error("消息解析失败")

func _send_to_server(message: Dictionary) -> void:
	var json_str = JSON.stringify(message)
	_websocket.send_text(json_str)

func _handle_connection_state_change(new_state: ConnectionState, error_message: String = "") -> void:
	_connection_state = new_state
	
	var status = {
		"state": new_state,
		"status": _connection_state_to_string(new_state),
		"error": error_message
	}
	
	CoreSystem.logger.info("[AIPipe] 连接状态变更: %s" % str(status))
	connection_state_changed.emit(status)

func _is_connected() -> bool:
	return _connection_state == ConnectionState.CONNECTED

func _message_type_to_string(type: MessageType) -> String:
	match type:
		MessageType.DIALOGUE:
			return "dialogue"
		MessageType.MAP:
			return "map"
		MessageType.SCENE:
			return "scene"
		_:
			return "unknown"

func _connection_state_to_string(state: ConnectionState) -> String:
	match state:
		ConnectionState.DISCONNECTED:
			return "disconnected"
		ConnectionState.CONNECTING:
			return "connecting"
		ConnectionState.CONNECTED:
			return "connected"
		ConnectionState.ERROR:
			return "error"
		_:
			return "unknown"

func _exit_tree() -> void:
	disconnect_from_server()
