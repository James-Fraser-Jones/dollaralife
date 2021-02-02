extends Control

export var start_index : int = 0
const ChoiceButton = preload("res://scenes/choice_button/ChoiceButton.tscn")

var game_log : RichTextLabel
var game_buttons : VBoxContainer

func _ready():
	game_log = $PanelContainer/MarginContainer/HSplitContainer/MarginContainer/PanelContainer/GameLog
	game_buttons = $PanelContainer/MarginContainer/HSplitContainer/ScrollContainer/GameButtons
	update_ui(start_index)
	
func update_ui(new_index):
	if new_index == -1:
		game_log.bbcode_text = "\n"
		update_ui(start_index)
	else:
		#find new snippet
		var new_snippet : Dictionary
		for snippet in story:
			if snippet.index == new_index:
				new_snippet = snippet
				break
		
		#add snippet text to log
		game_log.bbcode_text += ("\n\t" + new_snippet.text + "\n")
		
		#remove all current buttons
		for child in game_buttons.get_children():
			game_buttons.remove_child(child)
			child.queue_free()
		
		#add new buttons
		if new_snippet.choices.size() > 0:
			for choice in new_snippet.choices:
				var choice_button = ChoiceButton.instance()
				choice_button.get_child(0).bbcode_text = "\n\t" + choice.text
				#why do I need to use a custom signal for this? why can't I just connect to the button's signal instead?
				choice_button.connect("pressed", self, "update_ui", [choice.index], CONNECT_ONESHOT)
				game_buttons.add_child(choice_button)
		else:
			var choice_button = ChoiceButton.instance()
			choice_button.get_child(0).bbcode_text = "\n\t" + "[color=#ff6680]RESET[/color]"
			choice_button.connect("pressed", self, "update_ui", [-1], CONNECT_ONESHOT) 
			game_buttons.add_child(choice_button)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()

var story : Array = [
	{ 	"index": 0
	,  	"text": "You wake in a forest."
	,  	"choices": [
			{	"index": 1
			,	"text": "Walk north"
			}
		,
			{	"index": 2
			,	"text": "Make a fire"
			}
		]
	}
,
	{ 	"index": 1
	,  	"text": "You walk north and fall in a hole and break your legs. You die hours later."
	,  	"choices": [
		]
	}
,
	{ 	"index": 2
	,  	"text": "You make a fire and the glow illuminates a shadowy figure in the trees. Your breath is suddenly sucked away and you die of suffocation."
	,  	"choices": [
		]
	}
]
