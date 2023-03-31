class i2c_agent extends ncsu_component #(.T(i2c_transaction));

    local virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) bus;
    local i2c_configuration configuration;
    local i2c_driver driver;
    local i2c_monitor monitor;
    local i2c_coverage coverage;
    local ncsu_component #(T) subscribers[$];

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        if ( !(ncsu_config_db#(virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)))::get(get_full_name(), this.bus))) begin;
            $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
            $finish;
        end 
    endfunction

    function void set_configuration (i2c_configuration cfg);
        this.configuration = cfg;
    endfunction

    virtual function void build();
        super.build();
        driver = new("driver", this);
        driver.set_configuration (this.configuration);
        driver.set_bus (this.bus);
        driver.build();
        
        monitor = new ("monitor", this);
        monitor.set_configuration (this.configuration);
        monitor.set_agent (this);
        monitor.set_bus (this.bus);
        monitor.build();

        coverage = new ("coverage", this);
        coverage.build();
        this.connect_subscriber (coverage);
    endfunction

    virtual task bl_put (input T trans);
        driver.bl_put(trans);
    endtask

    virtual task bl_get (output T trans);
        driver.bl_get(trans);
    endtask


    function void connect_subscriber(ncsu_component #(T) subscriber);
        subscribers.push_back (subscriber);
    endfunction

    virtual function void nb_put(input T trans);
        foreach (subscribers[i]) begin
            subscribers[i].nb_put (trans);
        end
    endfunction

    virtual task run();
        fork
            monitor.run();
        join_none
    endtask

endclass