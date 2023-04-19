class i2cmb_generator_base extends ncsu_component;

    `ncsu_register_object(i2cmb_generator_base)

    local wb_agent agent_wb;
    local i2c_agent agent_i2c;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    function void set_wb_agent(wb_agent agent);
        this.agent_wb = agent;
    endfunction

    function void set_i2c_agent(i2c_agent agent);
        this.agent_i2c = agent;
    endfunction

    // Generate a wishbone transaction that writes to the DUT
    protected task generate_wb_transaction_write (bit [1:0] wb_addr, bit [7:0] wb_data);
        wb_transaction wb_trans = new ("wb_transaction");
        wb_transaction fsm_trans = new ("fsm_transaction");

        wb_trans.addr = wb_addr;
        wb_trans.data = wb_data;
        agent_wb.bl_put (wb_trans);

        // Generate a wishbone transaction to read the FSMR register
        fsm_trans.addr = FSMR_ADDR;
        agent_wb.bl_get_ref (fsm_trans);
    endtask

    // Generate a wishnbone transaction that reads from the DUT
    protected task generate_wb_transaction_read (bit [1:0] wb_addr, ref bit [7:0] wb_data);
        wb_transaction wb_trans = new ("wb_transaction");
        wb_transaction fsm_trans = new ("fsm_transaction");

        wb_trans.addr = wb_addr;
        agent_wb.bl_get_ref (wb_trans);
        wb_data = wb_trans.data;

        // Generate a wishbone transaction to read the FSMR register
        fsm_trans.addr = FSMR_ADDR;
        agent_wb.bl_get_ref (fsm_trans);
    endtask

    // Generate an empty I2C transaction and pass it to the I2C driver
    protected task generate_i2c_transaction (bit [7:0] i2c_data[]);
        i2c_transaction i2c_trans;
        agent_i2c.bl_get (i2c_trans);
        if (i2c_trans.op == READ) begin
            i2c_trans.data = i2c_data;
            agent_i2c.bl_put (i2c_trans);
            wait (i2c_trans.transfer_complete);
        end
    endtask

    protected task init();
        generate_wb_transaction_write (CSR_ADDR, 8'b11xx_xxxx);
        generate_wb_transaction_write (DPR_ADDR, 8'h00);
        generate_wb_transaction_write (CMDR_ADDR, CMD_SET_BUS);
    endtask

    ///////////////////////////////////////////////////////////////////////////
    // A sequence is a bunch of wishbone transactions between a START and STOP 
    // condition or a START and a repeated START condition. Generate a *single* 
    // I2C transaction for every new sequence.

    // START WRITE STOP
    // START WRITE START    (Repeated START)
    //       READ  START    (READ followed by repeated START)
    //       WRITE STOP     (WRITE followed by repeated START)
    ///////////////////////////////////////////////////////////////////////////
    protected task generate_sequence (seq_type_t seq_type, [6:0] i2c_addr, bit [7:0] i2c_data[]);
        $timeformat(-9, 2, " ns", 0);
        `BANNER($time, {get_full_name(), ": generate sequence of wb_transactions"})
        fork 
        begin
            generate_i2c_transaction (i2c_data);
        end

        begin
            randsequence (main)
                main                :   
                case (seq_type)
                SEQ_START_WRITE_STOP    : START_WRITE_STOP;
                SEQ_START_READ_STOP     : START_READ_STOP;
                SEQ_START_WRITE_START   : START_WRITE_START;
                SEQ_START_READ_START    : START_READ_START;
                SEQ_WRITE_START         : WRITE_START;
                SEQ_READ_START          : READ_START;
                SEQ_WRITE_STOP          : WRITE_STOP;
                SEQ_READ_STOP           : READ_STOP;
                endcase;
                START_WRITE_STOP        :   START ADDR(0)  WDATA STOP;
                START_WRITE_START       :   START ADDR(0)  WDATA START;
                WRITE_STOP              :         ADDR(0)  WDATA STOP;
                WRITE_START             :         ADDR(0)  WDATA START;
                START_READ_STOP         :   START ADDR(1)   RDATA STOP;
                START_READ_START        :   START ADDR(1)   RDATA START;
                READ_STOP               :         ADDR(1)   RDATA STOP;
                READ_START              :         ADDR(1)   RDATA START;
                // Leaf productions
                START                   :   {
                                            generate_wb_transaction_write (CMDR_ADDR, CMD_START); 
                                            };
                ADDR (bit op = 0)       :  {
                                            generate_wb_transaction_write (DPR_ADDR, {i2c_addr, op});
                                            generate_wb_transaction_write (CMDR_ADDR, CMD_WRITE);
                                            };
                WDATA                   :   {
                                            foreach (i2c_data[i]) begin
                                                generate_wb_transaction_write (DPR_ADDR, i2c_data[i]);
                                                generate_wb_transaction_write (CMDR_ADDR, CMD_WRITE);
                                            end
                                            };
                RDATA                   :   {
                                            bit [7:0] dpr_data;
                                            repeat (i2c_data.size() - 1) begin
                                                generate_wb_transaction_write (CMDR_ADDR, CMD_READ_ACK);
                                                // Read the DPR register
                                                generate_wb_transaction_read (DPR_ADDR, dpr_data);
                                            end
                                            // Read with NAK. Signal slave to stop transfer
                                            generate_wb_transaction_write (CMDR_ADDR, CMD_READ_NAK);
                                            // Read the DPR register
                                            generate_wb_transaction_read (DPR_ADDR, dpr_data);
                                            };
                STOP                    :   {
                                            generate_wb_transaction_write (CMDR_ADDR, CMD_STOP); 
                                            };
            endsequence
        end
        join
    endtask;

    virtual task run ();
    endtask

endclass