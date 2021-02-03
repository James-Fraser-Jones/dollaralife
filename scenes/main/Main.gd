extends Control

export var story_name : String = "example"
export var start_index : int = 0

const ChoiceButton = preload("res://scenes/choice_button/ChoiceButton.tscn")

var game_log : RichTextLabel
var game_log_scroll : ScrollContainer
var game_buttons : VBoxContainer
var story : Array = []

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
	
	#get first clause
	var first_clause = clauses.pop_front()
	
	if first_clause == null: #ERROR CONDITION
		print("ERROR: No clauses parsed")
		get_tree().quit()
	
	#declare vars
	var current_snippet : Dictionary = {}
	var lines : Array = first_clause.split("\n", true, 1) #split on first newline
	
	if lines[0].left(1) != "!": #ERROR CONDITION
		print("ERROR: First parsed clause is not a snippet")
		get_tree().quit()
	
	#create first snippet
	if lines[0].right(lines[0].length() - 1) == "[":
		current_snippet["index"] = int(lines[0].substr(1, lines[0].length() - 2))
		current_snippet["text"] = lines[1].substr(0, lines[1].length() - 2)
	else:
		current_snippet["index"] = int(lines[0].substr(1))
		current_snippet["text"] = lines[1]
	current_snippet["choices"] = []
	
	#transform remaining clauses
	for clause in clauses:
		lines = clause.split("\n", true, 1)
		
		if lines[0].left(1) == "!": #new snippet
			story.push_back(current_snippet)
			current_snippet = {}
			if lines[0].right(lines[0].length() - 1) == "[":
				current_snippet["index"] = int(lines[0].substr(1, lines[0].length() - 2))
				current_snippet["text"] = lines[1].substr(0, lines[1].length() - 2)
			else:
				current_snippet["index"] = int(lines[0].substr(1))
				current_snippet["text"] = lines[1]
			current_snippet["choices"] = []
			
		else: #new choice
			var choice : Dictionary = {}
			if lines[0].right(lines[0].length() - 1) == "[":
				choice["index"] = int(lines[0].substr(1, lines[0].length() - 2))
				choice["text"] = lines[1].substr(0, lines[1].length() - 2)
			else:
				choice["index"] = int(lines[0].substr(1))
				choice["text"] = lines[1]
			current_snippet["choices"].push_back(choice)
	
	#push final snippet
	story.push_back(current_snippet)
	
	#sort snippets by index to enable log time search
	story.sort_custom(SnippetUtility, "compare")
	
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
		var new_snippet : Dictionary = custom_bsearch(new_index)
		
		#add snippet text to log
		game_log.bbcode_text += new_snippet.text
		
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
				choice_button.connect("pressed", self, "update_ui", [choice["index"]], CONNECT_ONESHOT)
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
			
func custom_bsearch(target_index : int) -> Dictionary:
	var l : int = 0
	var r : int = story.size() - 1
	var m : int
	
	while l <= r:
		m = floor((l + r) / 2)
		if story[m]["index"] < target_index:
			l = m + 1
		elif story[m]["index"] > target_index:
			r = m - 1
		else:
			return story[m]
			
	print("ERROR: Failed to find snippet with index: " + str(target_index))
	get_tree().quit()
	
	return {}
	
class SnippetUtility: 
	static func compare(a, b): return a["index"] < b["index"]
