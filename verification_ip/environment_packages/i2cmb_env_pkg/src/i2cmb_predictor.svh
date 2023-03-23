class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

    local i2cmb_scoreboard scoreboard;
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
        this.i2c_trans = new("expected_trans");
        this.current_bus_state = STATE_IDLE;
    endfunction

    function void set_scoreboard (i2cmb_scoreboard scbd);
        this.scoreboard = scbd;
    endfunction

    // Receive a wb transaction from the wb agent and incrementally
    // construct an i2c transaction
    virtual function void nb_put (input T trans);

        bit transfer_complete = this.run_golden_model(trans);
        if (transfer_complete) begin
            this.addr_complete = 1'b0;
            this.i2c_trans.op = this.i2c_op;
            this.i2c_trans.addr = this.i2c_addr;
            {>> 8 {this.i2c_trans.data}} = this.i2c_data;;
            this.i2c_data.delete();
            this.scoreboard.nb_transport (this.i2c_trans, this.i2c_trans);
            this.i2c_trans = new ("expected_trans");
        end
    endfunction


    // The predictor models the byte-level FSM in the DUT. 
    // It incrementally constructs an i2c transaction
    local function bit run_golden_model(input T trans);
        addr_t addr = addr_t'(trans.addr);
        cmdr_u data = trans.data;
        bit    we   = trans.we;
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
            end
            else if (cmdr.err || cmdr.al) begin
                next_bus_state = STATE_IDLE;
                $error ("error / arbitration lost");
            end
        end

        STATE_BUSY: begin
            if (addr == DPR_ADDR) begin
                this.dpr = data.value;
                // Read data from the BFM is stored in the DPR
                if (!we) 
                    this.i2c_data.push_back(this.dpr);
            end
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_WRITE) begin
                next_bus_state = STATE_WRITE_BYTE;
                if (!this.addr_complete) begin
                    this.addr_complete = 1'b1;
                    this.i2c_op = i2c_op_t'(dpr[0]);
                    this.i2c_addr = this.dpr[7:1];
                end else begin
                    this.i2c_data.push_back(this.dpr);
                end
            end
            else if (addr == CMDR_ADDR && (cmdr.cmd == CMD_READ_ACK || cmdr.cmd == CMD_READ_NAK)) begin
                next_bus_state = STATE_READ_BYTE;
            end 
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_START) begin
                next_bus_state = STATE_START;
                if (this.addr_complete) // Repeated START
                    transfer_complete = 1'b1;
            end
            else if (addr == CMDR_ADDR && cmdr.cmd == CMD_STOP) begin
                next_bus_state = STATE_STOP;
                transfer_complete = 1'b1;
            end
            else begin
                $error ("Invalid command");
            end
        end

        STATE_WRITE_BYTE: begin
            if(cmdr.don || cmdr.nak) begin
                next_bus_state = STATE_BUSY;
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