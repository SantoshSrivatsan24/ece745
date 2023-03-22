class i2c_transaction #(
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 8
)extends ncsu_transaction;

    // TODO: Figure out why we call this macro
    // It's so that we can register this object with a factory
    // I don't think we need to register the I2C transaction with the factory
    // Since the generator generates different types of `wb` transactions. Not I2C transactions
    `ncsu_register_object (i2c_transaction)

    i2c_op_t op;
    bit [ADDR_WIDTH-1:0] addr;
    bit [DATA_WIDTH-1:0] data [];
    bit transfer_complete;

    function new (string name = "");
        super.new(name);
    endfunction

    function bit compare (i2c_transaction rhs);
        bit compare_op;
        bit compare_data;
        bit compare_addr;

        compare_op = (this.op == rhs.op);
        compare_addr = (this.addr == rhs.addr); 
        if (this.data.size() != rhs.data.size()) begin
            compare_data = 1'b0;
        end else begin
            for (int i = 0; i < data.size(); i++) begin
                compare_data = (this.data[i] == rhs.data[i]);
                if (!compare_data) break;
            end
        end
        compare = compare_op && compare_addr && compare_data;
    endfunction

    virtual function string convert2string();
        string str;
        $swrite (str, "I2C Op: %s\n", this.op.name);
        $swrite (str, "%sI2C Addr: 0x%x\n", str, this.addr);
        return str;
    endfunction

    function void display();
        $display ("I2C Op = %s", op.name);
        $display ("I2C Addr = 0x%x", addr);
        $write ("I2C Data =");
        foreach (data[i])
            $write (" %0d ", data[i]);
        $display();
    endfunction

endclass