typedef enum bit [2:0] {      
    STATE_IDLE,
    STATE_START,
    STATE_STOP,
    STATE_BUSY,
    STATE_WRITE_BYTE,
    STATE_READ_BYTE
} bus_state_t;

typedef enum bit [1:0] {
    STATE_WAIT_START_STOP,
    STATE_CAPTURE_ADDR,
    STATE_CAPTURE_DATA
} i2c_state_t;

typedef enum bit [2:0] {
    CMD_START       = 3'b100,
    CMD_STOP        = 3'b101,
    CMD_READ_ACK    = 3'b010,
    CMD_READ_NAK    = 3'b011,
    CMD_WRITE       = 3'b001,
    CMD_SET_BUS     = 3'b110,
    CMD_WAIT        = 3'b000
} cmd_t;

typedef struct packed {
    bit don;
    bit nak;
    bit al;
    bit err;
    bit r;
    cmd_t cmd;
} cmdr_t;

typedef union packed {
    byte value;
    cmdr_t fields;
} cmdr_u;

class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

    local wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans;
    local i2c_transaction #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_trans;

    local bus_state_t current_bus_state;
    local bus_state_t next_bus_state;

    local i2c_state_t current_i2c_state;
    local i2c_state_t next_i2c_state;

    local bit [7:0] dpr;
    local bit got_addr;
    local i2c_op_t i2c_op;
    local bit [6:0] i2c_addr;
    local bit [7:0] i2c_data[$];
    local bit transfer_complete;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
        this.i2c_trans = new("predicted_trans");
        this.current_bus_state = STATE_IDLE;
    endfunction

    virtual function void nb_put (input T trans);
        this.wb_trans = trans;
        this.run_golden_model();
        if (this.transfer_complete) begin
            this.transfer_complete = 1'b0;
            this.i2c_trans.op = this.i2c_op;
            this.i2c_trans.addr = this.i2c_addr;
            {>> 8 {this.i2c_trans.data}} = this.i2c_data;
            this.i2c_trans.display();
            this.i2c_data.delete();
        end
    endfunction

    // TODO: This function should modify i2c trans based on wb trans
    // I have to basically implement the entire i2c protocol in a 
    // non blocking fashion.
    // The predictor models the DUT. It incrementally constructs
    // an i2c transaction
    local function void run_golden_model();
        cmdr_u cmdr_value;
        cmdr_t cmdr;

        // Read the DPR register
        if (this.wb_trans.addr == 2'h1) begin
            this.dpr = this.wb_trans.data;
            if (this.wb_trans.we == 1'b0) begin
                i2c_data.push_back(dpr);
            end
        end

        // Read the CMDR register
        else if (this.wb_trans.addr == 2'h2) begin
            cmdr_value  = this.wb_trans.data;
            cmdr        = cmdr_value.fields;

            case (current_bus_state)
            STATE_IDLE: begin
                if(cmdr.cmd == CMD_START) begin
                    next_bus_state = STATE_START;
                end 
                else if(cmdr.cmd == CMD_SET_BUS) begin
                    next_bus_state = STATE_IDLE; 
                end 
                else begin
                    $error ("Invalid command");
                end
            end

            STATE_START: begin
                // Successful START condition
                if(cmdr.don) begin
                    next_bus_state = STATE_BUSY;
                    if (this.got_addr) this.transfer_complete = 1'b1;
                    this.got_addr = 1'b0;
                end
                // Unsuccessful START condition
                else if (cmdr.err || cmdr.al) begin
                    next_bus_state = STATE_IDLE;
                end
                else begin
                    $error ("Invalid command");
                end
            end

            STATE_BUSY: begin
                if (cmdr.cmd == CMD_WRITE) begin
                    next_bus_state = STATE_WRITE_BYTE;
                end
                else if (cmdr.cmd == CMD_READ_ACK || cmdr.cmd == CMD_READ_NAK) begin
                    next_bus_state = STATE_READ_BYTE;
                end 
                else if (cmdr.cmd == CMD_START) begin
                    next_bus_state = STATE_START;
                end
                else if (cmdr.cmd == CMD_STOP) begin
                    next_bus_state = STATE_STOP;
                end
                else begin
                    $error ("Invalid command");
                end
            end

            STATE_WRITE_BYTE: begin
                if(cmdr.don || cmdr.nak) begin
                    next_bus_state = STATE_BUSY;
                    if (!this.got_addr) begin
                        this.got_addr   = 1'b1;
                        this.i2c_op     = i2c_op_t'(dpr[0]);
                        this.i2c_addr   = this.dpr[7:1];
                    end else begin
                        this.i2c_data.push_back(dpr);
                    end
                end
                else if (cmdr.err || cmdr.al) begin
                    next_bus_state = STATE_IDLE;
                end
                else begin
                    $error ("Invalid command");
                end
            end

            STATE_READ_BYTE: begin
                if (cmdr.don) begin
                    next_bus_state = STATE_BUSY;
                end
                else if (cmdr.err || cmdr.al) begin
                    next_bus_state = STATE_IDLE;
                end
                else begin
                    $error ("Invalid command");
                end
            end

            STATE_STOP: begin
                if (cmdr.don) begin
                    next_bus_state = STATE_IDLE;
                    this.transfer_complete = 1'b1;
                    this.got_addr = 1'b0;
                end
                else begin
                    $error ("Invalid command");
                end
            end

            default: $error ("Invalid state");
            endcase

            // $display ("Current bus state: %s", current_bus_state.name);
            // $display ("Next bus state: %s", next_bus_state.name);
            current_bus_state = next_bus_state;
        end
    endfunction


endclass