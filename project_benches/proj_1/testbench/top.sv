`timescale 1ns / 10ps

`define EXAMPLES

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
			foreach (i2c_data[i]) $display("Data = 0x%x ", i2c_data[i]);
		end else begin
			$display("%t: I2C_BUS READ Transfer:", $time);
			$display("Addr: 0x%x", i2c_addr);
			foreach (i2c_data[i]) $display("Data = 0x%x ", i2c_data[i]);
		end
	end
end

// ****************************************************************************
// Define the flow of the simulation

logic [WB_DATA_WIDTH-1:0] 	cmdr_rdata;
logic [WB_DATA_WIDTH-1:0] 	dpr_rdata;
logic 						transfer_complete;

bit [7:0] data_to_provide [1] = {8'h34};


initial begin: TEST_FLOW

	wait (!rst)

`ifdef EXAMPLES
	// 6.1. Example 1 (pg. 22): Enable the IICMB core after power up
	// by writing the 'E' bit of the CSR register. Also enable interrupts (for Example 3)
	wb_bus.master_write (.addr(`CSR_ADDR), .data('b11xx_xxxx)); 

	// 6.3. Example 3: Write a byte 0x78 to a slave with address 0x22 
	// residing on IIC bus #5

	// 6.3.1. Write byte 0x00 to the DPR. This is the ID of the desired IIC bus
	wb_bus.master_write (.addr(`DPR_ADDR), .data('h0a));

	// 6.3.2. Write byte 'xxxx_x110' to the CMDR. This is the `Set Bus` command (pg. 7)
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_SET_BUS));

	// 6.3.3. Wait for interrupt or until the DON bit of the CMDR reads '1'
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata)); // Clear interrupt output

	// 6.3.4. Write byte 'xxxx_x100' to the CMDR. This is the start command (pg. 7)
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));

	// 6.3.5. Wait for interrupt or until the DON bit of the CMDR reads '1'
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// 6.3.6. Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 
	// 1 bit to the left + rightmost bit = '0', which means writing
	wb_bus.master_write (.addr(`DPR_ADDR), .data ('h22 << 1));

	// 6.3.7. Write byte 'xxxx_x001' to the CMDR. This is the Write command (pg. 7)
	wb_bus.master_write (.addr(`CMDR_ADDR), .data (`CMD_WRITE));

	// 6.3.8. Wait for interrupt or until the DON bit of the CMDR reads '1'. If instead
	// of DON, the NAK bit is '1', then slave doesn't respond
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// 6.3.9. Write byte 0x78 to the DPR. This is the byte to be written
	wb_bus.master_write (.addr(`DPR_ADDR), .data ('h78));

	// 6.3.10. Write byte 'xxxx_x001' to the CMDR. This is the Write command (pg. 7)
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));

	// 6.3.11. Wait for interrupt or until the DON bit of the CMDR reads '1'.
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// 6.3.12. Write byte 'xxxx_x101' to the CMDR. This is the Stop command
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));

	// 6.3.13. Wait for interrupt or until the DON bit of the CMDR reads '1'.
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
	
	////////////////////////////////////////////////////////////////////////////

	// 6.5. Example 5: Read byte from slave address 0x44 and memory location 0xAA

	/* 4 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));

	/* 5 */ wait (irq); 
			wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	/* 6 */ wb_bus.master_write (.addr(`DPR_ADDR), .data('h44 << 1)); // Write slave address

	/* 7 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));

	/* 8 */ wait (irq); 
			wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	/* 9 */ wb_bus.master_write (.addr(	`DPR_ADDR), .data ('hAA)); // Write memory location

	/* 10 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));

	/* 11 */ wait (irq); 
			 wb_bus.master_read (.addr(`CMDR_ADDR), .data (cmdr_rdata));

	/* 12 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START)); // Repeated START. Does it work without this??

	/* 13 */ wait (irq); 
			 wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	/* 14 */ wb_bus.master_write (.addr(`DPR_ADDR), .data('h89));

	/* 15 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));

	/* 16 */ wait (irq);
			 wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	/* 17 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_READ_ACK));

			i2c_bus.provide_read_data(.read_data(data_to_provide), .transfer_complete(transfer_complete));
			// wait(transfer_complete);

	/* 18 */ wait(irq);
			 wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	/* 19 */ wb_bus.master_read (.addr(`DPR_ADDR), .data(dpr_rdata));

	/* 20 */ wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));

	/* 21 */ wait (irq);
			 wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

`endif

	////////////////////////////////////////////////////////////////////////////

`ifdef PROJECT1
	// Write 32 incrementing values, from 0 to 31, to the i2c bus

	// Enable IICMB core
	wb_bus.master_write (.addr(`CSR_ADDR), .data('b11xx_xxxx)); 

	// Set Bus
	wb_bus.master_write (.addr(`DPR_ADDR), .data('h00));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_SET_BUS));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// START
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Write address to slave (Write operation)
	wb_bus.master_write (.addr(`DPR_ADDR), .data ('h22 << 1));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data (`CMD_WRITE));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Write data to slave
	for (byte wdata = 8'd0; wdata < 8'd31; wdata++) begin

		// TODO: Store wdata in a queue to verify later
		wb_bus.master_write (.addr(`DPR_ADDR), .data (wdata));
		wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));
		wait (irq);
		wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
	end

	// STOP
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	////////////////////////////////////////////////////////////////////////////

	// Read 32 values from the I2C bus

	// START
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Write address to slave (Write operation)
	wb_bus.master_write (.addr(`DPR_ADDR), .data ('h88));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data (`CMD_WRITE));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Write memory location to slave
	wb_bus.master_write (.addr(	`DPR_ADDR), .data ('hAA));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));
	wait (irq); 
	wb_bus.master_read (.addr(`CMDR_ADDR), .data (cmdr_rdata));

	// Repeated START
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));
	wait (irq); 
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Write address to slave (Read operation)
	wb_bus.master_write (.addr(`DPR_ADDR), .data('h89));
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));
	wait (irq); 
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

	// Read data from slave
	// for (byte rdata = 8'd100; rdata < 8'd105; rdata++) begin

		// $display ("rdata = %d", rdata);


		wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_READ_NACK));
		// wait (transfer_complete);
		wait (irq);
		wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
		i2c_bus.provide_read_data (.read_data(data_to_provide), .transfer_complete(transfer_complete));

		// TODO: Store DPR in a queue to verify later
		wb_bus.master_read (.addr(`DPR_ADDR), .data(dpr_rdata));
	// end

	// STOP
	wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));
	wait (irq);
	wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));

`endif
	#10000 $finish;
end

////////////////////////////////////////////////////////////////////////////

bit op;
bit [I2C_DATA_WIDTH-1:0] write_data[];

initial begin: I2C_FLOW

	// Wait for reset because a STOP condition occurs at 0ns
	wait (!rst);

	forever begin
		i2c_bus.wait_for_i2c_transfer (.op(op), .write_data(write_data));
		$display ("\n====================== TRANSFER COMPLETE ======================\n");
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


endmodule
