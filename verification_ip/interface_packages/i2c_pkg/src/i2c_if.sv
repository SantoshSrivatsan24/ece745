// ECE 745: Project 1
// I2C Interface for an IICMB controller

interface i2c_if #(
    int NUM_BUSSES = 1,
    int ADDR_WIDTH = 7,
    int DATA_WIDTH = 8
)(
    // Outputs from slave
    output wire [NUM_BUSSES-1:0] sda_o,

    // Inputs to slave (come from master)
    input wire[NUM_BUSSES-1:0] scl_i,
    input wire [NUM_BUSSES-1:0] sda_i
);

typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
typedef bit [DATA_WIDTH-1:0] data_t [];

bit                  do_ack   = 1'b0;
bit                  wren     = 1'b0;  
bit [NUM_BUSSES-1:0] wdata;

assign sda_o = do_ack ? 'b0 : 'bz;
assign sda_o = wren   ? wdata : 'bz;

////////////////////////////////////////////////////////////////////////////

// Read data from a queue and then flush the queue
function automatic bit read_op_from_q (ref bit q[$]);

    {<< bit {read_op_from_q}} = q;
    q.delete();
endfunction

function automatic bit [6:0] read_addr_from_q (ref bit q[$]);

    {<< 7 {read_addr_from_q}} = q;
    q.delete();
endfunction

function automatic data_t read_data_from_q (ref bit q[$]);

    int num_bytes = q.size() / DATA_WIDTH;
    read_data_from_q = new [num_bytes];

    foreach (read_data_from_q[i]) begin
        {<< DATA_WIDTH {read_data_from_q[i]}} = q;
    end

    q.delete();
endfunction

// Store data into a queue
function automatic void write_data_to_q (ref data_t data, ref bit q[$]);

    {>> {q}} = data;
endfunction

// Display data captured on the SDA line
function automatic void display_data (ref data_t data);

    foreach (data[i]) begin
        $display ("I2C Data = 0x%X", data[i]);
    end
endfunction

////////////////////////////////////////////////////////////////////////////

// START: A HIGH to LOW transition on the SDA line while SCL is HIGH

task automatic capture_start (ref bit busy);

    forever begin
        @(negedge sda_i);
        if (scl_i) begin
            // A repeated START occurs if we get a START while the bus is busy
            $display ("%t: I2C START condition.", $time);
            if (busy)
                break;
            else
                busy = 1'b1;
        end
    end
endtask

////////////////////////////////////////////////////////////////////////////

// STOP: A LOW to HIGH transition on the SDA line while SCL is HIGH

task automatic capture_stop(ref bit busy);

    forever begin
        @(posedge sda_i);
        if (scl_i) begin
            $display ("%t: I2C STOP condition", $time);
            busy = 1'b0;
            break;
        end
    end
endtask

////////////////////////////////////////////////////////////////////////////

// Tasks to capture data on the sda line into a transfer queue

task automatic capture_bit (ref bit q[$]);

    // Temporary bit to capture data on the sda line between posedge and negedge
    bit sda;
    @(posedge scl_i);
    sda = sda_i;
    @(negedge scl_i); 
    // Wait until we're sure we didn't see a repeated START/STOP condition
    q.push_back(sda);
endtask

////////////////////////////////////////////////////////////////////////////

// ACK: slave pulls SDA low. Remains low for the HIGH period of the clock

task send_ack ();

    do_ack = 1'b1;
    @(negedge scl_i);
    do_ack = 1'b0;
endtask;

task capture_ack();

    @(negedge scl_i);
endtask;

////////////////////////////////////////////////////////////////////////////

// Thread #1: Detect START and repeated START conditions
// Thread #2: Capture data once a START condition has been detected
// Thread #3: Detect a STOP condition and terminate data transfer

