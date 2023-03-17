class i2cmb_generator extends ncsu_component #(.T(wb_transaction));

    T transactions[9];
    wb_agent agent_wb;
    i2c_agent agent_i2c;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual task run();
        // $cast(transactions[0], ncsu_object_factory::create("wb_trans"));
        transactions[0] = new("wb_trans");
        transactions[0].create (0, `CSR_ADDR, 8'b11xx_xxxx);
        agent_wb.bl_put (transactions[0]);

        // $cast(transactions[1], ncsu_object_factory::create("wb_trans"));
        transactions[1] = new("wb_trans");
        transactions[1].create (0, `DPR_ADDR, 8'h00);
        agent_wb.bl_put (transactions[1]);

        // $cast(transactions[2], ncsu_object_factory::create("wb_trans"));
        transactions[2] = new("wb_trans");
        transactions[2].create(1, `CMDR_ADDR, `CMD_SET_BUS);
        agent_wb.bl_put (transactions[2]);

        // $cast(transactions[3], ncsu_object_factory::create("wb_trans"));
        transactions[3] = new("wb_trans");
        transactions[3].create(1, `CMDR_ADDR, `CMD_START);
        agent_wb.bl_put (transactions[3]);

        // $cast(transactions[4], ncsu_object_factory::create("wb_trans"));
        transactions[4] = new("wb_trans");
        transactions[4].create(0, `DPR_ADDR, `SLAVE_ADDR);
        agent_wb.bl_put (transactions[4]);

        // $cast(transactions[5], ncsu_object_factory::create("wb_trans"));
        transactions[5] = new("wb_trans");
        transactions[5].create(1, `CMDR_ADDR, `CMD_WRITE);
        agent_wb.bl_put (transactions[5]);

        // $cast(transactions[6], ncsu_object_factory::create("wb_trans"));
        transactions[6] = new("wb_trans");
        transactions[6].create(0, `DPR_ADDR, 8'hab);
        agent_wb.bl_put (transactions[6]);

        // $cast(transactions[7], ncsu_object_factory::create("wb_trans"));
        transactions[7] = new("wb_trans");
        transactions[7].create(1, `CMDR_ADDR, `CMD_WRITE);
        agent_wb.bl_put (transactions[7]);

        // $cast(transactions[8], ncsu_object_factory::create("wb_trans"));
        transactions[8] = new("wb_trans");
        transactions[8].create(1, `CMDR_ADDR, `CMD_STOP);
        agent_wb.bl_put (transactions[8]);
    endtask

    function void set_wb_agent(wb_agent agent);
        this.agent_wb = agent;
    endfunction

    function void set_i2c_agent(i2c_agent agent);
        this.agent_i2c = agent;
    endfunction
endclass