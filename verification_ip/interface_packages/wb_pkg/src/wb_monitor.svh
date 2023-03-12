class wb_monitor extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_bus;
    // local wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
        // if ( !(ncsu_config_db#(virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)))::get(get_full_name(), this.wb_bus))) begin;
        //     $display("abc_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
        //     $finish;
        // end 
    endfunction

    virtual task run ();
        automatic bit wb_we;
        wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans = new ("wb_trans");
        wb_bus.wait_for_reset();
        forever begin: MONITOR_WB_BUS
            wb_bus.master_monitor (.addr(wb_trans.addr), .data(wb_trans.data), .we(wb_we));
            if (wb_we) begin
                $display ("%s wb_monitor::run() (W) Addr = 0x%x Data = 0x%b", get_full_name(), wb_trans.addr, wb_trans.data);
            end else begin
                $display ("%s wb_monitor::run() (R) Addr = 0x%x Data = 0x%b", get_full_name(), wb_trans.addr, wb_trans.data);
            end
        end
    endtask

endclass