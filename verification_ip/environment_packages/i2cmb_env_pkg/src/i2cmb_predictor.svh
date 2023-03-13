class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

    local wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual function void nb_put (input T trans);
        $display ("The predictor who is a subscriber to the agent receives a transaction from the wishbone monitor");
        this.wb_trans = trans;
    endfunction

endclass