class i2cmb_scoreboard extends ncsu_component #(.T(i2c_transaction));

    local T expected_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // The scoreboard receives the actual transaction AFTER the expected transaction
    virtual function void nb_put (input T trans);
        $display({get_full_name(),"::nb_put: actual i2c transaction ", trans.convert2string()});
        if (expected_trans.compare(trans)) begin
            $display({get_full_name(),": i2c_transaction MATCH!"});
        end else begin
            $display({get_full_name(),": i2c_transaction MISMATCH!"});
        end
    endfunction

    virtual function void nb_transport(input T input_trans, output T output_trans);
        $display({get_full_name(),"::nb_transport: expected i2c transaction ", input_trans.convert2string()});
        this.expected_trans = input_trans;
    endfunction

endclass