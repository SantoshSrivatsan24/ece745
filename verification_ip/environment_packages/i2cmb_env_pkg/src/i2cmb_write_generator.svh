class i2cmb_write_generator extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_write_generator)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual task run ();
        // 32 incrementing writes from 0 to 31
        // generate_transaction (`CSR_ADDR, 8'b11xx_xxxx);
        // generate_transaction (`DPR_ADDR, 8'h00);
        // generate_transaction (`CMDR_ADDR, `CMD_SET_BUS);
        // generate_transaction (`CMDR_ADDR, `CMD_START);
        // generate_transaction (`DPR_ADDR, `SLAVE_ADDR);
        // generate_transaction (`CMDR_ADDR, `CMD_WRITE);
        // for (byte wdata = 8'd0; wdata < 8'd32; wdata++) begin
        //     generate_transaction (`DPR_ADDR, wdata);
        //     generate_transaction (`CMDR_ADDR, `CMD_WRITE);
        // end
        // generate_transaction (`CMDR_ADDR, `CMD_STOP);
    endtask

endclass