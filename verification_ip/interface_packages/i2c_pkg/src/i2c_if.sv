// ECE 745: Project 1
// I2C Interface for an IICMB controller

import i2c_pkg::*;

interface i2c_if #(
    int NUM_BUSSES = 1,
    int ADDR_WIDTH = 7,
    int DATA_WIDTH = 8
)(
    input wire      scl_i,
    input wire      sda_i,
    output wire     sda_o
);

typedef bit [DATA_WIDTH-1:0] data_t [];

// Global signals
static bit busy    = 1'b0;
static bit busy_   = 1'b0;
static bit sda_ack  = 1'b0;
static bit sda_we    = 1'b0;  
static bit wdata;

assign sda_o = sda_ack  ? 'b0   : 'bz;
assign sda_o = sda_we   ? wdata : 'bz;

////////////////////////////////////////////////////////////////////////////

function automatic bit read_op_from_q (ref bit q[$]);
    {<< bit {read_op_from_q}} = q;
    q.delete();
endfunction

function automatic bit [6:0] read_addr_from_q (ref bit q[$]);
    {<< ADDR_WIDTH {read_addr_from_q}} = q;
    q.delete();
endfunction

function automatic data_t read_data_from_q (ref bit q[$]);
    int num_bytes = q.size() / DATA_WIDTH;
    read_data_from_q = new [num_bytes];
    // The first byte is stored at the end of the queue
    // i.e. Stream from left to right
    {>> DATA_WIDTH {read_data_from_q}} = q;
    q.delete();
endfunction

function automatic void write_data_to_q (ref data_t data, ref bit q[$]);
    {>> {q}} = data;
endfunction

////////////////////////////////////////////////////////////////////////////

// START: A HIGH to LOW transition on the SDA line while SCL is HIGH
task automatic capture_start (ref bit is_busy);
    forever begin
        @(negedge sda_i);
        if (scl_i) begin
            // A repeated START occurs if we get a START while the bus is busy
            if (is_busy)
                break;
            else
                is_busy = 1'b1;
        end
    end
endtask

////////////////////////////////////////////////////////////////////////////

// STOP: A LOW to HIGH transition on the SDA line while SCL is HIGH
task automatic capture_stop(ref bit is_busy);
    forever begin
        @(posedge sda_i);
        if (scl_i) begin
            is_busy = 1'b0;
            break;
        end
    end
endtask

////////////////////////////////////////////////////////////////////////////

// Capture data on the sda line into a queue
task automatic capture_bit (ref bit q[$]);
    bit data;
    @(posedge scl_i);
    data = sda_i;
    @(negedge scl_i); 
    // Wait until we're sure we didn't see a repeated START/STOP condition
    q.push_back(data);
endtask

////////////////////////////////////////////////////////////////////////////

// Transmit data from a queue onto the sda line
task automatic transmit_bit (ref bit q[$]);
    // Allow the slave to drive the SDA line (MSB first)
    sda_we = 1'b1; 
    wdata = q.pop_front();
    @(posedge scl_i);
    @(negedge scl_i);
    // Release the SDA line
    sda_we = 1'b0;
endtask

////////////////////////////////////////////////////////////////////////////

// ACK: slave pulls SDA low. Remains low for the HIGH period of the clock
task transmit_ack ();
    sda_ack = 1'b1;
    @(negedge scl_i);
    sda_ack = 1'b0;
endtask

task capture_ack(output bit ack);
    sda_we = 1'b0;
    @(posedge scl_i);
    ack = !sda_i; // SDA remains LOW during the 9th clock pulse
    @(negedge scl_i);
endtask

////////////////////////////////////////////////////////////////////////////

// Thread #1: Detect START and repeated START conditions
// Thread #2: Detect a STOP condition and terminate data transfer
// Thread #3: Capture data once a START condition has been detected
task wait_for_i2c_transfer (
    output i2c_op_t op,
    output bit [DATA_WIDTH-1:0] write_data[]
);
    automatic   bit         q[$];
    automatic   bit [7:0]   device_addr;             

    fork
    capture_start(.is_busy(busy));
    capture_stop(.is_busy(busy));
    begin: CAPTURE_BYTE
        // Wait for a START condition
        wait (busy);

        // Capture the slave address into a queue
        repeat(ADDR_WIDTH) capture_bit(q);
        device_addr = read_addr_from_q (q);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        op = i2c_op_t'(read_op_from_q(q));

        // Acknowledge the first byte
        transmit_ack();
        if (op == WRITE) begin
            forever begin
                repeat(DATA_WIDTH) capture_bit(q);
                transmit_ack(); 
            end
        end
    end
    join_any
    // Kill all threads, return to testbench
    disable fork;
    // Read data from queue for a write command
    if (op == WRITE) write_data = read_data_from_q (q);
endtask

////////////////////////////////////////////////////////////////////////////

task provide_read_data (
    input bit [DATA_WIDTH-1:0] read_data [], 
    output bit transfer_complete
);
    automatic bit q[$];
    automatic bit ack;
    fork
    capture_start(.is_busy (busy));
    capture_stop(.is_busy(busy));
    begin: TRANSMIT_BYTE
        write_data_to_q (read_data, q);
        for (int i = 0; i < read_data.size(); i++) begin
            repeat (DATA_WIDTH) transmit_bit(q);
            capture_ack (.ack(ack));
            // A NACK during a read means the master does not want the slave to send any more bytes
            if (!ack) break;
        end
        // Block until repeated START/STOP
        forever @(posedge scl_i); 
    end
    join_any
    disable fork;
    // Transfer complete if the slave receives a NACK from the master
    transfer_complete = !ack;
endtask

////////////////////////////////////////////////////////////////////////////

// Return data observed
task monitor (
    output bit [ADDR_WIDTH-1:0] addr, 
    output i2c_op_t op, 
    output bit [DATA_WIDTH-1:0] data[]
);
    automatic   bit q[$];      

    fork
    capture_start(.is_busy(busy_));
    capture_stop(.is_busy(busy_));
    begin: OBSERVE_TRANSFER
        // Wait for a START condition
        wait (busy_);

        // Capture the slave address into a queue
        repeat(ADDR_WIDTH) capture_bit(q);
        addr = read_addr_from_q (q);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        op = i2c_op_t'(read_op_from_q(q));

        // Acknowledge the first byte
        @(negedge scl_i);

        // Observe data transfer on the bus. Don't drive the bus
        forever begin
            repeat(DATA_WIDTH) capture_bit(q);
            @(negedge scl_i);
        end
    end
    join_any
    // Kill all threads, return to testbench
    disable fork;
    // Read data from queue for a read/write command
    data = read_data_from_q (q);
endtask

endinterface

////////////////////////////////////////////////////////////////////////////