class i2cmb_environment extends ncsu_component #(.T(i2c_transaction));

    wb_agent agent_wb;
    i2c_agent agent_i2c;
    i2cmb_predictor predictor;
    i2cmb_scoreboard scoreboard;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build ();
        super.build();
        agent_wb = new ("wb_agent", this);
        agent_wb.build();
        agent_i2c = new ("i2c_agent", this);
        agent_i2c.build();
        predictor = new ("predictor", this);
        predictor.build();
        scoreboard = new ("scoreboard", this);
        scoreboard.build();
        predictor.set_scoreboard (scoreboard);
        agent_wb.connect_subscriber (predictor);
        agent_i2c.connect_subscriber (scoreboard);
    endfunction

    virtual task run ();
        agent_wb.run();
        agent_i2c.run();
    endtask

    function wb_agent get_wb_agent();
        return agent_wb;
    endfunction

    function i2c_agent get_i2c_agent();
        return agent_i2c;
    endfunction

endclass