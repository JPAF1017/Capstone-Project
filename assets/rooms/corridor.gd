@tool
extends DungeonRoom3D

func _ready():
	super._ready()
	dungeon_done_generating.connect(remove_unused_doors_and_walls)

func remove_unused_doors_and_walls():
	var models = $Models

	var directions = {
		"F": "F_WALL",
		"R": "R_WALL",
		"B": "B_WALL",
		"L": "L_WALL"
	}

	for dir in directions.keys():
		var door_node_path = "CSGBox3D/DOOR?_" + dir + "_CUT"
		var wall_name = directions[dir]

		if has_node(door_node_path):
			var door = get_door_by_node(get_node(door_node_path))
			if door and door.get_room_leads_to() != null:
				# Remove the wall if a door leads to another room
				if models.has_node(wall_name):
					models.get_node(wall_name).queue_free()
			else:
				# Otherwise make sure the wall is visible
				if models.has_node(wall_name):
					models.get_node(wall_name).visible = true

	# Remove doors that don't lead anywhere
	for door in get_doors():
		if door.get_room_leads_to() == null:
			door.door_node.queue_free()
