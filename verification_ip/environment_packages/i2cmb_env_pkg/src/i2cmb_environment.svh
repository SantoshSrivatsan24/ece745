class i2cmb_environment extends ncsu_component #(.T(i2c_transaction));

    wb_agent agent;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build ();
        super.build();
        agent = new ("wb_agent", this);
        agent.build();
    endfunction

    virtual task run ();
        agent.run();
    endtask

endclass