GEN_TRANS_TYPE ?= abc_transaction_base
TEST_SEED ?= 1234567890
CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean:
	rm -rf work

compile:
	vlog +incdir+ncsu_pkg ncsu_pkg/ncsu_pkg.sv
	vlog +incdir+ncsu_pkg +incdir+abc_pkg abc_pkg/abc_pkg.sv
	vlog abc_pkg/src/abc_if.sv
	vlog +incdir+ncsu_pkg +incdir+first_project_pkg first_project_pkg/first_project_pkg.sv
	vlog -cover bces first_dut/first_dut.sv
	vlog top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_gui

merge_coverage:
	xml2ucdb -format Excel ./test_plan_layered_testbench.xml ./test_plan_layered_testbench.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 


regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb

	
