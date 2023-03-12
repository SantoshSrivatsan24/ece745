class wb_agent extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_bus;
    wb_driver driver;
    wb_monitor monitor;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        if ( !(ncsu_config_db#(virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)))::get(get_full_name(), this.wb_bus))) begin;
            $display("abc_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
            $finish;
        end 
    endfunction

    virtual function void build();
        driver = new("driver", this);
        driver.build();
        driver.wb_bus = this.wb_bus;
        monitor = new ("monitor", this);
        monitor.build();
        monitor.wb_bus = this.wb_bus;
    endfunction

    virtual task bl_put (T trans);
        driver.bl_put(trans);
    endtask

    virtual task run();
        fork
            monitor.run();
        join_none
    endtask

endclass