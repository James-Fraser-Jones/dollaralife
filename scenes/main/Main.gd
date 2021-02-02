extends Control

export var story_name : String = "example"
export var start_index : int = 0

const ChoiceButton = preload("res://scenes/choice_button/ChoiceButton.tscn")

var game_log : RichTextLabel
var game_log_scroll : ScrollContainer
var game_buttons : VBoxContainer

func _ready():
	#set aliases
	game_log_scroll = $PanelContainer/MarginContainer/VSplitContainer/MarginContainer/PanelContainer/GameLogScroll
	game_log = $PanelContainer/MarginContainer/VSplitContainer/MarginContainer/PanelContainer/GameLogScroll/GameLog
	game_buttons = $PanelContainer/MarginContainer/VSplitContainer/ScrollContainer/GameButtons
	
	#read file
	var file : File = File.new()
	file.open("res://stories/" + story_name + ".txt", file.READ)
	var story_text : String = file.get_as_text()
	file.close()
	
	#parse file into clauses
	var regex : RegEx = RegEx.new()
	var reg_string : String = "[!?]\\d+(\\[\\n[\\s\\S]*?\\n\\]|\\n[^\\n]*)" #backslashes have to be escaped
	regex.compile(reg_string)
	var clauses : Array = []
	for clause in regex.search_all(story_text):
		clauses.push_back(clause.get_string())
	
	#for clause in clauses:
	#	print("Clause:")
	#	print(clause)
	#	print("End Clause:")
	
	#var hmm : Dictionary = {
	#	"new_snippet" : true 	#whether first character is ! or ?
	#,	"index" : 0 			#what the number is
	#,	"text" : "Hello world!" #either next line or everything after first newline minus last 2 characters (a newline and closing brace)
	#}
	
	#split on first newline
	#check first character to determine whether snippet or choice
	#check last character to determine whether short or long
	#retrieve number (ignoring last character if necessary)
	#if short, text is rest of content
	#if long, text is rest of content ignoring last two chars
	
	#transform clauses into array of dictionaries
	var story : Array = []
	var current_snippet : Dictionary = {
		"index": 0
	,  	"text": ""
	,  	"choices": []
	}
	for clause in clauses:
		var lines : Array = clause.split("\n", true, 1) #split on first newline
	
	#start game
	update_ui(start_index)
	
func update_ui(new_index):
	if new_index == -1:
		game_log.bbcode_text = ""
		update_ui(start_index)
	else:
		#add divider to log
		game_log.bbcode_text += "\n\n[color=#ff6680]-------------------[/color]\n\n"
		
		#find new snippet
		var new_snippet : Dictionary
		for snippet in story:
			if snippet.index == new_index: #linear time search is expensive
				new_snippet = snippet
				break
		
		#add snippet text to log
		game_log.bbcode_text += new_snippet.text #("\n\t" + new_snippet.text + "\n")
		
		#scroll log to bottom
		yield(get_tree(), "idle_frame")
		game_log_scroll.scroll_vertical = game_log_scroll.get_v_scrollbar().max_value
		
		#remove all current buttons
		for child in game_buttons.get_children():
			game_buttons.remove_child(child)
			child.queue_free()
		
		#add new buttons
		if new_snippet.choices.size() > 0:
			for choice in new_snippet.choices:
				var choice_button = ChoiceButton.instance()
				choice_button.get_child(0).bbcode_text = choice.text
				#why do I need to use a custom signal for this? why can't I just connect to the button's signal instead?
				choice_button.connect("pressed", self, "update_ui", [choice.index], CONNECT_ONESHOT)
				game_buttons.add_child(choice_button)
		else:
			var choice_button = ChoiceButton.instance()
			choice_button.get_child(0).bbcode_text = "[color=#ff6680]RESET[/color]"
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
	,  	"choices": []
	}
,
	{ 	"index": 2
	,  	"text": "You make a fire and the glow illuminates a shadowy figure in the trees. Your breath is suddenly sucked away."
	,  	"choices": [
			{	"index": 3
			,	"text": "Gasp for breath"
			}
		,
			{	"index": 4
			,	"text": "Accept death"
			}
		,
			{	"index": 5
			,	"text": "Cut open your windpipe"
			}
		]
	}
,	{	"index": 3
	,	"text": "You desperately gasp for breath but to no avail. You're dead within minutes."
	,	"choices": []
	}
,	{	"index": 4
	,	"text": "You decide to accept death. Game over."
	,	"choices": []
	}
,	{	"index": 5
	,	"text": "You cut open your windpipe and are able to breathe freely again. You stumble through the forest in a daze and die from blood loss several hours later."
	,	"choices": []
	}
]
