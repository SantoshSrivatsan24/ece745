class i2c_agent extends ncsu_component #(.T(i2c_transaction));

    virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_bus;
    i2c_driver driver;
    i2c_monitor monitor;
    ncsu_component #(T) subscribers[$];

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        if ( !(ncsu_config_db#(virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)))::get(get_full_name(), this.i2c_bus))) begin;
            $display("i2c_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
            $finish;
        end 
    endfunction

    virtual function void build();
        super.build();
        driver = new("driver", this);
        driver.build();
        driver.i2c_bus = this.i2c_bus;
        monitor = new ("monitor", this);
        monitor.build();
        monitor.i2c_bus = this.i2c_bus;
    endfunction

    function void set_data(input bit [7:0] data[]);
        driver.set_data (data);
    endfunction

    virtual task bl_get (output T trans);
        driver.bl_get(trans);
    endtask

    virtual task bl_put (input T trans);
        driver.bl_put(trans);
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