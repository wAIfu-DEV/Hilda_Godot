class_name WebSocketManager extends Node

# CONSTANTS --------------------------------------------------------------------
const WEBSOCKET_URL: String = "ws://127.0.0.1:8426"

const PACKET_SEPARATOR: String = ";"
const PACKET_PREF_VOICE: String = "v"
const PACKET_PREF_NARRATOR: String = "n"
const PACKET_PREF_INTERRUPT: String = "i"
const PACKET_PREF_SUBS_WORD: String = "s"
const PACKET_PREF_SUBS_CLEAR: String = "c"
const PACKET_PREF_ANIMATE: String = "a"
const PACKET_PREF_CHATMESSAGE: String = "m"
const PACKET_PREF_SING: String = "g"
const PACKET_PREF_REDEEM: String = "r"
const PACKET_PREF_USER: String = "u"
const PACKET_PREF_INFO: String = "k"


# VARS -------------------------------------------------------------------------
var ws: WebSocketPeer = null
var ref_world: World = null


# CODE -------------------------------------------------------------------------
func _ready()-> void:
    ref_world = get_tree().current_scene as World
    ws = WebSocketPeer.new()
    ws.connect_to_url(WEBSOCKET_URL)


func _process(_delta: float)-> void:
    ws.poll()
    match ws.get_ready_state():
        WebSocketPeer.STATE_OPEN:
            while ws.get_available_packet_count():
                _handlePacket(ws.get_packet())
        WebSocketPeer.STATE_CLOSED:
            ref_world.ref_subtitles.clear()
            _tryReconnect()


func _tryReconnect()-> void:
    print("WS::RECONNECT")
    ws.connect_to_url(WEBSOCKET_URL)


func _handlePacket(packet: PackedByteArray)-> void:
    var payload: String = packet.get_string_from_utf8()
    #print("WS::PACKET: ", payload)
    var split_payload: PackedStringArray = payload.split(PACKET_SEPARATOR)
    if !split_payload.size(): return

    var prefix: String = split_payload[0]
    match prefix:
        PACKET_PREF_VOICE:
            print("WS::VOICE: ", PACKET_SEPARATOR.join(split_payload.slice(1)))
            var id: String = split_payload[1]
            var audio_path: String = split_payload[2]
            ref_world.setVoice(id, audio_path)
        PACKET_PREF_NARRATOR:
            print("WS::NARRATOR: ", PACKET_SEPARATOR.join(split_payload.slice(1)))
            var id: String = split_payload[1]
            var audio_path: String = split_payload[2]
            ref_world.setNarrator(id, audio_path)
        PACKET_PREF_SING:
            print("WS::SING: ", PACKET_SEPARATOR.join(split_payload.slice(1)))
            var id: String = split_payload[1]
            var voc_path: String = split_payload[2]
            var inst_path: String = split_payload[3]
            ref_world.setSong(id, voc_path, inst_path)
        PACKET_PREF_INTERRUPT:
            print("WS::INTERRUPT")
            ref_world.ref_subtitles.clear()
            ref_world.interruptSound()
        PACKET_PREF_SUBS_WORD:
            #print("WS::SUBS_WORD: ", PACKET_SEPARATOR.join(split_payload.slice(1)))
            var text: String = ";".join(split_payload.slice(2))
            if split_payload[1] == "1":
                 ref_world.current_hilda._checkKeyword(text)
            ref_world.ref_subtitles.addWord(text)
        PACKET_PREF_SUBS_CLEAR:
            print("WS::SUBS_CLEAR")
            ref_world.ref_subtitles.clear()
        PACKET_PREF_ANIMATE:
            print("WS::ANIMATE: ", split_payload[1])
            match split_payload[1]:
                "idle": ref_world.current_hilda.setIdleAnimation()
                "talk": ref_world.current_hilda.setTalkingAnimation()
                "listen": ref_world.current_hilda.setListeningAnimation()
                _: ref_world.current_hilda.setAnimation(split_payload[1])
        PACKET_PREF_CHATMESSAGE:
            #print("WS::CHATMSG: %s: %s" % [split_payload[1], split_payload.slice(2)])
            ref_world.ref_twitchchat.displayChatMessage(split_payload[1], ";".join(split_payload.slice(2)))
        PACKET_PREF_REDEEM:
            print("WS::REDEEM: %s" % split_payload[1])
            match split_payload[1]:
                "throw":
                    ref_world.current_hilda.spawnMultipleObjects(int(split_payload[2]))
                "nuke":
                    ref_world.current_user = split_payload[2]
                    ref_world.ref_nukescene.start()
                "bald":
                    ref_world.current_hilda.goBald()
        PACKET_PREF_USER:
            #print("WS::USER: %s" % split_payload[1])
            ref_world.current_user = split_payload[1]
        PACKET_PREF_INFO:
            print("WS::INFO: %s" % split_payload[1])
            ref_world.displayStatusMessage(split_payload[1])
        _:
            printerr("Received incorrect packet from w-AI-fu: ", prefix)


func sendPacket(packet: String)-> void:
    if ws.get_ready_state() != ws.STATE_OPEN:
        print("WS::ERR: Tried to send from closed websocket.")
        return
    print("WS::SENT: ", packet)
    ws.send_text(packet)
