typedef enum bit [2:0] {      
    STATE_IDLE,
    STATE_START,
    STATE_STOP,
    STATE_BUSY,
    STATE_WRITE_BYTE,
    STATE_READ_BYTE
} bus_state_t;

typedef enum bit [2:0] {
    CMD_START       = 3'b100,
    CMD_STOP        = 3'b101,
    CMD_READ_ACK    = 3'b010,
    CMD_READ_NAK    = 3'b011,
    CMD_WRITE       = 3'b001,
    CMD_SET_BUS     = 3'b110,
    CMD_WAIT        = 3'b000
} cmd_t;

typedef enum bit [1:0] {
    CSR_ADDR = 2'h0,
    DPR_ADDR = 2'h1,
    CMDR_ADDR = 2'h2
} addr_t;

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
    cmdr_t cmdr;
} cmdr_u;

class i2cmb_predictor extends ncsu_component #(.T(wb_transaction_base));

    local wb_transaction_base #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans;
    local i2c_transaction #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_trans;

    local bus_state_t current_bus_state;
    local bus_state_t next_bus_state;

    local bit addr_complete;
    local bit [7:0] dpr;
    local i2c_op_t i2c_op;
    local bit [6:0] i2c_addr;
    local bit [7:0] i2c_data[$];

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
        this.i2c_trans = new("predicted_trans");
        this.current_bus_state = STATE_IDLE;
    endfunction

    virtual function void nb_put (input T trans);
        bit transfer_complete;
        this.wb_trans = trans;
        transfer_complete = this.run_golden_model();
        if (transfer_complete) begin
            this.addr_complete = 1'b0;
            this.i2c_trans.op = this.i2c_op;
            this.i2c_trans.addr = this.i2c_addr;
            {>> 8 {this.i2c_trans.data}} = this.i2c_data;
            this.i2c_trans.display();
            this.i2c_data.delete();
        end
    endfunction


    // The predictor models the byte-level FSM in the DUT. 
    // It incrementally constructs an i2c transaction
    local function bit run_golden_model();
        addr_t addr = addr_t'(this.wb_trans.addr);
        cmdr_u data = this.wb_trans.data;
        bit we      = this.wb_trans.we;
        cmdr_t cmdr = data.cmdr;
        bit transfer_complete = 1'b0;

        case (current_bus_state)
        STATE_IDLE: begin
            if(addr == CMDR_ADDR && cmdr.cmd == CMD_START) begin
                next_bus_state = STATE_START;
            end 
            else if(addr == CMDR_ADDR && cmdr.cmd == CMD_SET_BUS) begin
                next_bus_state = STATE_IDLE; 
            end 
            else begin
                next_bus_state = STATE_IDLE;
            end
        end

        STATE_START: begin
            if(cmdr.don) begin
                next_bus_state = STATE_BUSY;
                if (this.addr_complete) // Repeated START
                    transfer_complete = 1'b1;
            end
            else if (cmdr.err || cmdr.al) begin
                next_bus_state = STATE_IDLE;
                $error ("error / arbitration lost");
            end
        end

        STATE_BUSY: begin
            if (addr == DPR_ADDR) begin
                this.dpr = data.value;
                if (!we) // Read data from the BFM is stored in the DPR
                    this.i2c_data.push_back(this.dpr);
            end
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_WRITE) begin
                next_bus_state = STATE_WRITE_BYTE;
            end
            else if (addr == CMDR_ADDR && (cmdr.cmd == CMD_READ_ACK || cmdr.cmd == CMD_READ_NAK)) begin
                next_bus_state = STATE_READ_BYTE;
            end 
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_START) begin
                next_bus_state = STATE_START;
            end
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_STOP) begin
                next_bus_state = STATE_STOP;
            end
            else begin
                $error ("Invalid command");
            end
        end

        STATE_WRITE_BYTE: begin
            if(cmdr.don || cmdr.nak) begin
                next_bus_state = STATE_BUSY;
                if (!this.addr_complete) begin
                    this.addr_complete = 1'b1;
                    this.i2c_op = i2c_op_t'(dpr[0]);
                    this.i2c_addr = this.dpr[7:1];
                end else begin
                    this.i2c_data.push_back(this.dpr);
                end
            end
            else if (cmdr.err || cmdr.al) begin
                next_bus_state = STATE_IDLE;
                $error ("error / arbitration lost");
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
                transfer_complete = 1'b1;
            end
            else begin
                $error ("Invalid command");
            end
        end

        default: $error ("Invalid state");
        endcase

        current_bus_state = next_bus_state;
        return transfer_complete;
    endfunction
endclass