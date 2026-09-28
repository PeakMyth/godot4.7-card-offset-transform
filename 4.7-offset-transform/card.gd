extends Control

#  动画用到的 Tween 对象 
var tween_rotation: Tween   # 扇形角度补间
var tween_hover: Tween      # 悬停动画
var tween_appear: Tween     # 进场/退场动画
var tween_width: Tween      # 宽度动画

#  可调用参数 
var default_minimum := 50         # 这张牌在当前扇形中的目标最小x尺寸
var min_size_x_hover := 200       # 悬停时卡牌最小宽度
var angle_min := -15.0            # 扇形左边缘角度（度） （不一定用的上）
var angle_max := 15.0             # 扇形右边缘角度（度）
var default_rot := 0.0            # 这张牌在当前扇形中的目标角度（弧度）

@onready var panel: Panel = $Panel

func _ready() -> void:
	# ⭐ 开启 offset transform
	offset_transform_enabled = true
	# 旋转/缩放的轴心：x=0.5 中心，y=1.0 底部 → 卡牌绕"底部中心"旋转，扇形更自然
	offset_transform_pivot_ratio = Vector2(0.5, 0.5)
	# 不仅视觉偏移，鼠标点击响应区域也跟随改变
	offset_transform_visual_only = false
	
	# 连接鼠标进入信号
	panel.mouse_entered.connect(hover)
	# 连接鼠标离开信号
	panel.mouse_exited.connect(unhover)
	
	
	
	tween_ready()

# 计算这张牌的扇形角度
func angle_card() -> void:
	# 首先计算有多少张牌，去拿到这张牌在手牌中排在哪
	var parent = get_parent()
	if not parent:
		return
	
	# 手牌数量
	var child_count: int = parent.get_child_count()
	# 节点在其同级节点中的索引
	var my_index: int = get_index()
	
	# 只有一张牌 → 角度为 0（正中）
	if child_count <= 1:
		default_rot = 0.0
	else:
		# 把索引映射到 [-1, 1]：中间牌是 0，两边分别是 -1 和 1
		var t := float(my_index) / float(child_count - 1) * 2.0 - 1.0
		# 这张牌的角度就是 ———— 比例乘以最大角度得到弧度
		default_rot = deg_to_rad(t * angle_max)
	
	# 如果上一个角度补间还在跑，先删掉
	if tween_rotation and tween_rotation.is_running():
		tween_rotation.kill()
	
	# 补间到目标角度
	tween_rotation = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_rotation.tween_property(self, "offset_transform_rotation", default_rot, 0.1)

# 鼠标悬停：放大 + 摆正 + 上浮 + 变宽
func hover() -> void:
	z_index = 1  # 提到最上层
	# 如果上一个补间动画还在跑，先删掉
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_hover.set_parallel(true) # 多个属性同时补间动画
	tween_hover.tween_property(self, "offset_transform_scale", Vector2(1.2, 1.2), 0.1)          # 放大到 1.2 倍
	tween_hover.tween_property(self, "offset_transform_rotation", 0.0, 0.1)                     # 角度归零（摆正）
	tween_hover.tween_property(self, "offset_transform_position_ratio:y", -0.5, 0.15)           # Y轴向上浮起
	tween_hover.tween_property(self, "custom_minimum_size:x", min_size_x_hover, 0.2)            # 宽度变宽，给其它牌挤到旁边去

# 鼠标离开：恢复
func unhover() -> void:
	z_index = 0 # 恢复到原层
	# 如果上一个补间动画还在跑，先删掉
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween_hover.set_parallel(true) # 多个属性同时补间动画
	tween_hover.tween_property(self, "offset_transform_scale", Vector2(1.0, 1.0), 0.2)          # 缩放回 1.0
	tween_hover.tween_property(self, "offset_transform_rotation", default_rot, 0.2)             # 回到原来扇形角度
	tween_hover.tween_property(self, "offset_transform_position_ratio:y", 0.0, 0.25)           # 回到原位
	tween_hover.tween_property(self, "custom_minimum_size:x", default_minimum, 0.2)          # 宽度恢复

# 卡牌进入手牌时的动画
func tween_ready() -> void:
	# 初始状态：在下方 2 倍自身高度的位置（准备滑入）
	offset_transform_position_ratio = Vector2(0.0, 2.0)
	
	# 创建进场 Tween：缓动 Cubic + EaseOut
	tween_appear = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# 宽度从当前值补间到默认宽度（让 HBoxContainer 把它"挤"出来）
	tween_appear.tween_property(self, "custom_minimum_size:x", default_minimum, 0.25)
	# 同时：y 方向偏移从 2.0 回到 0（滑入）
	tween_appear.parallel().tween_property(self, "offset_transform_position_ratio:y", 0.0, 0.2)
	angle_card()

# 卡牌销毁（退场动画）
func destroy() -> void:
	# 如果上一个补间动画还在跑，先删掉
	if tween_appear and tween_appear.is_running():
		tween_appear.kill()
	
	tween_appear = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	# 宽度补间到 0（HBoxContainer 会把它收走）
	tween_appear.tween_property(self, "custom_minimum_size:x", 0.0, 0.2)
	# 同时向下方滑出
	tween_appear.parallel().tween_property(self, "offset_transform_position_ratio:y", 1.0, 0.2)
	
	# 动画结束后销毁节点
	tween_appear.finished.connect(queue_free)

# 根据手牌数量设置最小x尺寸
func set_card_width(target_width: float) -> void:
	default_minimum = target_width
	
	# 如果上一个宽度补间还在跑，先删掉
	if tween_width and tween_width.is_running():
		tween_width.kill()
	
	# 创建补间，平滑过渡到目标宽度
	tween_width = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween_width.tween_property(self, "custom_minimum_size:x", target_width, 0.2)
