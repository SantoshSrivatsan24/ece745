class i2cmb_environment extends ncsu_component #(.T(i2c_transaction));

    wb_agent agent0;
    i2c_agent agent1;
    i2cmb_predictor predictor;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build ();
        super.build();
        agent0 = new ("wb_agent", this);
        agent0.build();
        agent1 = new ("i2c_agent", this);
        agent1.build();
        predictor = new ("predictor", this);
        predictor.build();
        agent0.connect_subscriber (predictor);
    endfunction

    virtual task run ();
        agent0.run();
        agent1.run();
    endtask

endclass