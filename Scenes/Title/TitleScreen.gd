extends Control

func _ready():
	$Menu/CenterRow/Buttons/NewGameButton.grab_focus()

func _on_NewGameButton_pressed():
	$FadeIn.show()
	$FadeIn.fade_in()

func _on_ExitButton_pressed():
	get_tree().quit()

func _on_FadeIn_fade_finished():
	var _d = get_tree().change_scene("res://Scenes/Main/MainScene.tscn")
