set_global_assignment -entity "ClockPll" -library "lib_ClockPll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ClockPll" -library "lib_ClockPll" -name IP_TOOL_VERSION "20.1"
set_global_assignment -entity "ClockPll" -library "lib_ClockPll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ClockPll" -name SPD_FILE [file join $::quartus(sip_path) "ClockPll.spd"]

set_global_assignment -library "lib_ClockPll" -name MISC_FILE [file join $::quartus(sip_path) "ClockPll_sim/ClockPll.vho"]
