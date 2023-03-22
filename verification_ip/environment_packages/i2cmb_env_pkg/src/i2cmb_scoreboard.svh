class i2cmb_scoreboard extends ncsu_component #(.T(i2c_transaction));

    local T actual_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual function void nb_put (input T trans);
        $display({get_full_name()," nb_put: actual transaction ", trans.convert2string()});
        this.actual_trans = trans;
    endfunction

    // My scoreboard receives the expected transaction AFTER the actual transaction
    virtual function void nb_transport(input T input_trans, output T output_trans);
        $display({get_full_name()," nb_transport: expected transaction ", input_trans.convert2string()});
        if (actual_trans.compare(input_trans)) begin
            $display({get_full_name()," i2c_transaction MATCH!"});
        end else begin
            $display({get_full_name()," i2c_transaction MISMATCH!"});
        end
    endfunction

endclass