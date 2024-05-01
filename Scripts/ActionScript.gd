class_name ActionScript

const INST_TP: String =   "tp"
const INST_FLY: String =  "fly"
const INST_PATH: String = "path"
const INST_PATHTOPOI: String = "ppoi"
const INST_ROT: String =  "rot"
const INST_FACE: String = "face"
const INST_ANIM: String = "anim"
const INST_WAIT: String = "wait"
const INST_CMP: String = "cmp"
const INST_JNE: String = "jne"
const INST_JMP: String = "jmp"
const INST_RET: String = "ret"
const INST_LABEL: String = "labl"
const INST_GOTO: String = "goto"
const INST_GTNE: String = "gtne"
const INST_CAM: String = "cam"

static func Teleport(x: float, y: float, z: float)-> String:
    return "%s %f %f %f" % [INST_TP, x, y, z]

static func Fly(x: float, y: float, z: float)-> String:
    return "%s %f %f %f" % [INST_FLY, x, y, z]

static func Rotate(x: float, y: float, z: float)-> String:
    return "%s %f %f %f" % [INST_ROT, x, y, z]

static func Face(x: float, y: float, z: float)-> String:
    return "%s %f %f %f" % [INST_FACE, x, y, z]

static func Path(x: float, y: float, z: float)-> String:
    return "%s %f %f %f" % [INST_PATH, x, y, z]

static func PathToPoi(poi_name: String)-> String:
    return "%s %s" % [INST_PATHTOPOI, poi_name]

static func Animate(animation: String)-> String:
    return "%s %s" % [INST_ANIM, animation]

static func Wait(seconds: float)-> String:
    return "%s %f" % [INST_WAIT, seconds]

static func Compare(x: String, y: String)-> String:
    return "%s %s %s" % [INST_CMP, x, y]

static func JumpIfNotEqual(jump_amount: int)-> String:
    return "%s %d" % [INST_JNE, jump_amount]

static func Jump(jump_amount: int)-> String:
    return "%s %d" % [INST_JMP, jump_amount]

static func Return()-> String:
    return "%s" % INST_RET

static func Label(label_name: String)-> String:
    return "%s %s" % [INST_LABEL, label_name]

static func Goto(label: String)-> String:
    return "%s %s" % [INST_GOTO, label]

static func GotoIfNotEqual(label: String)-> String:
    return "%s %s" % [INST_GTNE, label]

static func Cam(cam_name: String)-> String:
    return "%s %s" % [INST_CAM, cam_name]
