# player/animals/rabbit_controller.gd
class_name RabbitController
extends AnimalBaseController

func _init():
    name = "RabbitController" # Set node name for easier identification

# Override if RabbitController needs specific logic beyond AnimalData during setup
# For MVP, AnimalData primarily defines these, so this is more for confirmation or specific overrides.

# As per AI prompt (2.1.3): "In RabbitController 中重写 SetupSensoryProfile() 方法，应用视觉效果：FOV 110度，轻微边缘模糊。"
# This implies RabbitController might directly set some things, or ensure the correct profile is loaded.
# However, the plan is for SensoryManager to use sensory_profile_id from AnimalData.
# So, this override can confirm or enforce it if AnimalData was generic.
# For now, we assume AnimalData for Rabbit will have the correct sensory_profile_id.

# The AI prompt example: "重写 SetupAbilities() 方法，添加 "短距离冲刺" 能力。"
# Similarly, this is now driven by ability_ids in AnimalData.
# This controller could instantiate the ability resources if they are not globally managed.

# For now, these overrides will just confirm the data from AnimalData.
# Specific instantiation of abilities or sensory effects is handled by AbilityManager and SensoryManager.

func _setup_sensory_profile():
    super._setup_sensory_profile() # Call base method
    if animal_data:
        print("RabbitController: Confirmed sensory profile ID from AnimalData: %s (e.g., for wide FOV)" % animal_data.sensory_profile_id)
        # If direct manipulation was needed:
        # get_viewport().get_camera_3d().fov = 110.0 # Example, but SensoryManager should do this

func _setup_abilities():
    super._setup_abilities() # Call base method
    if animal_data:
        print("RabbitController: Confirmed ability IDs from AnimalData: %s (e.g., for Sprint)" % str(animal_data.ability_ids))
        # If RabbitController was responsible for creating ability instances:
        # var sprint_ability = load("res://player/abilities/sprint_ability.tres").new()
        # ability_manager.add_ability(sprint_ability)
