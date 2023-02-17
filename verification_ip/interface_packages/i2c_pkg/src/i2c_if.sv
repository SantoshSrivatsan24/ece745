// ECE 745: Project 1
// I2C Interface for an IICMB controller

interface i2c_if #(
    int NUM_BUSSES = 1,
    int ADDR_WIDTH = 7,
    int DATA_WIDTH = 8
)(
    input wire      scl_i,
    inout triand    sda_io
);

typedef enum bit {WRITE=1'b0, READ=1'b1} i2c_op_t;
typedef bit [DATA_WIDTH-1:0] data_t [];

// Global signals
bit tx_ack      = 1'b0;
bit wren        = 1'b0;  
bit wdata;

assign sda_io = tx_ack  ? 'b0   : 'bz;
assign sda_io = wren    ? wdata : 'bz;

////////////////////////////////////////////////////////////////////////////

// Read the I2C operation from a queue 
function automatic bit read_op_from_q (ref bit q[$]);
    {<< bit {read_op_from_q}} = q;
    q.delete();
endfunction

// Read the slave address from a queue
function automatic bit [6:0] read_addr_from_q (ref bit q[$]);
    {<< 7 {read_addr_from_q}} = q;
    q.delete();
endfunction

// Read data from a queue
function automatic data_t read_data_from_q (ref bit q[$]);
    int num_bytes = q.size() / DATA_WIDTH;
    read_data_from_q = new [num_bytes];
    // The first byte is stored at the end of the queue
    // i.e. Stream from left to right
    {>> DATA_WIDTH {read_data_from_q}} = q;
    q.delete();
endfunction

// Store data into a queue
function automatic void write_data_to_q (ref data_t data, ref bit q[$]);
    {>> {q}} = data;
endfunction

////////////////////////////////////////////////////////////////////////////

// START: A HIGH to LOW transition on the SDA line while SCL is HIGH
task automatic capture_start (ref bit busy);
    forever begin
        @(negedge sda_io);
        if (scl_i) begin
            // A repeated START occurs if we get a START while the bus is busy
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
        @(posedge sda_io);
        if (scl_i) begin
            busy = 1'b0;
            break;
        end
    end
endtask

////////////////////////////////////////////////////////////////////////////

// Capture data on the sda line into a queue
task automatic capture_bit (ref bit q[$]);
    // Temporary bit to capture data on the sda line between posedge and negedge
    automatic bit sda;
    @(posedge scl_i);
    sda = sda_io;
    @(negedge scl_i); 
    // Wait until we're sure we didn't see a repeated START/STOP condition
    q.push_back(sda);
endtask

// Transmit data from a queue on the sda line
task automatic transmit_bit (ref bit q[$]);
    // Allow the slave to drive the SDA line (MSB first)
    wren = 1'b1; 
    wdata = q.pop_front();
    @(posedge scl_i);
    @(negedge scl_i);
endtask

////////////////////////////////////////////////////////////////////////////

// ACK: slave pulls SDA low. Remains low for the HIGH period of the clock
task transmit_ack ();
    tx_ack = 1'b1;
    @(negedge scl_i);
    tx_ack = 1'b0;
endtask;

task capture_ack(output bit ack);
    wren = 1'b0;
    @(posedge scl_i);
    ack = !sda_io; // SDA remains LOW during the 9th clock pulse
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

    // automatic - Allocate memory on the stack each time the task is called
    // static    - Preserve across calls  
    // Queue for capturing data on the SDA line
    automatic   bit         q[$];
    automatic   bit [7:0]   device_addr;
    static      bit         busy    = 1'b0;               

    fork
    // Capture START and repeated START conditions (sets the bus_busy flag)
    begin: DETECT_START
        capture_start(.busy(busy));
    end

    begin: DETECT_TRANSFER
        // Wait for a START condition (detected by capture_start)
        wait (busy);

        // Capture the slave address into a queue
        repeat(ADDR_WIDTH) capture_bit(q);
        device_addr = read_addr_from_q (q);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        $cast(op, read_op_from_q(q));

        // Acknowledge the first byte
        transmit_ack();
        if (op == WRITE) begin
            forever begin: CAPTURE_BYTE
                repeat(DATA_WIDTH) capture_bit(q);
                transmit_ack(); 
            end
        end
        if (op == READ) begin
            // Block for `provide_read_data()` to to write on the sda line
            forever begin: TRANSMIT_BYTE
                @(posedge scl_i);
            end
        end
    end

    // Capture a STOP condition (resets the bus_busy flag)
    begin: DETECT_STOP
        capture_stop(.busy(busy));
    end
    join_any

    // Read data from queue for a write command
    if (op == WRITE) write_data = read_data_from_q (q);
    // Kill all threads, return to testbench
    disable fork;

endtask;

////////////////////////////////////////////////////////////////////////////

task provide_read_data (
    input bit [DATA_WIDTH-1:0] read_data [], 
    output bit transfer_complete
);
    automatic bit ack;
    // Queue for pushing data onto the SDA line
    automatic bit q[$];
    // Write `read_data` onto the q
    write_data_to_q (read_data, q);

    for (int i = 0; i < read_data.size(); i++) begin
        repeat (DATA_WIDTH) transmit_bit(q);
        capture_ack (.ack(ack));
    end
    transfer_complete = ack;
endtask

////////////////////////////////////////////////////////////////////////////

// Return data observed
task monitor (
    output bit [ADDR_WIDTH-1:0] addr, 
    output i2c_op_t op, 
    output bit [DATA_WIDTH-1:0] data[]
);

    automatic   bit q[$];
    static      bit busy = 1'b0;      

    fork
    // Capture START and repeated START conditions (sets the bus_busy flag)
    begin: DETECT_START
        capture_start(.busy(busy));
    end

    begin: DETECT_TRANSFER
        // Wait for a START condition (detected by capture_start)
        wait (busy);

        // Capture the slave address into a queue
        repeat(7) capture_bit(q);
        addr = read_addr_from_q (q);

        // Capture the I2C operation (R/W)
        capture_bit(q);
        $cast(op, read_op_from_q(q));

        // Acknowledge the first byte
        transmit_ack();

        // "Observe" data transfer on the bus. Don't drive the bus
        forever begin : CAPTURE_BYTE
            repeat(8) capture_bit(q);
            @(negedge scl_i);
        end
    end

    // Capture a STOP condition (resets the bus_busy flag)
    begin: DETECT_STOP
        capture_stop(.busy(busy));
    end
    join_any

    // Read data from queue for a read/write command
    data = read_data_from_q (q);
    // Kill all threads, return to testbench
    disable fork;
endtask

endinterface

////////////////////////////////////////////////////////////////////////////