class wb_monitor extends ncsu_component #(.T(wb_transaction_base));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) bus;
    wb_configuration configuration;
    ncsu_component #(T) agent;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
        // $cast (this.wb_agent, this.parent);
    endfunction

    function void set_configuration (wb_configuration cfg);
        this.configuration = cfg;
    endfunction

    function void set_agent (ncsu_component #(T) agent);
        this.agent = agent;
    endfunction

    virtual task run ();
        T monitored_trans = new ("monitored_trans");
        bus.wait_for_reset();
        forever begin
            bus.master_monitor (.addr(monitored_trans.addr), .data(monitored_trans.data), .we(monitored_trans.we));
            // if (monitored_trans.we) begin
            //     $display ("%s wb_monitor::run() (W) Addr = 0x%x Data = 0b%b", get_full_name(), monitored_trans.addr, monitored_trans.data);
            // end else begin
            //     $display ("%s wb_monitor::run() (R) Addr = 0x%x Data = 0b%b", get_full_name(), monitored_trans.addr, monitored_trans.data);
            // end
            agent.nb_put (monitored_trans);
        end
    endtask

endclass