GEN_TRANS_TYPE ?= abc_transaction_base

clean:
	rm -rf work

compile:
	vlog +incdir+ncsu_pkg ncsu_pkg/ncsu_pkg.sv
	vlog +incdir+ncsu_pkg +incdir+abc_pkg abc_pkg/abc_pkg.sv
	vlog abc_pkg/src/abc_if.sv
	vlog +incdir+ncsu_pkg +incdir+first_project_pkg first_project_pkg/first_project_pkg.sv
	vlog first_dut/first_dut.sv
	vlog top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

run_cli:
	vsim  -c -sv_seed 12345 -do "run -a" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim  -sv_seed 12345 -do "run 0;do wave.do;run -a" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_gui
