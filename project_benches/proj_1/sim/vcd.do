vcd file output.vcd
vcd add /top/DUT/clk_i
vcd add /top/DUT/rst_i
vcd add /top/DUT/cyc_i
vcd add /top/DUT/stb_i
vcd add /top/DUT/ack_o
vcd add /top/DUT/adr_i
vcd add /top/DUT/we_i
vcd add /top/DUT/dat_i
vcd add /top/DUT/dat_o
vcd add /top/DUT/irq
vcd add /top/DUT/scl_i
vcd add /top/DUT/sda_i
vcd add /top/DUT/scl_o
vcd add /top/DUT/sda_o

vcd add /top/i2c_bus/*

run -all
quit