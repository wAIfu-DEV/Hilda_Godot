class_name Subtitles extends PanelContainer

const DEFAULT_FONT_SIZE: int = 42

var rgx_only_alphanum: RegEx = RegEx.create_from_string("[^a-z0-9]")
var should_prep_space: bool = false

# VARS -------------------------------------------------------------------------
@onready var ref_world: World = null
@onready var ref_wrapcont: HFlowContainer = $"HFlowContainer"
@onready var ref_tempword: Label = $"TemplateWord"
@onready var ref_tempemote: TextureRect = $"TemplateEmote"

var current_font_size: int = 42

# CODE -------------------------------------------------------------------------
func _ready() -> void:
    ref_world = get_tree().current_scene as World


func addWord(text: String)-> void:
    if !visible: visible = true
    var em = ref_world.ref_emotemanager
    var lower = text.to_lower()
    var sanitized = rgx_only_alphanum.sub(lower, "", true)
    while em.isEmote(sanitized):
        should_prep_space = true
        var emote: TextureRect = ref_tempemote.duplicate() as TextureRect
        ref_wrapcont.add_child(emote)
        var emote_texture = em.getEmoteIfCached(sanitized)
        if emote_texture == null:
            emote_texture = await em.asyncFetchEmote(sanitized)
        if !is_instance_valid(emote): return
        emote.texture = emote_texture
        emote.visible = true
        emote.custom_minimum_size.x = current_font_size
        emote.custom_minimum_size.y = current_font_size
        emote.size.x = current_font_size
        emote.size.y = current_font_size
        return
    var word: Label = ref_tempword.duplicate() as Label
    var temp: String = "%s " if !should_prep_space else " %s "
    should_prep_space = false
    word.text = temp % text
    word.set("theme_override_font_sizes/font_size", current_font_size)
    word.visible = true
    ref_wrapcont.add_child(word)
    await resizeFont()


func resizeFont()-> void:
    while size.y >= 500.0:
        current_font_size -= 1
        for child in ref_wrapcont.get_children():
            if child is Label:
                child.set("theme_override_font_sizes/font_size", current_font_size)
            if child is TextureRect:
                child.custom_minimum_size.x = current_font_size
                child.custom_minimum_size.y = current_font_size
                child.size.x = current_font_size
                child.size.y = current_font_size
        await  get_tree().process_frame



func clear()-> void:
    if visible: visible = false
    for child in ref_wrapcont.get_children():
        ref_wrapcont.remove_child(child)
        child.queue_free()
    current_font_size = DEFAULT_FONT_SIZE
