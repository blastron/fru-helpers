# Stores data describing a step in a strat, such as its human-readable description. Also indicates
#   what functions to call in order to simulate the mechanic and execute the strat.
class_name Step extends Resource

# The description of how the mechanic works. If blank, the previous step's description will be
#   shown.
@export var mechanic_description: String

# The description of how the strat is executed. If blank, will show the most recent description
#   found, provided the mechanic description has not changed since that step was last shown.
@export var strat_description: String

# Lists of locators to change the state of, separated by spaces.
@export var active_locators: String
@export var inactive_locators: String
@export var hidden_locators: String
