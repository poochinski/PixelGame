class_name PlayerInventory
extends Node

signal cash_added(amount: int, total: int)
signal changed

var _cash: int = 0
var bandages: int = 0
const BANDAGE_PRICE: int = 5
const BANDAGE_LIMIT: int = 9
var cash: int:
	get: return _cash

func add_cash(amount: int) -> bool:
	if amount <= 0:
		return false
	_cash += amount
	cash_added.emit(amount, _cash)
	changed.emit()
	return true

func spend_cash(amount: int) -> bool:
	if amount <= 0 or _cash < amount:
		return false
	_cash -= amount
	changed.emit()
	return true

func buy_bandage() -> bool:
	if bandages >= BANDAGE_LIMIT or _cash < BANDAGE_PRICE:
		return false
	_cash -= BANDAGE_PRICE
	bandages += 1
	changed.emit()
	return true

func use_bandage(health: HealthComponent) -> bool:
	if bandages <= 0 or health.dead or health.current >= health.maximum:
		return false
	bandages -= 1
	health.heal(30.0)
	changed.emit()
	return true
