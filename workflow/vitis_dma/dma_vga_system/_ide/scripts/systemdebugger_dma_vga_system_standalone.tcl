# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/polytech/Bureau/vitis_dma/dma_vga_system/_ide/scripts/systemdebugger_dma_vga_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/polytech/Bureau/vitis_dma/dma_vga_system/_ide/scripts/systemdebugger_dma_vga_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw /home/polytech/Bureau/vitis_dma/zed/export/zed/hw/zed.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source /home/polytech/Bureau/vitis_dma/dma_vga/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow /home/polytech/Bureau/vitis_dma/dma_vga/Debug/dma_vga.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
