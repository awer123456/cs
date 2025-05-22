# player/animals/rabbit_controller.gd
class_name RabbitController
extends AnimalBaseController # This now correctly points to the CharacterBody3D version

func _init():
    name = "RabbitController"

# No _physics_process override needed for now, base class handles it.

func _setup_sensory_profile():
    super._setup_sensory_profile()
    if animal_data:
        # print("RabbitController: Confirmed sensory profile ID from AnimalData: %s" % animal_data.sensory_profile_id)
        pass

func _setup_abilities():
    super._setup_abilities()
    if animal_data:
        # print("RabbitController: Confirmed ability IDs from AnimalData: %s" % str(animal_data.ability_ids))
        pass
```
