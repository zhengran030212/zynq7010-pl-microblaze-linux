set script_dir [file dirname [file normalize [info script]]]
set proj_dir   [file join $script_dir build]

puts ">>> creating project"
create_project -force mb_soc $proj_dir -part xc7z010clg400-1
set_property target_language Verilog [current_project]

puts ">>> sourcing board base"
source [file join $script_dir board_base.tcl]

puts ">>> generating wrapper"
set bd_file [get_files -quiet [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc mb_soc.bd]]
if {$bd_file eq ""} { set bd_file [get_files *.bd] }
make_wrapper -files $bd_file -top
set wrapper [glob -nocomplain [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc hdl mb_soc_wrapper.v] \
                              [file join $proj_dir mb_soc.gen sources_1 bd mb_soc hdl mb_soc_wrapper.v]]
if {[llength $wrapper] == 0} {
  puts "WRAPPER_CANDIDATES:"; puts [glob -nocomplain [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc hdl *]]
  set wrapper [glob -nocomplain [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc hdl mb_soc_wrapper.*]]
}
add_files -norecurse [lindex $wrapper 0]
update_compile_order -fileset sources_1
set_property top mb_soc_wrapper [current_fileset]

puts ">>> generating output products"
generate_target all [get_files [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc mb_soc.bd]]
export_ip_user_files -of_objects [get_files [file join $proj_dir mb_soc.srcs sources_1 bd mb_soc mb_soc.bd]] -no_script -sync -force -quiet

puts ">>> synthesis"
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "synth failed"}

puts ">>> implementation"
launch_runs impl_1 -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "impl failed"}

puts ">>> bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_timing_summary -file [file join $proj_dir timing.rpt]
report_utilization    -file [file join $proj_dir utilization.rpt]

set out [file join $script_dir out]
file mkdir $out
file copy -force [file join $proj_dir mb_soc.runs impl_1 mb_soc_wrapper.bit] [file join $out mb_soc.bit]
file copy -force [file join $proj_dir mb_soc.runs impl_1 mb_soc_wrapper.bin] [file join $out mb_soc.bin] -quiet
puts "BUILD_OK=$out"
