# player/abilities/sprint_ability.gd
class_name SprintAbility
extends AbilityBase

@export var sprint_speed_multiplier: float = 1.8
@export var sprint_duration: float = 3.0 # Relevant if INSTANT with a timed effect, or for SUSTAINED

var original_speed: float = 0.0
var sprint_timer: float = 0.0

# For this example, let's treat it as an INSTANT ability that has a timed effect.
# A SUSTAINED ability would require holding down a button and continuously drain stamina.
# The design doc example "temporary提高 casterController 的移动速度 X%，持续 Y 秒" fits an instant activation with a duration.

func _init():
    # Default values for a sprint ability
    ability_id = "sprint_01"
    display_name = "Sprint"
    description = "Temporarily increases movement speed."
    stamina_cost = 20.0
    cooldown = 5.0
    duration_type = Globals.AbilityDurationType.INSTANT # Or SUSTAINED if it's a toggle/hold

func _on_execute(p_caster_controller):
    # Assuming p_caster_controller is PlayerAnimalController which has current_animal_data
    # and current_animal_data has base_stats.base_move_speed.
    # A more direct approach would be if p_caster_controller itself has a speed property
    # or a reference to a CharacterBody3D/2D node.
    
    # Placeholder: how to get and set speed depends on PlayerAnimalController's final structure
    # or if it directly controls a CharacterBody.
    # For now, let's assume PlayerAnimalController has a method or property for speed.
    
    # This ability is more complex if it directly modifies stats on AnimalData.
    # It's better if PlayerAnimalController exposes a way to get/set current move speed.
    # Or, the ability could emit a signal that a movement component listens to.

    if p_caster_controller and p_caster_controller.has_method("get_current_move_speed") and p_caster_controller.has_method("set_current_move_speed"):
        original_speed = p_caster_controller.get_current_move_speed()
        p_caster_controller.set_current_move_speed(original_speed * sprint_speed_multiplier)
        sprint_timer = sprint_duration
        is_active = true # Use is_active to signify the effect is ongoing
        print("%s: Speed increased to %s" % [display_name, original_speed * sprint_speed_multiplier])
    else:
        printerr("%s: Caster controller does not support speed modification methods needed for sprint." % display_name)
        # If execute was called, stamina is already consumed. This ability would fail to apply its effect.
        # To prevent stamina consumption on effect failure, move super().execute() call to after effect check.
        # For now, keeping it simple as per AbilityBase structure.


func _on_tick(delta_time: float, p_caster_controller):
    if is_active: # 'is_active' here means the sprint effect is ongoing
        sprint_timer -= delta_time
        if sprint_timer <= 0:
            deactivate(p_caster_controller)

func _on_deactivate(p_caster_controller):
    if p_caster_controller and p_caster_controller.has_method("set_current_move_speed"):
        p_caster_controller.set_current_move_speed(original_speed)
        print("%s: Speed restored to %s" % [display_name, original_speed])
    else:
        printerr("%s: Caster controller does not support speed modification methods for deactivation." % display_name)
    is_active = false # Ensure is_active is false for the effect itself
    # Note: AbilityBase.deactivate() already sets self.is_active = false if it was a SUSTAINED ability.
    # Here, for an INSTANT ability with a timed effect, we manage an internal 'active' state for the effect.
```
