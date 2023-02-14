// ECE 745: Project 1
// I2C Interface for an IICMB controller

typedef enum bit [1:0] {WRITE=2'b00, READ=2'b01, NULL=2'b11} i2c_op_t;

interface i2c_if #(
    int NUM_BUSSES = 1,
    int ADDR_WIDTH = 32,
    int DATA_WIDTH = 16
)(
    // Outputs from slave
    output wire [NUM_BUSSES-1:0] scl_o,
    output wire [NUM_BUSSES-1:0] sda_o,

    // Inputs to slave (come from master)
    input wire[NUM_BUSSES-1:0] scl_i,
    input wire [NUM_BUSSES-1:0] sda_i
);


// Declare queue for capturing stuff on the sda line
bit         transfer_q[$];
bit         i2c_start = 1'b0;
bit [7:0]   i2c_addr;
i2c_op_t    i2c_op;
byte        i2c_data; 
bit         i2c_ack = 1'b0;

assign sda_o = i2c_ack ? 'b0 : 'bz;

//////////////////////////////////////////////////////////

// Functions to read from a queue

function bit read_op ();

    {<< bit {read_op}} = transfer_q;
    transfer_q.delete();

endfunction

function bit [6:0] read_addr ();

    {<< 7 {read_addr}} = transfer_q;
    transfer_q.delete();

endfunction

function byte read_data ();

    {<< byte {read_data}} = transfer_q;
    transfer_q.delete();

endfunction


////////////////////////////////////////////////////////////////////////////

// START: sda goes low while scl is high
// Spawn thread to repeatedly check for a start condition
// TODO: Thread should resume to check for repeated start

task capture_start (output bit is_start);

    fork
    begin: loop
        forever begin
            @(negedge sda_i);
            if (scl_i) begin
                is_start = 1'b1;
                $display ("Found a start!");
                break;
            end else begin
                is_start = 1'b0;       
            end 
        end
    end
    join_any
endtask

////////////////////////////////////////////////////////////////////////////

task capture_bit ();

    @(posedge scl_i);
    transfer_q.push_back(sda_i);
endtask

////////////////////////////////////////////////////////////////////////////


task capture_addr (output bit [7:0] addr);

    repeat (7) capture_bit();
    addr = read_addr ();
    $display ("I2C Address = 0x%x", addr);

endtask

////////////////////////////////////////////////////////////////////////////

task capture_op (output i2c_op_t op);

    capture_bit();
    $cast(op, read_op());
    $display ("I2C Op = %s", op.name);

endtask

////////////////////////////////////////////////////////////////////////////


task capture_data (output byte data);

    repeat (8) capture_bit();
    data = read_data ();
    $display ("I2C Data = 0x%x", data);

endtask

////////////////////////////////////////////////////////////////////////////

task send_ack ();

    @(negedge scl_i);
    i2c_ack = 1'b1;
    @(negedge scl_i);
    i2c_ack = 1'b0;

endtask;


////////////////////////////////////////////////////////////////////////////

task wait_for_i2c_transfer ();

    capture_start (.is_start(i2c_start));

    wait (i2c_start);

    capture_addr (.addr(i2c_addr));
    capture_op   (.op(i2c_op));
    send_ack     ();

    // TODO: We need to check for a repeated start here. Because the transfer 
    // of data could end anytime
    capture_data (.data(i2c_data));
    send_ack     ();

    // TODO: Write task to capture stop

endtask;

////////////////////////////////////////////////////////////////////////////

// Provide data for read operation
task provide_read_data (
    input bit [DATA_WIDTH-1:0] read_data, 
    output bit transfer_complete
);

endtask

////////////////////////////////////////////////////////////////////////////

// Return data observed
task monitor (
    output bit [ADDR_WIDTH-1:0] addr, 
    output i2c_op_t op, 
    output bit [DATA_WIDTH-1:0] data
);

endtask

endinterface

////////////////////////////////////////////////////////////////////////////

