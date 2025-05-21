# player/animals/fox_controller.gd
class_name FoxController
extends AnimalBaseController

func _init():
    name = "FoxController"

# Similar to RabbitController, Fox-specific setup beyond AnimalData can be done here.
# For MVP, AnimalData will drive the specifics.

func _setup_sensory_profile():
    super._setup_sensory_profile()
    if animal_data:
        print("FoxController: Confirmed sensory profile ID from AnimalData: %s (e.g., for olfactory sense)" % animal_data.sensory_profile_id)

func _setup_abilities():
    super._setup_abilities()
    if animal_data:
        print("FoxController: Confirmed ability IDs from AnimalData: %s (e.g., for Sneak)" % str(animal_data.ability_ids))
```
