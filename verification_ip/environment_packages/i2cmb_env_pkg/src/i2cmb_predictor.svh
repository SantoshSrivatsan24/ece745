class i2cmb_predictor extends ncsu_component #(.T(wb_transaction));

    local wb_transaction #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_trans;
    local i2c_transaction #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new(name, parent);
    endfunction

    virtual function void nb_put (input T trans);
        this.wb_trans = trans;
        this.predict();
    endfunction

    // TODO: This function should modify i2c trans based on wb trans
    // I have to basically implement the entire i2c protocol in a 
    // non blocking fashion.
    // The predictor models the DUT. It incrementally constructs
    // an i2c transaction
    local function void predict();
    endfunction

endclass