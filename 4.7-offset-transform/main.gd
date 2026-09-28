extends Control

@onready var hand: HBoxContainer = $Hand
@onready var btn_add: Button = $BtnAdd
@onready var btn_remove: Button = $BtnRemove

func _ready() -> void:
	# 连接按钮的 pressed 信号到对应函数
	btn_add.pressed.connect(_on_btn_add_pressed)
	btn_remove.pressed.connect(_on_btn_remove_pressed)

# "加一张手牌"按钮回调
func _on_btn_add_pressed() -> void:
	hand.add_test_card()

# "删一张手牌"按钮回调
func _on_btn_remove_pressed() -> void:
	hand.remove_last_card()
