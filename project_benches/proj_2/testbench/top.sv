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

wb_driver driver;
wb_transaction wb_trans;

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
// Monitor Wishbone bus and display transfers in the transcript

logic [WB_ADDR_WIDTH-1:0] wb_addr;
logic [WB_DATA_WIDTH-1:0] wb_data;
logic wb_we;

// initial begin: WB_MONITORING
// 	wait (!rst);
// 	forever begin
// 		wb_bus.master_monitor (.addr(wb_addr), .data(wb_data), .we(wb_we));

// 		if (wb_we) begin
// 			case (wb_data)
// 				8'b0000_0100 : begin `WB_BANNER ($time, "WB BUS: Issue a START command"); end
// 				8'b0000_0101 : begin `WB_BANNER ($time, "WB BUS: Issue a STOP command"); end
// 			endcase
// 		end
// 	end
// end

// ****************************************************************************
// Monitor I2C bus and display transfers in the transcript

bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
bit [I2C_DATA_WIDTH-1:0] i2c_data[];
i2c_op_t 				 i2c_op;

initial begin: MONITOR_I2C_BUS
	$timeformat(-9, 2, " ns", 0);
	wait (!rst);
	forever begin
		i2c_bus.monitor (.addr(i2c_addr), .op(i2c_op), .data(i2c_data));
		if (i2c_op == WRITE) begin
			`I2C_BANNER ($time, "I2C BUS WRITE TRANSFER");	
		end else begin
			`I2C_BANNER ($time, "I2C BUS READ TRANSFER");
		end
		$display ("Addr = 0x%x", i2c_addr);
		$write ("Data = ");
		foreach (i2c_data[i]) 
			$write("%0d  ", i2c_data[i]);
		$display ();
	end
end

// ****************************************************************************
// Define the flow of the simulation


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
	.NUM_BUSSES(NUM_I2C_BUSSES),
	.ADDR_WIDTH(I2C_ADDR_WIDTH),
	.DATA_WIDTH(I2C_DATA_WIDTH)
)
i2c_bus (
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
	ncsu_config_db #(virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)))::set("tst.env.wb_agent.wb_driver", wb_bus);
	driver = new ("tst.env.wb_agent.wb_driver", null);
	wb_trans = new ("wb_trans");
	// Create a new transaction. TODO: The generator is supposed to do this.
	wb_trans.wb_op = 1'b0;
	wb_trans.wb_addr = 8'h22;
	wb_trans.wb_data = new [3];
	for (byte i = 8'd0; i < 8'd3; i++) begin
		wb_trans.wb_data[i] = i;
	end

	wait (!rst);
	driver.wb_enable	();
	driver.wb_set_bus	(.bus_id(8'h00));
	driver.bl_put 		(wb_trans);


	#1000 `FANCY_BANNER ("DONE!");
	$finish;
end

////////////////////////////////////////////////////////////////////////////

bit [I2C_DATA_WIDTH-1:0]	i2c_wdata[];
bit [I2C_DATA_WIDTH-1:0]	i2c_rdata[];
i2c_op_t 					op;
bit 						transfer_complete;

initial begin: I2C_FLOW
	// Wait for reset because a STOP condition occurs at 0ns
	wait (!rst);
	forever begin
		i2c_bus.wait_for_i2c_transfer (.op(op), .write_data(i2c_wdata));
		if (op == READ) begin
			i2c_bus.provide_read_data(.read_data(i2c_rdata), .transfer_complete(transfer_complete));
		end
	end
end

endmodule
