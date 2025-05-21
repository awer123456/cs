# player/abilities/ability_base.gd
class_name AbilityBase
extends Resource

@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cooldown: float = 0.0 # Time in seconds
@export var stamina_cost: float = 0.0
@export var duration_type: Globals.AbilityDurationType = Globals.AbilityDurationType.INSTANT

# Runtime state
var is_active: bool = false # For sustained abilities
var last_used_time: float = -INF # To track cooldown, -INF means ready to use
var caster_controller = null # To be set when ability is equipped/used by PlayerAnimalController or NPC

func _init(p_id: String = "", p_name: String = "", p_desc: String = ""):
    ability_id = p_id
    display_name = p_name
    description = p_desc

# Virtual methods to be overridden by specific abilities

# Check if the ability can be used (e.g., enough stamina, not on cooldown)
func can_use(p_caster_stats: PlayerSurvivalStats) -> bool:
    if not p_caster_stats:
        printerr("AbilityBase: Caster stats not provided for can_use check.")
        return false
        
    if Time.get_ticks_msec() / 1000.0 < last_used_time + cooldown:
        # print("%s is on cooldown." % display_name)
        return false
    
    if p_caster_stats.current_stamina < stamina_cost:
        # print("%s: Not enough stamina." % display_name)
        return false
        
    return true

# Called to execute the ability's logic.
# p_caster_controller is the PlayerAnimalController or NPC controller instance.
func execute(p_caster_controller):
        if not p_caster_controller or not p_caster_controller.has_node("PlayerSurvivalStats"): # Basic check
            printerr("AbilityBase: Caster controller or its PlayerSurvivalStats not valid for execute.")
        return

        var caster_stats = p_caster_controller.player_survival_stats # Assuming PlayerAnimalController structure
        if not caster_stats:
             caster_stats = p_caster_controller.get_node_or_null("PlayerSurvivalStats") # Fallback for NPCs

        if not caster_stats:
            printerr("AbilityBase: Could not retrieve caster_stats for execute.")
        return

    if can_use(caster_stats):
        caster_stats.consume_stamina(stamina_cost)
        last_used_time = Time.get_ticks_msec() / 1000.0
        
        if duration_type == Globals.AbilityDurationType.SUSTAINED:
            is_active = true
        
        # print("%s executed by %s" % [display_name, p_caster_controller.name])
        # Specific logic implemented in derived classes
        _on_execute(p_caster_controller) # Call internal execution
    else:
        # print("%s cannot be used now." % display_name)
        pass

# Internal execution logic for derived classes
func _on_execute(p_caster_controller):
    # Needs to be implemented by derived classes
    push_warning("AbilityBase._on_execute() not implemented in derived class: %s" % self.get_class())


# Called every frame for sustained abilities.
func tick(delta_time: float, p_caster_controller):
    if is_active and duration_type == Globals.AbilityDurationType.SUSTAINED:
        # print("%s ticking..." % display_name)
        # Specific logic implemented in derived classes
        _on_tick(delta_time, p_caster_controller) # Call internal tick

func _on_tick(delta_time: float, p_caster_controller):
    # Optional to be implemented by derived sustained abilities
    pass


# Called to deactivate a sustained ability or when its duration ends.
func deactivate(p_caster_controller):
    if is_active: # Only deactivate if truly active (relevant for SUSTAINED)
        is_active = false # Set before calling _on_deactivate for consistency
        # print("%s deactivated." % display_name)
        # Specific logic implemented in derived classes
        _on_deactivate(p_caster_controller) # Call internal deactivation

func _on_deactivate(p_caster_controller):
    # Optional to be implemented by derived sustained abilities
    pass
    
func set_caster(p_caster_controller):
    caster_controller = p_caster_controller
