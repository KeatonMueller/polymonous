extends RichTextLabel

var score: int

func reset_score():
	score = 0
	update_text()

func set_score(sc: int):
	score = sc
	update_text()

func inc_score(inc: int):
	score += inc
	update_text()

func update_text():
	set_text("Score: " + str(score))