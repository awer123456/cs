# systems/sensory_manager.gd
class_name SensoryManager
extends Node

@export var player_animal_controller: PlayerAnimalController
@export var main_camera: Camera3D # Assign the main game camera here

# Placeholder for where SensoryProfile resources are stored/loaded from.
var sensory_profile_repository: Dictionary = {} # Example: {"RabbitVision": preload("res://path/to/rabbit_profile.tres")}

var current_sensory_profile: SensoryProfile = null

func _ready():
    if not player_animal_controller:
        printerr("SensoryManager: PlayerAnimalController not assigned!")
        # Potentially try to find it if it's a sibling or parent/child
    else:
        # Connect to the signal from PlayerAnimalController
        if player_animal_controller.has_signal("animal_form_switched"):
            player_animal_controller.animal_form_switched.connect(on_animal_form_switched)
            # Apply initial profile if an animal is already selected
            if player_animal_controller.current_animal_data:
                on_animal_form_switched(player_animal_controller.current_animal_data)
        else:
            printerr("SensoryManager: PlayerAnimalController does not have 'animal_form_switched' signal.")


    if not main_camera:
        main_camera = get_viewport().get_camera_3d()
        if not main_camera:
            printerr("SensoryManager: MainCamera not assigned and not found in viewport!")
    
    # Example: Populate repository (paths would be to SensoryProfile .tres files)
    # sensory_profile_repository["RabbitVision"] = load("res://systems/sensory_profiles/rabbit_profile.tres")
    # sensory_profile_repository["FoxVision"] = load("res://systems/sensory_profiles/fox_profile.tres")


func on_animal_form_switched(new_animal_data: AnimalData):
    if new_animal_data and new_animal_data.sensory_profile_id != "":
        print("SensoryManager: Animal form switched. Updating sensory profile to: %s" % new_animal_data.sensory_profile_id)
        update_sensory_effects(new_animal_data.sensory_profile_id)
    elif new_animal_data == null or (new_animal_data and new_animal_data.sensory_profile_id == ""): # Corrected condition
        print("SensoryManager: New animal data has no sensory profile ID or is null. Resetting to default.") # Clarified message
        apply_default_sensory_profile()


func update_sensory_effects(current_animal_profile_id: String): # Parameter name changed for clarity
    if not sensory_profile_repository.has(current_animal_profile_id):
        printerr("SensoryManager: SensoryProfile ID '%s' not found in repository." % current_animal_profile_id)
        apply_default_sensory_profile() # Apply a default or clear effects
        return

    var profile: SensoryProfile = sensory_profile_repository[current_animal_profile_id]
    if not profile:
        printerr("SensoryManager: Failed to load SensoryProfile for ID '%s'." % current_animal_profile_id)
        apply_default_sensory_profile()
        return

    current_sensory_profile = profile
    print("SensoryManager: Applying SensoryProfile: %s" % profile.profile_id)

    # 1. Apply Visual Profile
    if main_camera:
        main_camera.fov = profile.field_of_view
        print("  Set camera FOV to: %s" % profile.field_of_view)
        
        # Further visual changes: (Godot 4.x CameraAttributes example)
        # var attributes = main_camera.get_node_or_null("CameraAttributes") # Or main_camera.attributes directly in newer Godot 4
        # if attributes: attributes.saturation = profile.color_saturation
        # print("  Set camera saturation to: %s" % profile.color_saturation)
            
        if profile.post_process_shader_path != "":
            print("  Applying post-process shader: %s" % profile.post_process_shader_path)
            # Example: 
            # var shader_material = load(profile.post_process_shader_path)
            # if main_camera.has_method("get_attributes") and main_camera.get_attributes(): # Godot 4.0+
            #    main_camera.get_attributes().post_process_shader = shader_material
            # elif get_viewport().world_environment: # Godot 3.x (more complex setup)
            #    print("  Godot 3.x post-processing needs specific setup.")
            # else:
            #    print("  Cannot apply post_process_shader: No suitable API found (check Godot version/setup).")
        else:
            print("  No post-process shader specified.")
            # Clear existing post-process shader if any
            # if main_camera.has_method("get_attributes") and main_camera.get_attributes():
            #    main_camera.get_attributes().post_process_shader = null
            # elif get_viewport().world_environment:
            #    print("  Godot 3.x post-processing shader removal needs specific setup.")

    else:
        printerr("  SensoryManager: MainCamera not available to apply visual profile.")

    # 2. Apply Audio Profile (Conceptual)
    print("  Applying audio parameters (hearing range: %s, focus sounds: %s)" % [profile.hearing_range_multiplier, str(profile.focus_sounds)])
    # This would involve interacting with an AudioManager or directly with AudioStreamPlayer3D nodes,
    # potentially adjusting their attenuation or bus effects.

    # 3. Night Vision Logic (Conceptual)
    # This could involve changing global illumination, specific lights, or a shader effect.
    # var current_ambient_light = 0.5 # Need a way to get this, e.g. from WorldEnvironment
    # if current_ambient_light < profile.night_vision_threshold:
    #    print("  Activating night vision (intensity: %s)" % profile.visual_night_vision_intensity)
    #    # Activate night vision effect (e.g., shader, light changes)
    # else:
    #    print("  Deactivating night vision")
    #    # Deactivate night vision effect

func apply_default_sensory_profile():
    current_sensory_profile = null
    print("SensoryManager: Applied default sensory profile (cleared effects).")
    if main_camera:
        main_camera.fov = 75.0 # Default FOV
        # Reset other visual effects (saturation, post-processing)
        # if main_camera.has_method("get_attributes") and main_camera.get_attributes(): # Godot 4.0+
        #    attributes = main_camera.get_attributes()
        #    attributes.saturation = 1.0
        #    attributes.post_process_shader = null
        # elif get_viewport().world_environment: # Godot 3.x
        #    get_viewport().world_environment.environment.saturation = 1.0

    # Reset audio effects

func _process(_delta): # delta is implicitly available
    if current_sensory_profile and current_sensory_profile.detection_radius > 0:
        render_olfactory_cues()

func render_olfactory_cues():
    if not current_sensory_profile or current_sensory_profile.detection_radius == 0:
        return # No olfactory sense for current animal or no profile

    # Placeholder logic for displaying olfactory cues
    # This would involve:
    # 1. Finding objects in the scene with `tracked_tags` within `detection_radius`.
    #    - Iterate through relevant nodes (e.g., in a group "Smellable")
    #    - Check distance from player
    #    - Check if node has one of the current_sensory_profile.tracked_tags
    # 2. Visualizing them (e.g., particles, outlines, icons) for `trail_display_duration`.
    #    - This could be spawning temporary visual effect scenes or drawing in 2D overlay.
    # print_debug("SensoryManager: Rendering olfactory cues for tags: %s, radius: %s" % [current_sensory_profile.tracked_tags, current_sensory_profile.detection_radius])
    pass

# Helper to add SensoryProfile to the repository
func add_sensory_profile_to_repository(profile: SensoryProfile):
    if profile and profile.profile_id != "":
        sensory_profile_repository[profile.profile_id] = profile
    else:
        printerr("SensoryManager: Could not add invalid or unnamed sensory profile to repository.")

```
