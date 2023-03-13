class wb_driver extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_bus;
    ncsu_component #(T) wb_agent;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual task bl_put (input T trans);
        bit [7:0] cmdr_rdata;
        if (trans.cmd) begin
            wb_bus.master_write(.addr(trans.addr), .data(trans.data));
            wb_bus.wait_for_interrupt ();
            wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
        end else begin
            wb_bus.master_write(.addr(trans.addr), .data(trans.data));
        end
    endtask

	//////////////////////////////////////////////////////////////////////
endclass