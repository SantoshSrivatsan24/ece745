class wb_monitor extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH (2), .DATA_WIDTH(8)) wb_bus;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

endclass