# ui/hud_controller.gd
class_name HUDController
extends Control # Base class for UI elements in Godot

# --- Exported Node Paths for UI Elements ---
# Assign these in the Godot editor
@export var health_bar: ProgressBar
@export var stamina_bar: ProgressBar
@export var hunger_bar: ProgressBar
@export var thirst_bar: ProgressBar # Optional, as per design

@export var current_animal_icon: TextureRect
# Placeholder for ability icons - could be an array or HBoxContainer of TextureRects
# @export var ability_icons_container: HBoxContainer 

# --- Controller References ---
# Assign these in the editor or find them in _ready
@export var player_survival_stats: PlayerSurvivalStats
@export var player_animal_controller: PlayerAnimalController


func _ready():
    # --- Validate Node Assignments & Connect Signals ---
    if not player_survival_stats:
        # Try to find it, e.g., if it's a globally accessible node or in a specific group
        # For example, if PlayerSurvivalStats is a child of a node named "Player":
        # player_survival_stats = get_node_or_null("/root/Game/Player/PlayerSurvivalStats") 
        var pss_nodes = get_tree().get_nodes_in_group("PlayerSurvivalStats") # Assuming it's in this group
        if pss_nodes.size() > 0:
            player_survival_stats = pss_nodes[0] as PlayerSurvivalStats
        
        if not player_survival_stats:
            printerr("HUDController: PlayerSurvivalStats node not assigned or found!")
            # Consider set_process(false) or disabling parts of HUD if stats are unavailable
    
    if player_survival_stats: # Proceed only if found/assigned
        # Connect to signals from PlayerSurvivalStats
        if player_survival_stats.has_signal("health_updated"):
            player_survival_stats.health_updated.connect(_on_health_updated)
        if player_survival_stats.has_signal("stamina_updated"):
            player_survival_stats.stamina_updated.connect(_on_stamina_updated)
        if player_survival_stats.has_signal("hunger_updated"):
            player_survival_stats.hunger_updated.connect(_on_hunger_updated)
        if thirst_bar and player_survival_stats.has_signal("thirst_updated"): # Optional
            player_survival_stats.thirst_updated.connect(_on_thirst_updated)
        
        # Initialize HUD with current stat values
        if player_survival_stats.current_animal_data: # If stats were initialized with animal data
            _on_health_updated(player_survival_stats.current_health, player_survival_stats.current_animal_data.base_stats.max_health)
            _on_stamina_updated(player_survival_stats.current_stamina, player_survival_stats.current_animal_data.base_stats.stamina_max)
            _on_hunger_updated(player_survival_stats.current_hunger, player_survival_stats.current_animal_data.base_stats.hunger_max)
            if thirst_bar and player_survival_stats.current_animal_data.base_stats.thirst_max > 0 : # Check if thirst is relevant
                 _on_thirst_updated(player_survival_stats.current_thirst, player_survival_stats.current_animal_data.base_stats.thirst_max)
            elif thirst_bar:
                 thirst_bar.visible = false
        else: # Default initialization if no animal data yet on stats component
             _on_health_updated(player_survival_stats.current_health, 100.0) # Assuming 100 as default max
             _on_stamina_updated(player_survival_stats.current_stamina, 100.0)
             _on_hunger_updated(player_survival_stats.current_hunger, 100.0)
             if thirst_bar: _on_thirst_updated(player_survival_stats.current_thirst, 100.0) # Default if no data


    if not player_animal_controller:
        # player_animal_controller = get_tree().get_first_node_in_group("PlayerAnimalController")
        var pac_nodes = get_tree().get_nodes_in_group("PlayerAnimalController") # Assuming it's in this group
        if pac_nodes.size() > 0:
            player_animal_controller = pac_nodes[0] as PlayerAnimalController

        if not player_animal_controller:
            printerr("HUDController: PlayerAnimalController node not assigned or found!")

    if player_animal_controller: # Proceed only if found/assigned
        if player_animal_controller.has_signal("animal_form_switched"):
            player_animal_controller.animal_form_switched.connect(_on_animal_form_switched)
        # Initialize with current animal data if available
        if player_animal_controller.current_animal_data:
            _on_animal_form_switched(player_animal_controller.current_animal_data)

    # Hide optional thirst bar if not configured or not relevant initially
    if not thirst_bar:
        print("HUDController: Thirst bar not assigned, thirst display will be skipped.")
    # Further check for thirst_max on animal switch is in _on_animal_form_switched and _on_thirst_updated


