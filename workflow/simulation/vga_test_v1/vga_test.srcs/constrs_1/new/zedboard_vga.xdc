## Horloge
##set_property PACKAGE_PIN W18 [get_ports clk]
##set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Reset (bouton BTN0)
#et_property PACKAGE_PIN L16 [get_ports reset]
#set_property IOSTANDARD LVCMOS33 [get_ports reset]

set_property PACKAGE_PIN Y9 [get_ports clk] 

## hsync & vsync (utiliser des pins GPIO ou LEDs comme placeholder si VGA non branché)
set_property PACKAGE_PIN AA19 [get_ports hsync]
set_property PACKAGE_PIN Y19 [get_ports vsync]
##set_property IOSTANDARD LVCMOS33 [get_ports {hsync vsync}]

## Red[3:0]
set_property PACKAGE_PIN V20 [get_ports {red[0]}]
set_property PACKAGE_PIN U20 [get_ports {red[1]}]
set_property PACKAGE_PIN V19 [get_ports {red[2]}]
set_property PACKAGE_PIN V18 [get_ports {red[3]}]


## Green[3:0]
set_property PACKAGE_PIN AB22 [get_ports {green[0]}]
set_property PACKAGE_PIN AA22 [get_ports {green[1]}]
set_property PACKAGE_PIN AB21 [get_ports {green[2]}]
set_property PACKAGE_PIN AA21 [get_ports {green[3]}]

## Blue[3:0]
set_property PACKAGE_PIN Y21 [get_ports {blue[0]}]
set_property PACKAGE_PIN Y20 [get_ports {blue[1]}]
set_property PACKAGE_PIN AB20 [get_ports {blue[2]}]
set_property PACKAGE_PIN AB19 [get_ports {blue[3]}]


## pixel_y[9:0] → Mapper les LSB sur les LEDs pour debug
#set_property PACKAGE_PIN T22 [get_ports {pixel_y[0]}]
#set_property PACKAGE_PIN T21 [get_ports {pixel_y[1]}]
#set_property PACKAGE_PIN U22 [get_ports {pixel_y[2]}]
#set_property PACKAGE_PIN U21 [get_ports {pixel_y[3]}]
#set_property PACKAGE_PIN V22 [get_ports {pixel_y[4]}]
#set_property PACKAGE_PIN W22 [get_ports {pixel_y[5]}]
#set_property PACKAGE_PIN W21 [get_ports {pixel_y[6]}]
#set_property PACKAGE_PIN Y22 [get_ports {pixel_y[7]}]
#set_property PACKAGE_PIN Y21 [get_ports {pixel_y[8]}]
#set_property PACKAGE_PIN T20 [get_ports {pixel_y[9]}]
##set_property IOSTANDARD LVCMOS33 [get_ports {pixel_y[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

