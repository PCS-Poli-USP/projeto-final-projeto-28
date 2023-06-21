set_global_assignment -entity "ClockVGA" -library "lib_ClockVGA" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ClockVGA" -library "lib_ClockVGA" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "ClockVGA" -library "lib_ClockVGA" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ClockVGA" -name SPD_FILE [file join $::quartus(sip_path) "ClockVGA.spd"]

set_global_assignment -library "lib_ClockVGA" -name MISC_FILE [file join $::quartus(sip_path) "ClockVGA_sim/ClockVGA.vho"]
