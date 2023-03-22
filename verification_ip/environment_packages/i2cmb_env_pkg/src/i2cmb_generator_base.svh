typedef enum bit [3:0] {      
    SEQ_START_WRITE_STOP,
    SEQ_START_READ_STOP,
    SEQ_START_WRITE_START,
    SEQ_START_READ_START,
    SEQ_WRITE_START,
    SEQ_READ_START,
    SEQ_WRITE_STOP,
    SEQ_READ_STOP
} seq_type_t;

class i2cmb_generator_base extends ncsu_component #(.T(wb_transaction_base));

    `ncsu_register_object(i2cmb_generator_base)

    wb_agent agent_wb;
    i2c_agent agent_i2c;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    function void set_wb_agent(wb_agent agent);
        this.agent_wb = agent;
    endfunction

    function void set_i2c_agent(i2c_agent agent);
        this.agent_i2c = agent;
    endfunction

    // Generate a new wishbone transaction and pass it to the wishbone driver
    local task generate_wb_transaction (bit [1:0] wb_addr, bit [7:0] wb_data);
        T wb_trans;
        $cast (wb_trans, ncsu_object_factory::create("wb_transaction_base"));
        wb_trans.create (wb_addr, wb_data);
        agent_wb.bl_put (wb_trans);
    endtask

    // Generate an empty I2C transaction and pass it to the I2C driver
    local task generate_i2c_transaction (bit [7:0] i2c_data[]);
        i2c_transaction i2c_trans;
        agent_i2c.bl_get (i2c_trans);
        if (i2c_trans.op == 1) begin
            i2c_trans.data = i2c_data;
            agent_i2c.bl_put (i2c_trans);
            wait (i2c_trans.transfer_complete);
        end
    endtask

    local task init();
        generate_wb_transaction (`CSR_ADDR, 8'b11xx_xxxx);
        generate_wb_transaction (`DPR_ADDR, 8'h00);
        generate_wb_transaction (`CMDR_ADDR, `CMD_SET_BUS);
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
    task generate_sequence (seq_type_t seq_type, [6:0] i2c_addr, bit [7:0] i2c_data[]);

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
                START_WRITE_STOP    :   START ADDR(0) WDATA STOP;
                START_READ_STOP     :   START ADDR(1) RDATA STOP;
                START_WRITE_START   :   START ADDR(0) WDATA START;
                START_READ_START    :   START ADDR(1) RDATA START;
                WRITE_STOP          :         ADDR(0) WDATA STOP;
                READ_STOP           :         ADDR(1) RDATA STOP;
                WRITE_START         :         ADDR(0) WDATA START;
                READ_START          :         ADDR(1) RDATA START;
                // Leaf productions
                START               :   {
                                        generate_wb_transaction (`CMDR_ADDR, `CMD_START); 
                                        };
                ADDR (bit op = 0)   :   {
                                        generate_wb_transaction (`DPR_ADDR, {i2c_addr, op});
                                        generate_wb_transaction (`CMDR_ADDR, `CMD_WRITE);
                                        };
                WDATA               :   {
                                        foreach (i2c_data[i]) begin
                                            generate_wb_transaction (`DPR_ADDR, i2c_data[i]);
                                            generate_wb_transaction (`CMDR_ADDR, `CMD_WRITE);
                                        end
                                        };
                RDATA               :   {
                                        T read_trans;
                                        repeat (i2c_data.size() - 1) begin
                                            generate_wb_transaction (`CMDR_ADDR, `CMD_READ_ACK);
                                            // Read the DPR register
                                            agent_wb.bl_get (read_trans);
                                        end
                                        // Read with NAK. Signal slave to stop transfer
                                        generate_wb_transaction (`CMDR_ADDR, `CMD_READ_NACK);
                                        // Read the DPR register
                                        agent_wb.bl_get (read_trans);
                                        };
                STOP                :   {
                                        generate_wb_transaction (`CMDR_ADDR, `CMD_STOP); 
                                        };
            endsequence
        end
        join
    endtask;

    virtual task run ();
        this.init();
    endtask

endclass