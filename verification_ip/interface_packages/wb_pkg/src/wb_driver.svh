class wb_driver extends ncsu_component #(.T(wb_transaction_base));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) bus;
    wb_configuration configuration;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    function void set_configuration (wb_configuration cfg);
        this.configuration = cfg;
    endfunction

    virtual task bl_put (input T trans);
        bit [7:0] cmdr_rdata;
        if (trans.addr == CMDR_ADDR) begin
            bus.master_write(.addr(CMDR_ADDR), .data(trans.data));
            bus.wait_for_interrupt();
            bus.master_read (.addr(CMDR_ADDR), .data(cmdr_rdata));
        end else begin
            bus.master_write(.addr(trans.addr), .data(trans.data));
        end
    endtask

    virtual task bl_get (output T trans);
        trans = new ("read_trans");
        bus.master_read(.addr(DPR_ADDR), .data(trans.data));
    endtask

	//////////////////////////////////////////////////////////////////////
endclass