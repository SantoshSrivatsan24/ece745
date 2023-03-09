class i2c_driver extends ncsu_component #(.T(i2c_transaction));

    // virtual i2c_if i2c_bus;
    // bit [7:0] i2c_data[];
 
    // function new (string name = "", ncsu_component #(T) parent = null);
    //     super.new(name, parent);
    // endfunction

    // function void set_data (bit [7:0] data []);
    //     i2c_data = data;
    // endfunction

    // virtual task bl_get (output T trans);
    //     i2c_bus.wait_for_i2c_transfer (.op(trans.i2c_op), .write_data(trans.i2c_data));
    //     if (trans.i2c_op == 1) begin
    //         i2c_bus.provide_read_data(.read_data(i2c_data), .transfer_complete(trans.transfer_complete));
    //     end
    // endtask

endclass