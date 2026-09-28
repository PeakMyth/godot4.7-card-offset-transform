extends HBoxContainer

# ⭐ 换成你自己的卡牌场景路径
const CARD_SCENE := preload("res://card.tscn")

# 宽度自适应参数
var card_width_max := 125      # 卡牌最大宽度（牌少时）
var card_width_min := 25      # 卡牌最小宽度（牌多时，低于此值就该缩间距了）
var card_width_normal := 100   # 默认宽度 （可能用不上）

func _ready() -> void:
	reflow_cards()

# 重排所有卡牌的扇形角度
func reflow_cards() -> void:
	if get_child_count() == 0:
		return
	
	# 收集所有有效卡牌
	var valid_cards := []
	# 遍历所有卡牌节点
	for card in get_children():
		valid_cards.append(card)
	
	# 有效卡牌数量
	var valid_count: int = valid_cards.size()
	# 计算好的卡牌最小尺寸
	var target_card_width =  reflow_separation(valid_count)
	
	# 设置卡牌宽度与角度
	for card in get_children():
		if card.has_method("set_card_width"):
			card.set_card_width(target_card_width)
		if card.has_method("angle_card"):
			card.angle_card()

# 计算自适应的卡牌宽度
func reflow_separation(valid_count: int) -> float:
	# 计算自适应的卡牌宽度
	var target_card_width: float
	
	if valid_count <= 3:
		# 只有一张牌或者牌数量少 → 用最大宽度（最散）
		target_card_width = card_width_max
	
	elif valid_count > 3 and valid_count <= 10:
		target_card_width = -3 * valid_count + 110
	elif valid_count > 10 and valid_count <= 15:
		target_card_width = -4 * valid_count + 100
	elif valid_count > 15 and valid_count <= 19:
		target_card_width = 40
	elif valid_count >= 20 and valid_count <= 25:
		target_card_width = 30
	elif valid_count > 25 and valid_count <= 30:
		target_card_width = card_width_min
	else:
		target_card_width = card_width_min
	
	return target_card_width

# 加一张卡牌（供按钮调用）
func add_test_card() -> void:
	# 实例化一张新卡牌
	var card = CARD_SCENE.instantiate()
	# 加入容器 → HBoxContainer 会自动排好 x 位置
	add_child(card)
	# 等一帧，确保 get_index() 正确后再重排扇形
	await get_tree().process_frame
	reflow_cards()

# 删最后一张卡牌（供按钮调用）
func remove_last_card() -> void:
	# 拿到所有子节点
	var children := get_children()
	if children.is_empty():
		return  # 没牌可删
	
	# 取最后一张
	var last_card = children[-1]
	# 播放退场动画（destroy 里最后会 queue_free）
	if last_card.has_method("destroy"):
		last_card.destroy()
	
	# 等退场动画跑起来后再重排剩下的牌
	# 用 0.2 秒和 destroy 动画时长对齐
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	reflow_cards()
