class_name BarMission
extends RefCounted

enum State { AVAILABLE, ACTIVE, READY, COMPLETE }
const GOAL: int = 3
const REWARD: int = 25
var state: State = State.AVAILABLE
var wins: int = 0

func accept() -> bool:
	if state != State.AVAILABLE:
		return false
	state = State.ACTIVE
	return true

func record_win() -> void:
	if state != State.ACTIVE:
		return
	wins = mini(wins + 1, GOAL)
	if wins == GOAL:
		state = State.READY

func claim(inventory: PlayerInventory) -> bool:
	if state != State.READY:
		return false
	state = State.COMPLETE
	inventory.add_cash(REWARD)
	return true

func summary() -> String:
	match state:
		State.ACTIVE: return "STREET BUSINESS  %d / %d WINS" % [wins, GOAL]
		State.READY: return "RETURN TO THE BAR  /  $25 REWARD"
		State.COMPLETE: return "STREET BUSINESS  /  COMPLETE"
	return "FIND WORK AT THE LAST LIGHT BAR"
