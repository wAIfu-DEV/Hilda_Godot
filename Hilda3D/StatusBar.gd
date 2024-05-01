class_name StatusBar extends PanelContainer

@onready var ref_label = $"Label"

func displayStatus(text: String)-> void:
    ref_label.text = text
