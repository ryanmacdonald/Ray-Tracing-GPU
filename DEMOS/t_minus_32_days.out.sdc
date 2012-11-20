## Generated SDC file "t_minus_32_days.out.sdc"

## Copyright (C) 1991-2012 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 12.0 Build 178 05/31/2012 SJ Full Version"

## DATE    "Fri Nov 09 20:36:47 2012"

##
## DEVICE  "EP4CE115F29C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports { clk }]
create_clock -name {clk_25M} -period 40.000 -waveform { 0.000 20.000 } [get_pins {fbh|reader|vc|clk_25M|clk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]} -source [get_pins {mra|sdram_ctrl|altpll_0|sd1|pll7|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -phase -54.000 -master_clock {clk} [get_pins {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] -rise_to [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] -fall_to [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] -rise_to [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] -fall_to [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -exclusive -group [get_clocks {clk}] -group [get_clocks {clk_25M}] -group [get_clocks {mra|sdram_ctrl|altpll_0|sd1|pll7|clk[0]}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

