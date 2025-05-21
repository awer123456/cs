# player/player_survival_stats.gd
class_name PlayerSurvivalStats
extends Node

# Properties
var current_health: float = 100.0
var current_stamina: float = 100.0
var current_hunger: float = 100.0
var current_thirst: float = 100.0 # Optional, as per doc

# Reference to the current animal's static data
# This should be set by PlayerAnimalController when the animal form changes.
var current_animal_data: AnimalData = null 

# Signals for when stats change, useful for UI updates
signal health_updated(new_health, max_health)
signal stamina_updated(new_stamina, max_stamina)
signal hunger_updated(new_hunger, max_hunger)
signal thirst_updated(new_thirst, max_thirst) # Optional

func _ready():
    # Initialize stats based on animal data if available,
    # otherwise use default values and wait for animal_data to be set.
    if current_animal_data:
        initialize_stats()
    else:
        # Emit initial signals with default values if no animal data yet
        # Assuming default max if no data. These values will be updated once animal_data is set.
        emit_signal("health_updated", current_health, 100.0) 
        emit_signal("stamina_updated", current_stamina, 100.0)
        emit_signal("hunger_updated", current_hunger, 100.0)
        emit_signal("thirst_updated", current_thirst, 100.0)


func initialize_stats():
    if not current_animal_data:
        printerr("PlayerSurvivalStats: AnimalData not set, cannot initialize stats.")
        return

    current_health = current_animal_data.base_stats.max_health
    current_stamina = current_animal_data.base_stats.stamina_max
    current_hunger = current_animal_data.base_stats.hunger_max
    current_thirst = current_animal_data.base_stats.thirst_max # If used

    emit_signal("health_updated", current_health, current_animal_data.base_stats.max_health)
    emit_signal("stamina_updated", current_stamina, current_animal_data.base_stats.stamina_max)
    emit_signal("hunger_updated", current_hunger, current_animal_data.base_stats.hunger_max)
    emit_signal("thirst_updated", current_thirst, current_animal_data.base_stats.thirst_max)


func set_animal_data(new_animal_data: AnimalData):
    if new_animal_data == null:
        printerr("PlayerSurvivalStats: Attempted to set null AnimalData.")
        return
    current_animal_data = new_animal_data
    initialize_stats()


# Methods
func take_damage(amount: float):
    if not current_animal_data: 
        # If there's no animal data, we can't determine max health. 
        # Defaulting to current_health - amount or simple current_health = max(0, current_health - amount)
        current_health = max(0, current_health - amount)
        emit_signal("health_updated", current_health, current_health + amount) # Estimate max_health
        if current_health == 0:
            print("Player has died (No AnimalData).") # Placeholder
        return

    current_health = max(0, current_health - amount)
    emit_signal("health_updated", current_health, current_animal_data.base_stats.max_health)
    if current_health == 0:
        # Handle player death logic here or emit a signal
        print("Player has died.") # Placeholder

func heal(amount: float):
    if not current_animal_data: 
        # If no animal data, heal up to an arbitrary cap or just add amount.
        # For consistency, let's assume if there's no animal_data, there's a default max_health (e.g. 100)
        # or simply don't allow healing beyond a certain point if stats aren't initialized.
        # current_health = min(100.0, current_health + amount) # Assuming a default max_health if no animal_data
        # emit_signal("health_updated", current_health, 100.0)
        return # Or, print an error: printerr("Cannot heal: AnimalData not set.")


    current_health = min(current_animal_data.base_stats.max_health, current_health + amount)
    emit_signal("health_updated", current_health, current_animal_data.base_stats.max_health)

# deltaTime is the time elapsed since the last frame (from _process or _physics_process)
func update_stats(delta_time: float):
    if not current_animal_data:
        # printerr("PlayerSurvivalStats: No animal data, skipping stats update.")
        return

    # Hunger update
    var previous_hunger = current_hunger
    if current_animal_data.hunger_rate_multiplier > 0: # Check if animal gets hungry
        current_hunger -= current_animal_data.hunger_rate_multiplier * delta_time
        current_hunger = max(0, current_hunger)

    if previous_hunger != current_hunger: # Only emit if changed
         emit_signal("hunger_updated", current_hunger, current_animal_data.base_stats.hunger_max)

    if current_hunger == 0:
        # Per document: "if hunger value降到0，则每秒减少 health 5点"
        take_damage(5.0 * delta_time) 
        
    # Thirst update (Optional, if thirst_max > 0 in animal_data.base_stats)
    # Assuming a thirst_rate_multiplier similar to hunger_rate_multiplier if this feature is used.
    # For now, this part is not explicitly in the document for update_stats, only for feed.
    # if current_animal_data.base_stats.thirst_max > 0:
    #    var previous_thirst = current_thirst
    #    # Assume a hypothetical current_animal_data.thirst_rate_multiplier
    #    # current_thirst -= (current_animal_data.thirst_rate_multiplier_if_it_existed * delta_time)
    #    current_thirst = max(0, current_thirst)
    #    if previous_thirst != current_thirst:
    #        emit_signal("thirst_updated", current_thirst, current_animal_data.base_stats.thirst_max)
    #    if current_thirst == 0:
    #        take_damage(some_thirst_damage_rate * delta_time) # Example if thirst causes damage

    # Passive stamina regeneration can be handled here if desired.
    # For example: restore_stamina(passive_stamina_regen_rate * delta_time)
    # However, the document implies stamina is managed by abilities.
    pass


func consume_stamina(amount: float) -> bool:
    if not current_animal_data: return false

    if current_stamina >= amount:
        current_stamina -= amount
        emit_signal("stamina_updated", current_stamina, current_animal_data.base_stats.stamina_max)
        return true
    return false

func restore_stamina(amount: float):
    if not current_animal_data: return

    current_stamina = min(current_animal_data.base_stats.stamina_max, current_stamina + amount)
    emit_signal("stamina_updated", current_stamina, current_animal_data.base_stats.stamina_max)

func feed(hunger_restore: float, thirst_restore: float = 0.0): 
    if not current_animal_data: return

    current_hunger = min(current_animal_data.base_stats.hunger_max, current_hunger + hunger_restore)
    emit_signal("hunger_updated", current_hunger, current_animal_data.base_stats.hunger_max)

    # Only affect thirst if the animal has a thirst stat (thirst_max > 0)
    if current_animal_data.base_stats.thirst_max > 0: 
        current_thirst = min(current_animal_data.base_stats.thirst_max, current_thirst + thirst_restore)
        emit_signal("thirst_updated", current_thirst, current_animal_data.base_stats.thirst_max)

```
