class wb_transaction extends ncsu_transaction;

    // TODO: Figure out why we call this macro
    // It's so that we can register this object with a factory
    // `ncsu_register_object(wb_transaction)

    bit wb_op;
    bit [6:0] wb_addr;
    bit [7:0] wb_data [];

    function new (string name = "");
        super.new(name);
    endfunction

endclass