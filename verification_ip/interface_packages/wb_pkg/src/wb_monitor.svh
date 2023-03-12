class wb_monitor extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_bus;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual task run ();
        wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) monitored_trans = new ("monitored_trans");
        wb_bus.wait_for_reset();
        forever begin: MONITOR_WB_BUS
            wb_bus.master_monitor (.addr(monitored_trans.addr), .data(monitored_trans.data), .we(monitored_trans.we));
            if (monitored_trans.we) begin
                $display ("%s wb_monitor::run() (W) Addr = 0x%x Data = 0x%b", get_full_name(), monitored_trans.addr, monitored_trans.data);
            end else begin
                $display ("%s wb_monitor::run() (R) Addr = 0x%x Data = 0x%b", get_full_name(), monitored_trans.addr, monitored_trans.data);
            end
        end
    endtask

endclass