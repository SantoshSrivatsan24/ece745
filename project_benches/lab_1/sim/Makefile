export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile

clean: 
	rm -rf work *.wlf *.vcd transcript

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom ../rtl/mbyte.vhd
	vcom ../rtl/mbit.vhd
	vcom ../rtl/bus_state.vhd
	vcom ../rtl/filter.vhd
	vcom ../rtl/conditioner.vhd
	vcom ../rtl/conditioner_mux.vhd
	vcom ../rtl/iicmb_m.vhd
	vcom ../rtl/regblock.vhd
	vcom ../rtl/wishbone.vhd
	vcom ../rtl/iicmb_m_wb.vhd


comp_bench: comp_wb_pkg
	vlog ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate-gui:
	vsim -i -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

simulate-cli:
	vsim  -c -classdebug -msgmode both -do "set NoQuitOnFinish 1; do vcd.do" optimized_debug_top_tb

debug: clean compile simulate-gui

run: clean compile simulate-cli
