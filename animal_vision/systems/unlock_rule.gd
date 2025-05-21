# systems/unlock_rule.gd
class_name UnlockRule
extends Resource

@export var rule_id: String = "" # Optional: for easier identification of the rule itself
@export var predator_animal_id: String = "" # Animal ID of the attacker
@export var prey_animal_id: String = ""   # Animal ID of the animal that was successfully preyed upon
@export var unlocks_animal_id: String = "" # Animal ID that gets unlocked as a result

func _init(p_rule_id: String = "", p_predator: String = "", p_prey: String = "", p_unlocks: String = ""):
    rule_id = p_rule_id
    predator_animal_id = p_predator
    prey_animal_id = p_prey
    unlocks_animal_id = p_unlocks

func is_valid() -> bool:
    return not predator_animal_id.is_empty() and \
           not prey_animal_id.is_empty() and \
           not unlocks_animal_id.is_empty()
