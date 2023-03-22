class i2c_driver extends ncsu_component #(.T(i2c_transaction));

    virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) bus;
    i2c_configuration configuration;
 
    function new (string name = "", ncsu_component #(T) parent = null);
        super.new(name, parent);
    endfunction

    function void set_configuration (i2c_configuration cfg);
        this.configuration = cfg;
    endfunction

    virtual task bl_get(output T trans);
        trans = new ("i2c_trans");
        bus.wait_for_i2c_transfer (.op(trans.op), .write_data(trans.data));
    endtask

    virtual task bl_put(input T trans);
        bus.provide_read_data(.read_data(trans.data), .transfer_complete(trans.transfer_complete));
        wait (trans.transfer_complete);
    endtask

endclass