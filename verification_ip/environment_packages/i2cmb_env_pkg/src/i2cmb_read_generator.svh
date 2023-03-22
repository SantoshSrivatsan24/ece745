class i2cmb_read_generator extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_read_generator)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2c_rdata = new[32];
        for (byte i = 8'd0; i < 8'd32; i++) begin
            i2c_rdata[i] = i + 8'd100;
        end
    endfunction

    virtual task run ();
        // // 32 incrementing reads from 100 to 131
        // agent_i2c.set_data(i2c_rdata);
        // generate_transaction (`CSR_ADDR, 8'b11xx_xxxx);
        // generate_transaction (`DPR_ADDR, 8'h00);
        // generate_transaction (`CMDR_ADDR, `CMD_SET_BUS);
        // generate_transaction (`CMDR_ADDR, `CMD_START);
        // generate_transaction (`DPR_ADDR, `SLAVE_ADDR | 8'h1);
        // generate_transaction (`CMDR_ADDR, `CMD_WRITE);
        // repeat (31) begin
        //     generate_transaction (`CMDR_ADDR, `CMD_READ_ACK);
        //     agent_wb.bl_get (wb_trans);
        // end
        // generate_transaction (`CMDR_ADDR, `CMD_READ_NACK);
        // agent_wb.bl_get (wb_trans);
        // generate_transaction (`CMDR_ADDR, `CMD_STOP);
    endtask

endclass