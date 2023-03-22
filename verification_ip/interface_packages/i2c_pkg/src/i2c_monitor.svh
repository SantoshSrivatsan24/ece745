class i2c_monitor extends ncsu_component #(.T(i2c_transaction));

    virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) bus; 
    i2c_configuration configuration;
    ncsu_component #(T) agent;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    function void set_configuration (i2c_configuration cfg);
        this.configuration = cfg;
    endfunction

    function void set_agent (ncsu_component #(T) agent);
        this.agent = agent;
    endfunction

    virtual task run ();
        T monitored_trans = new ("monitored_trans");
        bus.wait_for_reset();
        forever begin
		    bus.monitor (.addr(monitored_trans.addr), .op(monitored_trans.op), .data(monitored_trans.data));
            agent.nb_put (monitored_trans);
        end
    endtask

endclass