task wait_for_i2c_transfer (
    output i2c_op_t op,
    output bit [DATA_WIDTH-1:0] write_data[]
);

    // automatic - Allocate memory on the stack every time the task is called
    // static    - Preserve across calls  
    // Queue for capturing data on the SDA line
    automatic   bit         q[$]                ;
    automatic   bit [7:0]   device_addr         ;
    static      bit         bus_busy    = 1'b0  ;               

    fork

    // Capture START and repeated START conditions (sets the bus_busy flag)
    begin: DETECT_START
        capture_start(.busy(bus_busy));
    end

    begin: DETECT_TRANSFER

        // Wait for a START condition (detected by capture_start)
        wait (bus_busy);

        // Capture the slave address into a queue
        repeat(7) capture_bit(q);
        device_addr = read_addr_from_q (q);
        $display ("I2C Address = 0x%X", device_addr);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        $cast(op, read_op_from_q(q));
        $display ("I2C Operation = %s", op.name);

        // Acknowledge the first byte
        send_ack();

        if (op == WRITE) begin

            forever begin : CAPTURE_BYTE
                repeat(8) capture_bit(q);
                send_ack(); 
            end
        end
        
        if (op == READ) begin

            // Wait for `provide_read_data()` to to write NUM_BYTES on the sda line
            forever begin: SEND_BYTE
                repeat (8) begin
                    @(posedge scl_i);
                    @(negedge scl_i);
                end
            end
        end

        // TODO: Capture a NACK before STOP condition. Especially if the transfer
        //       direction is going to change. See Fig 12 and Notes on pg. 14
    end

    // Capture a STOP condition (resets the bus_busy flag)
    begin: DETECT_STOP
        capture_stop(.busy(bus_busy));
    end
    join_any

    // Read data from  queue for a write command
    if (op == WRITE) begin

        write_data = read_data_from_q (q);
        foreach (write_data[i]) begin
            $display ("I2C Data = 0x%X", write_data[i]);
        end
    end

    // Kill all threads, return to testbench
    disable fork;

endtask;

////////////////////////////////////////////////////////////////////////////

// TODO: I'm not sure whether this implements read with ack or read with nack
// TODO: I'm not sure whether this task is supposed to drive the SDA line or not
//       I'm driving the SDA line

task provide_read_data (
    input bit [DATA_WIDTH-1:0] read_data [], 
    output bit transfer_complete
);
    // Queue for pushing data onto the SDA line
    automatic bit q[$];

    write_data_to_q(read_data, q);

    for (int i = 0; i < read_data.size() / DATA_WIDTH; i++) begin

        repeat (8) begin
            // Allow the slave to drive the SDA line (MSB first)
            wren = 1'b1; 
            wdata = q.pop_front();
            @(posedge scl_i);
            @(negedge scl_i);
        end
    end

    // Release the SDA line
    wren = 1'b0; 
    transfer_complete = 1'b1;
endtask

////////////////////////////////////////////////////////////////////////////

// Return data observed
// TODO: You have to implement the entire logic of the protocol in monitor
// Shouldn't be dependent on wait for i2c transfer
task monitor (
    output bit [ADDR_WIDTH-1:0] addr, 
    output i2c_op_t op, 
    output bit [DATA_WIDTH-1:0] data[]
);

    automatic   bit         q[$]                ;
    static      bit         bus_busy    = 1'b0  ;      

    fork

    // Capture START and repeated START conditions (sets the bus_busy flag)
    begin: DETECT_START
        capture_start(.busy(bus_busy));
    end

    begin: DETECT_TRANSFER

        // Wait for a START condition (detected by capture_start)
        wait (bus_busy);

        // Capture the slave address into a queue
        repeat(7) capture_bit(q);
        addr = read_addr_from_q (q);
        $display ("I2C Address = 0x%X", addr);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        $cast(op, read_op_from_q(q));
        $display ("I2C Operation = %s", op.name);

        // Acknowledge the first byte
        send_ack();

        // "Observe" data transfer on the bus. Don't drive the bus
        forever begin : CAPTURE_BYTE
            repeat(8) capture_bit(q);
            capture_ack(); 
        end
        
        // TODO: Capture a NACK before STOP condition. Especially if the transfer
        //       direction is going to change. See Fig 12 and Notes on pg. 14
    end

    // Capture a STOP condition (resets the bus_busy flag)
    begin: DETECT_STOP
        capture_stop(.busy(bus_busy));
    end
    join_any


    // Read data from  queue for a read/write command
    data = read_data_from_q (q);
    display_data (data);

    // Kill all threads, return to testbench
    disable fork;
    

endtask

endinterface

////////////////////////////////////////////////////////////////////////////