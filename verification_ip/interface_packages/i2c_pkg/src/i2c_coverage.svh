class i2c_coverage extends ncsu_component #(.T(i2c_transaction));

    covergroup i2c_addr_cg with function sample (i2c_op_t op, bit [6:0] addr);
        op  : coverpoint op;
        addr: coverpoint addr;
        op_x_addr: cross op, addr;
    endgroup

    covergroup i2c_data_cg with function sample (i2c_op_t op, bit [7:0] data);
        op  : coverpoint op;
        data: coverpoint data;
        op_x_data: cross op, data;
    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2c_addr_cg = new;
        i2c_data_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        i2c_addr_cg.sample(trans.op, trans.addr);
        foreach (trans.data[i]) begin
            i2c_data_cg.sample (trans.op, trans.data[i]);
        end
    endfunction

endclass