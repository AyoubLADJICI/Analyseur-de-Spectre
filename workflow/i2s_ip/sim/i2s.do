puts "Simulation script for ModelSim "

vlib work
vcom -2008 ../src/i2s.vhd
vcom -2008 tb_i2s.vhd

vsim i2s_tb(behavioral)

view signals
add wave *

add wave -position insertpoint  \
sim:/i2s_tb/uut/bit_counter

add wave -position insertpoint  \
sim:/i2s_tb/uut/packet_counter

run -all
wave zoom full