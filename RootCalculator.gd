@tool
extends EditorScript


func _run() -> void:
	var editor_interface = get_editor_interface()
	var anim_tree : AnimationTree = editor_interface.get_selection().get_selected_nodes()[0]
	
	# Configuration - adjust these values according to your setup
	var root_bone_name = "Root"  # Name of your root bone
	#var skeleton_path = NodePath("../GeneralSkeleton")  # Path to skeleton from AnimationTree
	#var speed_param = "parameters/RootSpeed"  # AnimationTree parameter path

	#var skeleton = anim_tree.get_node(skeleton_path)
	#var root_bone_idx = skeleton.find_bone(root_bone_name)

	for anim_name in anim_tree.get_animation_list():
		if "Jog" in anim_name or "Run" in anim_name or "Walk" in anim_name:
			var anim : Animation = anim_tree.get_animation(anim_name)
			
			# Find or create root bone track
			#var bone_path = NodePath(str(skeleton_path) + ":" + str(root_bone_idx))
			var root_track = anim.find_track("%GeneralSkeleton:Root",Animation.TYPE_POSITION_3D)
			
			if root_track == -1:
				print("Skipping ", anim_name, " - no root bone track")
				continue

			# Create or clear Bezier track
			var bezier_path = NodePath("../AnimationTree:RootSpeed")
			var bezier_track = anim.find_track(bezier_path,Animation.TYPE_BEZIER)
			if bezier_track == -1:
				bezier_track = anim.add_track(Animation.TYPE_BEZIER)
				anim.track_set_path(bezier_track, bezier_path)
			else:
				anim.track_clear(bezier_track)
				
			# Process keyframes
			var key_count = anim.track_get_key_count(root_track)
			var prev_position : Vector3
			var prev_time : float
			
			for key_idx in key_count:
				var time = anim.track_get_key_time(root_track, key_idx)
				var position = anim.track_get_key_value(root_track, key_idx)
				
				if key_idx > 0:
					var delta = time - prev_time
					if delta > 0:
						var speed = (position - prev_position).length() / delta
						
						# Insert bezier key at current time with calculated speed
						anim.bezier_track_insert_key(bezier_track,time,speed,Vector2.ZERO,Vector2.ZERO)
				
				prev_position = position
				prev_time = time
			
			print("Processed ", anim_name)
	print("Root motion speed setup complete!")
