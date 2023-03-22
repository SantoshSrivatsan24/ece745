class i2c_driver extends ncsu_component #(.T(i2c_transaction));

    virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_bus;
    ncsu_component #(T) i2c_agent;
    local bit [7:0] data [];
 
    function new (string name = "", ncsu_component #(T) parent = null);
        super.new(name, parent);
    endfunction

    function void set_data (input bit [7:0] data[]);
        this.data = data;
    endfunction

    virtual task bl_get(output T trans);
        trans = new ("i2c_trans");
        i2c_bus.wait_for_i2c_transfer (.op(trans.op), .write_data(trans.data));
    endtask

    virtual task bl_put(input T trans);
        i2c_bus.provide_read_data(.read_data(trans.data), .transfer_complete(trans.transfer_complete));
        wait (trans.transfer_complete);
    endtask

endclass