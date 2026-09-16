class_name CombatPose
extends RefCounted

var aim := Vector2.RIGHT
var bat_angle: float = -1.25
var torso_angle: float = 0.0
var lean := Vector2.ZERO
var hand_offset := Vector2.ZERO
var stance: float = 0.0
var foot_drive: float = 0.0
var active: bool = false
var heavy: bool = false
var phase: int = 0
var progress: float = 0.0

static func guard(direction: Vector2) -> CombatPose:
	var pose := CombatPose.new()
	pose.aim = direction
	pose.torso_angle = direction.angle()
	var side := -1.0 if direction.x < -0.2 else 1.0
	pose.bat_angle = -PI * 0.5 + side * 0.32
	pose.hand_offset = direction * 3.0 + Vector2(side * 4.0, 1.0)
	return pose

# One presentation clock for shoulders, feet, hands and bat. Combat timings remain
# owned by MeleeController; sampling this pose never changes physics or damage.
static func swing(direction: Vector2, phase_id: int, amount: float, combo: int, is_heavy: bool, from_angle: float, from_hand: Vector2) -> CombatPose:
	var pose := guard(direction)
	pose.active = phase_id != 0
	pose.heavy = is_heavy
	pose.phase = phase_id
	pose.progress = clampf(amount, 0.0, 1.0)
	if not pose.active:
		return pose
	var sign_value := -1.0 if combo == 2 else 1.0
	var finisher := combo == 3
	var back := 1.7 if finisher else 1.15
	var through := 1.45 if finisher else 1.0
	var weight := 1.0 if is_heavy or finisher else 0.65
	var wind_angle := direction.angle() - sign_value * back
	var end_angle := direction.angle() + sign_value * through
	var wind_hand := direction.rotated(-sign_value * 1.1) * 5.0
	var end_hand := direction.rotated(sign_value * 0.6) * 8.0
	if is_heavy:
		wind_angle = -PI * 0.5 - (0.22 if direction.x >= 0 else -0.22)
		end_angle = direction.angle()
		wind_hand = Vector2(-direction.x * 2.0, -7.0)
		end_hand = direction * 9.0 + Vector2(0, 4)
	var wind_lean := -direction * (2.0 + weight) + Vector2(0, 1)
	var end_lean := direction * (2.0 + weight * 2.0) + Vector2(0, 1.0 if is_heavy else 0.0)
	var wind_twist := -sign_value * (0.35 + weight * 0.25)
	var end_twist := sign_value * (0.35 + weight * 0.35)
	var p := smoothstep(0.0, 1.0, pose.progress)
	if phase_id == 1:
		pose.bat_angle = lerp_angle(from_angle, wind_angle, p)
		pose.hand_offset = from_hand.lerp(wind_hand, p)
		pose.lean = wind_lean * p
		pose.torso_angle += wind_twist * p
		pose.stance = p * weight
	elif phase_id == 2:
		pose.bat_angle = lerp_angle(wind_angle, end_angle, p) if is_heavy else lerpf(wind_angle, end_angle, p)
		pose.hand_offset = wind_hand.lerp(end_hand, p)
		pose.lean = wind_lean.lerp(end_lean, p)
		pose.torso_angle += lerpf(wind_twist, end_twist, p)
		pose.stance = weight
		pose.foot_drive = p * weight
	else:
		# Hold the finishing shape before easing back to guard.
		var settle := smoothstep(0.18, 1.0, pose.progress)
		pose.bat_angle = lerp_angle(end_angle, pose.bat_angle, settle)
		pose.hand_offset = end_hand.lerp(pose.hand_offset, settle)
		pose.lean = end_lean * (1.0 - settle)
		pose.torso_angle += end_twist * (1.0 - settle)
		pose.stance = weight * (1.0 - settle)
		pose.foot_drive = weight * (1.0 - settle)
	return pose

