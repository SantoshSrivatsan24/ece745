`timescale 1ns / 10ps

`define CSR_ADDR	2'h0
`define DPR_ADDR 	2'h1
`define CMDR_ADDR 	2'h2

`define CMD_START     8'bxxxx_x100
`define CMD_STOP      8'bxxxx_x101
`define CMD_READ_ACK  8'bxxxx_x010
`define CMD_READ_NACK 8'bxxxx_x011
`define CMD_WRITE     8'bxxxx_x001
`define CMD_SET_BUS   8'bxxxx_x110
`define CMD_WAIT      8'bxxxx_x000

`define SLAVE_ADDR	(8'h22 << 1)

`define I2C_BANNER(t, x) \
	$display ("========================================="); \
	$display ("%s (%t)", x, t); \
	$display ("-----------------------------------------")

`define WB_BANNER(t, x) \
	$display ("============================================================"); \
	$display ("%s (%t)", x, t)

`define FANCY_BANNER(x) \
	$display ("\n************************************************************"); \
	$display ("%s", x); \
	$display ("************************************************************\n")


import ncsu_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int CLK_PHASE = 5;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
triand  [NUM_I2C_BUSSES-1:0] sda;

// i2cmb_environment env;
i2cmb_test test;
wb_transaction_base #(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)) wb_trans;
wb_transaction_base #(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)) wb_read_trans;
i2c_transaction #(.ADDR_WIDTH(I2C_ADDR_WIDTH), .DATA_WIDTH(I2C_DATA_WIDTH)) i2c_trans;
bit [I2C_DATA_WIDTH-1:0] i2c_rdata [];

// ****************************************************************************
// Clock generator

initial begin: CLK_GEN
	 clk = 1'b0;
	 forever #CLK_PHASE clk = ~clk;
end

// ****************************************************************************
// Reset generator

// Active high reset (pg. 14, iicmb_mb spec)
initial begin: RST_GEN
	#113 rst = 1'b0;
end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if #(
	.ADDR_WIDTH(WB_ADDR_WIDTH),
	.DATA_WIDTH(WB_DATA_WIDTH)  
)
wb_bus (
	// System sigals
	.clk_i(clk),
	.rst_i(rst),
	.irq_i(irq),
	// Master signals
	.cyc_o(cyc),
	.stb_o(stb),
	.ack_i(ack),
	.adr_o(adr),
	.we_o(we),
	// Slave signals
	.cyc_i(),
	.stb_i(),
	.ack_o(),
	.adr_i(),
	.we_i(),
	// Shred signals
	.dat_o(dat_wr_o),
	.dat_i(dat_rd_i)
	);

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model
i2c_if #(
	.ADDR_WIDTH(I2C_ADDR_WIDTH),
	.DATA_WIDTH(I2C_DATA_WIDTH)
)
i2c_bus (
	.rst_i  (rst),
	.scl_i 	(scl),
	.sda_i  (sda),
	.sda_o  (sda)
);

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
	(
		// ------------------------------------
		// -- Wishbone signals:
		.clk_i(clk),         // in    std_logic;                            -- Clock
		.rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
		// -------------
		.cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
		.stb_i(stb),         // in    std_logic;                            -- Slave selection
		.ack_o(ack),         //   out std_logic;                            -- Acknowledge output
		.adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
		.we_i(we),           // in    std_logic;                            -- Write enable
		.dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
		.dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
		// ------------------------------------
		// ------------------------------------
		// -- Interrupt request:
		.irq(irq),           //   out std_logic;                            -- Interrupt request
		// ------------------------------------
		// ------------------------------------
		// -- I2C interfaces:
		.scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
		.sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
		.scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
		.sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
		// ------------------------------------
	);

////////////////////////////////////////////////////////////////////////////

initial begin: TEST_FLOW
	ncsu_config_db #(virtual wb_if #(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::set("tst.env.wb_agent", wb_bus);
	ncsu_config_db #(virtual i2c_if #(.ADDR_WIDTH(I2C_ADDR_WIDTH), .DATA_WIDTH(I2C_DATA_WIDTH)))::set("tst.env.i2c_agent", i2c_bus);

	// env = new ("tst.env", null);
	// env.build();
	// wb_trans = new ("wb_trans");

	test = new ("tst", null);

	wait (!rst);
	test.run();
	// env.agent0.run();
	
	// wb_trans.create(0, `CSR_ADDR, 8'b11xx_xxxx);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(0, `DPR_ADDR, 8'h00);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_SET_BUS);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_START);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(0, `DPR_ADDR, `SLAVE_ADDR);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_WRITE);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(0, `DPR_ADDR, 8'hab);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_WRITE);
	// env.agent0.bl_put(wb_trans);

	// i2c_rdata = new[1];
	// i2c_rdata = {8'd24};
	// env.agent1.set_data(i2c_rdata);
	
	// wb_trans.create(1, `CMDR_ADDR, `CMD_START);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(0, `DPR_ADDR, `SLAVE_ADDR | 1'b1);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_WRITE);
	// env.agent0.bl_put(wb_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_READ_NACK);
	// env.agent0.bl_put(wb_trans);
	// env.agent0.bl_get(wb_read_trans);

	// wb_trans.create(1, `CMDR_ADDR, `CMD_STOP);
	// env.agent0.bl_put(wb_trans);

	#1000 `FANCY_BANNER ("DONE!");
	$finish;
end

////////////////////////////////////////////////////////////////////////////

// initial begin: I2C_FLOW
// 	// Wait for reset because a STOP condition occurs at 0ns
// 	wait (!rst);
// 	forever begin
// 		env.agent1.bl_get (i2c_trans);
// 		if (i2c_trans.op == READ) begin
// 			env.agent1.bl_put (i2c_trans);
// 		end
// 	end
// end

// initial begin: I2C_MONITOR
// 	wait (!rst);
// 	env.agent1.run();
// end

endmodule
