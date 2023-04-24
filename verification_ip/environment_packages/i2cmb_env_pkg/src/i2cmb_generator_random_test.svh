class i2cmb_generator_random_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_random_test)

    local bit read_complete;
    local bit op;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        this.read_complete = 1'b0;
        this.op = 1'b0;
    endfunction

    ///////////////////////////////////////////////////////////////////////////
    // Generate a random command based on the previous command AND the response
    // to the previous command. Restart transaction if nak/arbitration lost.
    // We can't have any random sequence of commands. 
    // For instance, The DUT hangs when a READ follows a START.
    ///////////////////////////////////////////////////////////////////////////
    local task generate_rand_cmd (input cmd_t prev_cmd, input rsp_t prev_rsp, output cmd_t curr_cmd, output rsp_t curr_rsp);
        randsequence (main)
            main:
            case (prev_rsp)
            RSP_NAK, RSP_ARB_LOST, RSP_ERR : START;
            default: CONTINUE;
            endcase;

            CONTINUE      :
            case (prev_cmd)
            CMD_START     : AFTER_START;
            CMD_STOP      : AFTER_STOP;
            CMD_READ_ACK  : AFTER_READ_ACK;
            CMD_READ_NAK  : AFTER_READ_NAK;
            CMD_WRITE     : AFTER_WRITE;
            CMD_SET_BUS   : AFTER_SET_BUS;
            CMD_WAIT      : AFTER_WAIT;
            default       : START;
            endcase;
           
            AFTER_START     : START  | STOP  | ADDR;
            AFTER_STOP      : START  | WAIT  | SET_BUS;
            AFTER_READ_ACK  : READ_ACK | READ_NAK;
            AFTER_READ_NAK  : START | STOP;
            AFTER_WRITE     : 
            case (this.op)
                1'b0        : AFTER_WRITE0;                 
                1'b1        : AFTER_WRITE1;
            endcase;
            AFTER_WRITE0    : START | STOP | WRITE;                 // Can't have a READ if the operation is a WRITE
            AFTER_WRITE1    : 
            case (this.read_complete)
                1'b0        : AFTER_WRITE2;
                1'b1        : AFTER_WRITE3;
            endcase;
            AFTER_WRITE2    : READ_ACK | READ_NAK;                  // Can't have a START/STOP without reading atleast one byte
            AFTER_WRITE3    : START | STOP | READ_ACK | READ_NAK;   // Can't have a WRITE if the operation is a READ
            AFTER_SET_BUS   : START | STOP | SET_BUS | WAIT;
            AFTER_WAIT      : START | SET_BUS | WAIT;

            // Leaf productions
            START       : {
                            this.read_complete = 1'b0;
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_START, curr_rsp);
                            curr_cmd = CMD_START;
                          };
            STOP        : {
                            this.read_complete = 1'b0;
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_STOP, curr_rsp);
                            curr_cmd = CMD_STOP;
                          };
            ADDR        : {
                            this.op = $urandom();
                            generate_wb_transaction_write (DPR_ADDR, {$urandom(), this.op});
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_WRITE, curr_rsp);
                            curr_cmd = CMD_WRITE;
                          };
            READ_ACK    : {
                            bit [7:0] dpr_data;
                            this.read_complete = 1'b1;
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_READ_ACK, curr_rsp); 
                            generate_wb_transaction_read (DPR_ADDR, dpr_data);
                            curr_cmd = CMD_READ_ACK;
                          };
            READ_NAK    : {
                            bit [7:0] dpr_data;
                            this.read_complete = 1'b1;
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_READ_NAK, curr_rsp);
                            generate_wb_transaction_read (DPR_ADDR, dpr_data);
                            curr_cmd = CMD_READ_NAK;   
                          };
            WRITE       : {
                            generate_wb_transaction_write (DPR_ADDR, $urandom());
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_WRITE, curr_rsp);
                            curr_cmd = CMD_WRITE;
                          };
            SET_BUS     : {
                            generate_wb_transaction_write (DPR_ADDR, $urandom_range(0,15));
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_SET_BUS, curr_rsp);
                            curr_cmd = CMD_SET_BUS;
                          };
            WAIT        : {
                            generate_wb_transaction_write (DPR_ADDR, $urandom_range(10, 20));
                            generate_wb_transaction_write_and_rsp (CMDR_ADDR, CMD_WAIT, curr_rsp);
                            curr_cmd = CMD_WAIT;
                          };
        endsequence
    endtask;

    ///////////////////////////////////////////////////////////////////////////
    // Generate a random i2c response to a wishbone WRITE or READ command
    // Possible responses: DON, NAK, AL, ERR
    ///////////////////////////////////////////////////////////////////////////
    local task generate_rand_rsp ();
        bit [7:0] i2c_data[] = {$urandom()};
        randcase
        8   : super.generate_i2c_transaction (i2c_data);
        1   : super.generate_i2c_nak();
        0   : super.generate_i2c_arb_lost();
        endcase
    endtask

    virtual task run ();
        cmd_t prev_cmd = NULL_CMD;
        rsp_t prev_rsp = NULL_RSP;
        cmd_t curr_cmd;
        rsp_t curr_rsp;
        super.init_core();

        `FANCY_BANNER ("BEGIN RANDOM TESTS");

        fork: GENERATE_I2C_TRANSACTION
        forever begin
           generate_rand_rsp();
        end
        join_none

        fork: GENERATE_WB_TRANSACTION
        begin
            // Generate a random command based on the previous command
            for (int i = 0; i < 200; i++) begin
                this.generate_rand_cmd (prev_cmd, prev_rsp, curr_cmd, curr_rsp);
                prev_cmd = curr_cmd;
                prev_rsp = curr_rsp;
            end
        end
        join

        // We could be in between a wishbone START and a repeated START/STOP
        // when we are done generating random wishbone commands. Simulation
        // hangs if we don't terminate wait_for_i2c_transfer
        disable GENERATE_I2C_TRANSACTION;
        `FANCY_BANNER ("END RANDOM TESTS");
    endtask

endclass