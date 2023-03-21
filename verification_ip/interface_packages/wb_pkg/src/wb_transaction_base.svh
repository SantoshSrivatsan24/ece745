class wb_transaction_base #(
    parameter int ADDR_WIDTH = 2,
    parameter int DATA_WIDTH = 8
) extends ncsu_transaction;

    // Register this object with a factory
    `ncsu_register_object (wb_transaction_base)
    
    bit [ADDR_WIDTH-1:0]    addr;
    bit [DATA_WIDTH-1:0]    data;
    bit                     we;

    function new (string name = "");
        super.new(name);
    endfunction

    function void create (bit [ADDR_WIDTH-1:0] addr, bit [DATA_WIDTH-1:0] data);
        this.addr = addr;
        this.data = data;
    endfunction

    virtual function string convert2string();   
        return $sformatf("Addr = 0x%x, Data = %b", this.addr, this.data);
    endfunction
endclass