# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/polytech/Bureau/vitis_dma/zed/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/polytech/Bureau/vitis_dma/zed/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {zed}\
-hw {/tools/Xilinx/Vitis/2022.2/data/embeddedsw/lib/fixed_hwplatforms/zed.xsa}\
-out {/home/polytech/Bureau/vitis_dma}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {zed}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
