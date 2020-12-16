###############################
# Author: Semih GENC
# Description : Automation script for simulation of median filter
# Date : 2020-12-16
###############################
# Please use this file with Modelsim simulator
# You can edit this file as you wish


###############################
# Definitions
###############################
set design_path [pwd]
set workspace_name "sim_median_filter"

# Relative path defs
set sim_path "${design_path}"
set rtl_path "${design_path}/../design"
set tb_path "${design_path}/tb"
set sim_working_folder "${sim_path}/run"


#mkdir run
cd $sim_working_folder


###############################
# Create work library
###############################
vlib work



###############################
# Compile files
###############################

vlog -work work -timescale "1ns/1ps" -sv \
$rtl_path/*.v \
$rtl_path/components/*.v \
$rtl_path/components/sort_NxN/*.v \
$sim_path/modules/file_frame_grabber.sv \
$sim_path/modules/frame_timing_gen.v \
$sim_path/modules/parallel_2_vbus.v \
$sim_path/modules/pgm_reader.sv \
$sim_path/modules/vbus_2_parallel.v \
$sim_path/modules/file_compare.sv \
$tb_path/tb.sv


vsim tb

add wave -position insertpoint sim:/tb/*

run -all
