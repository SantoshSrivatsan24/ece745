class wb_agent extends ncsu_component #(.T(wb_transaction_base));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) bus;
    wb_configuration configuration;
    wb_driver driver;
    wb_monitor monitor;
    ncsu_component #(T) subscribers[$];

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        if ( !(ncsu_config_db#(virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)))::get(get_full_name(), this.bus))) begin;
            $display("wb_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
            $finish;
        end 
    endfunction

    function void set_configuration (wb_configuration cfg);
        this.configuration = cfg;
    endfunction

    virtual function void build();
        super.build();
        driver = new("driver", this);
        driver.set_configuration (this.configuration);
        driver.build();
        driver.bus = this.bus;
        
        monitor = new ("monitor", this);
        monitor.set_configuration (this.configuration);
        monitor.set_agent (this);
        monitor.build();
        monitor.bus = this.bus;
    endfunction

    virtual task bl_put (input T trans);
        driver.bl_put(trans);
    endtask

    virtual task bl_get (output T trans);
        driver.bl_get (trans);
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