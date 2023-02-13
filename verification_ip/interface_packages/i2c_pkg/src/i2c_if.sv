// ECE 745: Project 1
// I2C Interface for an IICMB controller

typedef enum bit {START=1'b0, STOP=1'b1} i2c_op_t;

interface i2c_if #(
    int NUM_BUSSES = 1,
    int ADDR_WIDTH = 32,
    int DATA_WIDTH = 16
)(
    // Outputs from slave
    output wire [NUM_BUSSES-1:0] scl_o,
    output tri0 [NUM_BUSSES-1:0] sda_o,

    // Inputs to slave (come from master)
    input wire[NUM_BUSSES-1:0] scl_i,
    input tri0 [NUM_BUSSES-1:0] sda_i
);

reg ack = 1'b0;
assign sda_o = ack ? 'b0 : 'bz;

// Declare queue for capturing address on the sda line
bit address[$];


//////////////////////////////////////////////////////////

task wait_for_i2c_start (output bit capture_start)



endtask

//////////////////////////////////////////////////////////

task receive_data (output bit capture_data)



endtask

//////////////////////////////////////////////////////////

task provide_read_data (output bit transfer_complete)



endtask

//////////////////////////////////////////////////////////



// What is i2c_op_t?
// Tyepdef for R/W

// What are the two outputs for?
task wait_for_i2c_transfer (
    output bit address_complete
);
    // Detect START condition: sda transitions from high to low while scl is high
    @(negedge sda_i);

    if (scl_i) begin : capture_start

        $display ("%t: Start condition!", $time);

        repeat (8) begin : capture_address
            @(posedge scl_i) address.push_front (sda_i);
            $display ("%t: Address bit: %b", $time, sda_i);
        end  

        $display();

        // MSB at the end of the queue
        foreach (address[i]) $display ("%t: Address bit: %b", $time, address[i]);

        // Send ACK. slave pulls sda low while scl is high
        @(negedge scl_i);
        ack <= 1'b1;
        @(negedge scl_i);
        ack <= 1'b0;   

        address_complete = 1'b1;
    end else begin

        address_complete = 1'b0;
    end
endtask

// Provide data for read operation
task provide_read_data (
    input bit [DATA_WIDTH-1:0] read_data, 
    output bit transfer_complete
);

endtask

// Return data observed
task monitor (
    output bit [ADDR_WIDTH-1:0] addr, 
    output i2c_op_t op, 
    output bit [DATA_WIDTH-1:0] data
);


endtask

endinterface




