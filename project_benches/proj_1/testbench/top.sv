`timescale 1ns / 10ps

`define TEMP

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

`define BANNER(x) \
	$display("\n================= %s =================\n", x) \

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

// ****************************************************************************
// Clock generator

initial begin: CLK_GEN
	 clk = 1'b0;
	 forever #5 clk = ~clk;
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

initial begin: WB_MONITORING
	$timeformat(-9, 2, " ns", 12);
	forever begin
		#10 wb_bus.master_monitor (.addr(wb_addr), .data(wb_data), .we(wb_we));
		if (wb_we) begin
			$display("%t: (WB) W: Addr: %b, Data: %b", $time, wb_addr, wb_data);
		end else begin
			$display("%t: (WB) R: Addr: %b, Data: %b", $time, wb_addr, wb_data);
		end
	end
end

// ****************************************************************************
// Monitor I2C bus and display transfers in the transcript

bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
bit [I2C_DATA_WIDTH-1:0] i2c_data[];
bit i2c_op;

initial begin: I2C_MONITORING
	$timeformat(-9, 2, " ns", 12);
	forever begin
		#10 i2c_bus.monitor (.addr(i2c_addr), .op(i2c_op), .data(i2c_data));
		if (!i2c_op) begin
			$display("%t: I2C_BUS WRITE Transfer:", $time);
			$display ("Addr = 0x%x", i2c_addr);
			foreach (i2c_data[i]) $display("Data = %0d ", i2c_data[i]);
		end else begin
			$display("%t: I2C_BUS READ Transfer:", $time);
			$display("Addr: 0x%x", i2c_addr);
			foreach (i2c_data[i]) $display("Data = %0d ", i2c_data[i]);
		end
	end
end

// ****************************************************************************
// Define the flow of the simulation

logic [WB_DATA_WIDTH-1:0] 	dpr_rdata;
logic 						transfer_complete;

initial begin: TEST_FLOW
	wait (!rst)
	wb_enable();
	wb_set_bus(.bus_id(8'h00));

	// Round 1: 32 incrementing writes from 0 to 31
	`BANNER ("ROUND 1 BEGIN");
	wb_start();
	wb_write(.wdata(8'h22 << 1)); // Address
	for (byte wdata = 8'd0; wdata < 8'd31; wdata++) begin
		wb_write(.wdata(wdata));
	end
	wb_stop();
	// Round 2: 32 incrementing reads from 100 to 131
	`BANNER ("ROUND 2 BEGIN");
	wb_start();
	wb_write(.wdata(8'h44 << 1)); // Address
	wb_write(.wdata(8'haa)); // Memory location
	wb_start();
	wb_write(.wdata((8'h44 << 1) | 8'h1));
	for (byte rdata = 8'd100; rdata < 8'd132; rdata++) begin
		wb_read (.provide_data(rdata), .rdata(dpr_rdata));
	end
	wb_stop();
	$finish;
end

////////////////////////////////////////////////////////////////////////////

bit op;
bit [I2C_DATA_WIDTH-1:0] write_data[];

initial begin: I2C_FLOW
	// Wait for reset because a STOP condition occurs at 0ns
	wait (!rst);
	forever begin
		i2c_bus.wait_for_i2c_transfer (.op(op), .write_data(write_data));
		`BANNER ("TRANSFER COMPLETE");
	end
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
	.sda_io (sda)
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

// Enable the IICMB core
task wb_enable();
	wb_bus.master_write (.addr(`CSR_ADDR), .data('b11xx_xxxx)); 
endtask

// Wait for IRQ to go high. Clear IRQ by reading the CMDR register
task wb_wait();
	logic [WB_DATA_WIDTH-1:0] 	cmdr_rdata;
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
endtask

task wb_set_bus(input byte bus_id);
	wb_bus.master_write (.addr(`DPR_ADDR), .data(bus_id));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_SET_BUS));
	wb_wait();
endtask

// Issue a START command
task wb_start();
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));
	wb_wait();
endtask

// Issue a STOP command
task wb_stop();
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));
	wb_wait();
endtask

// Issue a WRITE command
task wb_write(input byte wdata);
	wb_bus.master_write (.addr(	`DPR_ADDR), .data (wdata));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));
	wb_wait();
endtask;

// Issue a READ command (slave writes to the DPR)
task wb_read(input byte provide_data, output byte rdata);
	bit transfer_complete;
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_READ_ACK));
	i2c_bus.provide_read_data (.read_data({provide_data}), .transfer_complete(transfer_complete));
	wait (transfer_complete);
	wb_wait();
	wb_bus.master_read (.addr(`DPR_ADDR), .data(rdata));
endtask

endmodule
