extends Control

export var story_name : String = "example"
export var start_index : int = 0

const ChoiceButton = preload("res://scenes/choice_button/ChoiceButton.tscn")
const Regex = "[!?]\\d+(\\[\\n[\\s\\S]*?\\n\\]|\\n[^\\n]*)"

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
	file.open("res://stories/" + story_name + ".story", file.READ)
	var story_text : String = file.get_as_text()
	file.close()
	
	#parse file into clauses
	var regex : RegEx = RegEx.new()
	regex.compile(Regex)
	var clauses : Array = []
	for clause in regex.search_all(story_text):
		clauses.push_back(clause.get_string())
	
	#get first clause
	var first_clause : String = clauses.pop_front()
	
	#ERROR CONDITIONS
	if first_clause == null: 
		print("ERROR: No clauses parsed")
		get_tree().quit()
	elif first_clause.left(1) != "!":
		print("ERROR: First parsed clause is not a snippet")
		get_tree().quit()
	
	#create first snippet
	var current_snippet : Dictionary = parse_clause(first_clause)
	current_snippet["choices"] = []
	
	#transform remaining clauses
	for clause in clauses:
		if clause.left(1) == "!": #new snippet
			story.push_back(current_snippet)
			current_snippet = parse_clause(clause)
			current_snippet["choices"] = []
		else: #new choice
			var choice : Dictionary = parse_clause(clause)
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
		game_log.bbcode_text += "\n[color=#ff6680]---------------------------------------------------[/color]\n\n"
		
		#find new snippet
		var new_snippet : Dictionary = custom_bsearch(new_index)
		
		#add snippet text to log
		game_log.bbcode_text += indent(new_snippet.text)
		
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
				add_button(choice["index"], choice["text"])
		else:
			add_button(-1, "[color=#ff6680]RESET[/color]")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()

#UTILITY

func indent(s : String) -> String:
	var arr : Array = s.split("\n")
	var acc : String = ""
	for sentence in arr:
		acc += "\t" + sentence + "\n"
	return acc
	
func parse_clause(clause : String) -> Dictionary:
	var lines : Array = clause.split("\n", true, 1)
	var data : Dictionary = {}
	if lines[0].right(lines[0].length() - 1) == "[":
		data["index"] = int(lines[0].substr(1, lines[0].length() - 2))
		data["text"] = lines[1].substr(0, lines[1].length() - 2)
	else:
		data["index"] = int(lines[0].substr(1))
		data["text"] = lines[1]
	return data

func add_button(index: int, text : String):
	var choice_button = ChoiceButton.instance()
	choice_button.get_child(0).bbcode_text = "\n" + indent(text)
	choice_button.connect("pressed", self, "update_ui", [index], CONNECT_ONESHOT)
	game_buttons.add_child(choice_button)

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
