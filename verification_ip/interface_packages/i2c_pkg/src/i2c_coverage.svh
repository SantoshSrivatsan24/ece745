class i2c_coverage extends ncsu_component #(.T(i2c_transaction));

    bit [6:0] addr;
    bit [7:0] data;
    bit op;

    covergroup i2c_transaction_cg;

        op: coverpoint op
        {

        }

        addr: coverpoint addr
        {

        }

        data: coverpoint data
        {

        }
        // TODO: Testplan 4.2
        op_x_addr: cross op, addr
        {

        }
        // TODO: Testplan 4.3
        op_x_data: cross op, data
        {

        }
        // TODO: Testplan 4.4
        op_x_addr_x_data: cross op, addr, data
        {

        }

    endgroup


    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2c_transaction_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        i2c_transaction_cg.sample();
    endfunction

endclass