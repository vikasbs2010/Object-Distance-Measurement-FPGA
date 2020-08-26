proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_param gui.test TreeTableDev
  debug::add_scope template.lib 1
  create_project -in_memory -part xc7z020clg484-1
  set_property board_part em.avnet.com:zed:part0:1.2 [current_project]
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.cache/wt [current_project]
  set_property parent.project_path /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.xpr [current_project]
  set_property ip_repo_paths /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.cache/ip [current_project]
  set_property ip_output_repo /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.cache/ip [current_project]
  add_files -quiet /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.runs/synth_1/Main_module.dcp
  add_files -quiet /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.runs/vio_0_synth_1/vio_0.dcp
  set_property netlist_only true [get_files /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.runs/vio_0_synth_1/vio_0.dcp]
  read_xdc -mode out_of_context -ref vio_0 /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.srcs/sources_1/ip/vio_0/vio_0_ooc.xdc
  set_property processing_order EARLY [get_files /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.srcs/sources_1/ip/vio_0/vio_0_ooc.xdc]
  read_xdc -ref vio_0 /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.srcs/sources_1/ip/vio_0/vio_0.xdc
  set_property processing_order EARLY [get_files /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.srcs/sources_1/ip/vio_0/vio_0.xdc]
  read_xdc /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.srcs/constrs_1/new/Obj_distance_measurement.xdc
  link_design -top Main_module -part xc7z020clg484-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force Main_module_opt.dcp
  catch {report_drc -file Main_module_drc_opted.rpt}
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  place_design 
  write_checkpoint -force Main_module_placed.dcp
  catch { report_io -file Main_module_io_placed.rpt }
  catch { report_clock_utilization -file Main_module_clock_utilization_placed.rpt }
  catch { report_utilization -file Main_module_utilization_placed.rpt -pb Main_module_utilization_placed.pb }
  catch { report_control_sets -verbose -file Main_module_control_sets_placed.rpt }
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force Main_module_routed.dcp
  catch { report_drc -file Main_module_drc_routed.rpt -pb Main_module_drc_routed.pb }
  catch { report_timing_summary -warn_on_violation -max_paths 10 -file Main_module_timing_summary_routed.rpt -rpx Main_module_timing_summary_routed.rpx }
  catch { report_power -file Main_module_power_routed.rpt -pb Main_module_power_summary_routed.pb }
  catch { report_route_status -file Main_module_route_status.rpt -pb Main_module_route_status.pb }
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

start_step write_bitstream
set rc [catch {
  create_msg_db write_bitstream.pb
  write_bitstream -force Main_module.bit 
  if { [file exists /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.runs/synth_1/Main_module.hwdef] } {
    catch { write_sysdef -hwdef /home/2019H1400080H/Documents/Object_Distance_Measurement/Object_Distance_Measurement.runs/synth_1/Main_module.hwdef -bitfile Main_module.bit -meminfo Main_module.mmi -file Main_module.sysdef }
  }
  close_msg_db -file write_bitstream.pb
} RESULT]
if {$rc} {
  step_failed write_bitstream
  return -code error $RESULT
} else {
  end_step write_bitstream
}

