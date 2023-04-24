class wb_driver extends ncsu_component #(.T(wb_transaction));

    local virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) bus;
    local wb_configuration configuration;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    function void set_bus (virtual wb_if #(2, 8) bus);
        this.bus = bus;
    endfunction

    function void set_configuration (wb_configuration cfg);
        this.configuration = cfg;
    endfunction

    virtual task bl_put (input T trans);
        if (trans.addr == CMDR_ADDR) begin
            bus.master_write(.addr(trans.addr), .data(trans.data));
            bus.wait_for_interrupt();
            // Reading the CMDR clears the irq signal and also lets the predictor 
            // know which state to transition to next (based on the response bits)
            bus.master_read (.addr(trans.addr), .data(trans.rsp));
        end else begin
            bus.master_write(.addr(trans.addr), .data(trans.data));
        end
    endtask

    virtual task bl_get (output T trans);
        trans = new ("wb_transaction");
        bus.master_read(.addr(DPR_ADDR), .data(trans.data));
    endtask

    task bl_get_ref (ref T trans);
        bus.master_read(.addr(trans.addr), .data(trans.data));
    endtask

	//////////////////////////////////////////////////////////////////////
endclass