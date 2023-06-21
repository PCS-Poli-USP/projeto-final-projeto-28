set_global_assignment -entity "RAM_CLOCK" -library "lib_RAM_CLOCK" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "RAM_CLOCK" -library "lib_RAM_CLOCK" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "RAM_CLOCK" -library "lib_RAM_CLOCK" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_RAM_CLOCK" -name SPD_FILE [file join $::quartus(sip_path) "RAM_CLOCK.spd"]

set_global_assignment -library "lib_RAM_CLOCK" -name MISC_FILE [file join $::quartus(sip_path) "RAM_CLOCK_sim/RAM_CLOCK.vho"]
