class i2c_coverage extends ncsu_component #(.T(i2c_transaction));

    covergroup i2c_addr_cg with function sample (i2c_op_t op, bit [6:0] addr);

        op  : coverpoint op;
        addr: coverpoint addr;

        // TODO: Testplan 4.2
        op_x_addr: cross op, addr
        {

        }
        // // TODO: Testplan 4.3
        // op_x_data: cross op, data
        // {

        // }
        // // TODO: Testplan 4.4
        // op_x_addr_x_data: cross op, addr, data
        // {

        // }

    endgroup

    covergroup i2c_data_cg with function sample (bit [7:0] data);
        data: coverpoint data;
    endgroup


    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2c_addr_cg = new;
        i2c_data_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        i2c_addr_cg.sample(trans.op, trans.addr);
        foreach (trans.data[i]) begin
            i2c_data_cg.sample (trans.data[i]);
        end
    endfunction

endclass