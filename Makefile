PROJECT=hp300
all:
#	quartus_sh -t sys/build_id.tcl compie $(PROJECT)
	quartus_map --read_settings_files=on --write_settings_files=off $(PROJECT) #--recompile=on
	quartus_fit --read_settings_files=off --write_settings_files=off $(PROJECT)
	quartus_asm --read_settings_files=off --write_settings_files=off $(PROJECT)
	quartus_sta $(PROJECT)



