# systems/predation_system.gd
class_name PredationSystem
extends Node

@export var player_animal_controller: PlayerAnimalController
@export var unlock_rules: Array[UnlockRule] = [] # Assign UnlockRule .tres files here in the editor

func _ready():
    if not player_animal_controller:
        # Try to find it if not set, assuming a common scene structure
        var pac_nodes = get_tree().get_nodes_in_group("PlayerAnimalController") # Example group
        if pac_nodes.size() > 0:
            player_animal_controller = pac_nodes[0] as PlayerAnimalController # Take the first one

        if not player_animal_controller:
             # Or search by type if PlayerAnimalController is unique and added to scene root or similar known location
            var root_node = get_tree().root
            for child_idx in root_node.get_child_count():
                var child = root_node.get_child(child_idx)
                if child is PlayerAnimalController: # Check type directly
                    player_animal_controller = child
                    break
        if not player_animal_controller:
            printerr("PredationSystem: PlayerAnimalController not assigned or found!")

    # Validate rules on load (optional)
    for i in range(unlock_rules.size() - 1, -1, -1): # Iterate backwards for safe removal
        var rule = unlock_rules[i]
        if not rule or not rule.is_valid():
            printerr("PredationSystem: Invalid or null UnlockRule at index %s. Removing." % i)
            unlock_rules.remove_at(i)
        else:
            print("PredationSystem: Loaded valid unlock rule: Predator '%s' eats '%s' -> Unlocks '%s'" % [rule.predator_animal_id, rule.prey_animal_id, rule.unlocks_animal_id])


# Call this method when the player (as predator) successfully preys on an NPC
# predator_id is the animal_id of the player's current form
# prey_id is the animal_id of the NPC that was eaten
func process_predation_event(predator_id: String, prey_id: String):
    if not player_animal_controller:
        printerr("PredationSystem: Cannot process event, PlayerAnimalController is not set.")
        return

    print("PredationSystem: Processing predation event. Predator: %s, Prey: %s" % [predator_id, prey_id])

    for rule in unlock_rules:
        if not rule or not rule.is_valid(): # Should have been caught in _ready, but good practice
            continue

        if rule.predator_animal_id == predator_id and rule.prey_animal_id == prey_id:
            print("  Match found! Rule: %s eats %s, unlocks %s." % [rule.predator_animal_id, rule.prey_animal_id, rule.unlocks_animal_id])
            # Check if the form to be unlocked is already unlocked
            if not player_animal_controller.unlocked_animal_ids.has(rule.unlocks_animal_id):
                player_animal_controller.unlock_form(rule.unlocks_animal_id)
                # Optionally, provide feedback to the player (e.g., via a signal for UI)
                print("  '%s' unlocked!" % rule.unlocks_animal_id)
                # emit_signal("form_unlocked_via_predation", rule.unlocks_animal_id)
            else:
                print("  '%s' was already unlocked." % rule.unlocks_animal_id)
            # Depending on design, a rule might only trigger once, or unlock something else.
            # For now, it just ensures the form is unlocked.

# Helper to add rules programmatically if needed
func add_unlock_rule(rule: UnlockRule):
    if rule and rule.is_valid():
        unlock_rules.append(rule)
    else:
        printerr("PredationSystem: Attempted to add an invalid or null unlock rule.")
```