# --- Signal Callbacks from PlayerSurvivalStats ---
func _on_health_updated(new_value: float, max_value: float):
    if health_bar:
        health_bar.max_value = max_value
        health_bar.value = new_value
        # Optional: Update text label for health, e.g., health_bar.get_node("Label").text = "%d/%d" % [new_value, max_value]

func _on_stamina_updated(new_value: float, max_value: float):
    if stamina_bar:
        stamina_bar.max_value = max_value
        stamina_bar.value = new_value

func _on_hunger_updated(new_value: float, max_value: float):
    if hunger_bar:
        hunger_bar.max_value = max_value
        hunger_bar.value = new_value

func _on_thirst_updated(new_value: float, max_value: float):
    if thirst_bar:
        if max_value <= 0: # Animal might not have thirst
            thirst_bar.visible = false
            return
        thirst_bar.visible = true
        thirst_bar.max_value = max_value
        thirst_bar.value = new_value


# --- Signal Callback from PlayerAnimalController ---
func _on_animal_form_switched(new_animal_data: AnimalData):
    if not new_animal_data:
        printerr("HUDController: Received null animal data on form switch.")
        if current_animal_icon: current_animal_icon.texture = null # Clear icon
        return

    print("HUDController: Animal form switched to %s. Updating HUD." % new_animal_data.display_name)
    
    # Update Animal Icon
    if current_animal_icon:
        # Assuming AnimalData might get an icon_path field.
        # This is a deviation from the specified AnimalData structure but common for UI.
        # If AnimalData doesn't have 'icon_path', this will gracefully do nothing or clear.
        if new_animal_data.has_method("get_icon_path"): # Check for a getter method first
            var icon_path = new_animal_data.get_icon_path()
            if not icon_path.is_empty():
                var icon_tex = load(icon_path)
                if icon_tex:
                    current_animal_icon.texture = icon_tex
                else:
                    printerr("HUDController: Failed to load animal icon from: %s" % icon_path)
                    current_animal_icon.texture = null 
            else: current_animal_icon.texture = null # Clear if path is empty
        elif new_animal_data.has("icon_path") and typeof(new_animal_data.icon_path) == TYPE_STRING and not new_animal_data.icon_path.is_empty(): # Direct property access
            var icon_tex = load(new_animal_data.icon_path)
            if icon_tex:
                current_animal_icon.texture = icon_tex
            else:
                printerr("HUDController: Failed to load animal icon from: %s" % new_animal_data.icon_path)
                current_animal_icon.texture = null
        else:
            # print("HUDController: No icon_path specified or found in AnimalData for %s." % new_animal_data.display_name)
            current_animal_icon.texture = null # Clear icon or set default

    # Update Ability Icons (Placeholder)
    # print("HUDController: Updating ability icons for abilities: %s" % str(new_animal_data.ability_ids))
    # if ability_icons_container:
    #    for child in ability_icons_container.get_children(): child.queue_free() # Clear old icons
    #    # Logic to load and display ability icons based on new_animal_data.ability_ids
    #    # This would require an AbilityRepository or similar system to get AbilityBase resources by ID,
    #    # and AbilityBase would need an icon_path property.
    #    pass 

    # Update visibility of thirst bar based on new animal's stats
    if thirst_bar: # Check if thirst_bar node is assigned
        if new_animal_data.base_stats and new_animal_data.base_stats.thirst_max > 0:
            thirst_bar.visible = true
            # Values will be updated by _on_thirst_updated when PlayerSurvivalStats reinitializes
            # and emits its signals. We can also force an update here if needed.
            if player_survival_stats: # Ensure player_survival_stats is valid
                 _on_thirst_updated(player_survival_stats.current_thirst, new_animal_data.base_stats.thirst_max)
        else:
            thirst_bar.visible = false
```
