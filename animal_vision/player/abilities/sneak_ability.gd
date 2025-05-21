# player/abilities/sneak_ability.gd
class_name SneakAbility
extends AbilityBase

@export var detection_modifier: float = 0.5 # e.g., reduces detection range by 50%
@export var sneak_duration: float = 10.0 # If it's a timed effect

# Let's make this a SUSTAINED ability as an example
# (player holds button to sneak, drains stamina over time)
@export var stamina_drain_per_second: float = 2.0 # Moved to class level for @export

func _init():
    ability_id = "sneak_01"
    display_name = "Sneak"
    description = "Reduces detection probability while active."
    stamina_cost = 5.0 # Initial cost to activate
    cooldown = 2.0 # Cooldown after deactivation
    duration_type = Globals.AbilityDurationType.SUSTAINED
    # stamina_drain_per_second was previously in _init in some versions, now at class level


func _on_execute(p_caster_controller):
    # Placeholder: Apply sneak effect
    # This might involve setting a state on the caster_controller or an AI perception system.
    if p_caster_controller and p_caster_controller.has_method("set_stealth_modifier"):
        p_caster_controller.set_stealth_modifier(detection_modifier)
        print("%s: Activated. Detection modifier: %s" % [display_name, detection_modifier])
    else:
        printerr("%s: Caster controller does not support set_stealth_modifier method." % display_name)
        # If the effect cannot be applied, and this ability is SUSTAINED,
        # we should prevent it from staying active.
        # AbilityBase.execute sets is_active = true for SUSTAINED types *before* calling _on_execute.
        # So, if _on_execute fails to apply the effect, we must manually deactivate.
        if is_active: # is_active would have been set to true by AbilityBase for SUSTAINED
            is_active = false # Manually revert if effect application failed
            # This ability will now not be "active" in the sense of its effect or tick logic.
            # Cooldown and stamina cost were already applied by AbilityBase.execute.
            # A more robust system might involve _on_execute returning a bool.
            # If false, AbilityBase.execute could revert stamina/cooldown and not set is_active.


func _on_tick(delta_time: float, p_caster_controller):
    # For SUSTAINED ability, drain stamina over time
    if not p_caster_controller:
        printerr("%s: Caster controller is null in _on_tick." % display_name)
        deactivate(p_caster_controller) # Deactivate if controller is lost
        return

    var stats: PlayerSurvivalStats = null
    # Attempt to get PlayerSurvivalStats from common locations
    if p_caster_controller.has_meta("player_survival_stats_node"): # If path stored in meta
        stats = p_caster_controller.get_node_or_null(p_caster_controller.get_meta("player_survival_stats_node"))
    elif p_caster_controller.has_node("PlayerSurvivalStats"): # Direct child
        stats = p_caster_controller.get_node("PlayerSurvivalStats")
    elif p_caster_controller.has_property("player_survival_stats"): # Direct property
         if p_caster_controller.player_survival_stats is PlayerSurvivalStats:
            stats = p_caster_controller.player_survival_stats
        
    if not stats:
        printerr("%s: PlayerSurvivalStats not found on caster in _on_tick." % display_name)
        deactivate(p_caster_controller) # Deactivate if stats are missing
        return

    var stamina_to_drain = stamina_drain_per_second * delta_time
    
    if stats.current_stamina >= stamina_to_drain:
        stats.consume_stamina(stamina_to_drain) # consume_stamina already emits signal
    else:
        # Not enough stamina to sustain, deactivate
        print("%s: Not enough stamina to sustain. Deactivating." % display_name)
        deactivate(p_caster_controller)


func _on_deactivate(p_caster_controller):
    # Placeholder: Remove sneak effect
    if p_caster_controller and p_caster_controller.has_method("set_stealth_modifier"):
        p_caster_controller.set_stealth_modifier(1.0) # Reset modifier
        print("%s: Deactivated. Detection modifier reset." % display_name)
    else:
        printerr("%s: Caster controller does not support set_stealth_modifier method for deactivation." % display_name)
    # is_active is already set to false by AbilityBase.deactivate() before this is called.
```
