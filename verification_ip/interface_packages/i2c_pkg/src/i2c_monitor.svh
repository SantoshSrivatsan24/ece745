class i2c_monitor extends ncsu_component #(.T(i2c_transaction));

    virtual i2c_if #(.ADDR_WIDTH(7), .DATA_WIDTH(8)) i2c_bus; 
    ncsu_component #(T) i2c_agent;

    function new (string name = "", ncsu_component_base parent = null);
        super.new();
        $cast(this.i2c_agent, this.parent);
    endfunction

    virtual task run ();
        T monitored_trans = new ("monitored_trans");
        i2c_bus.wait_for_reset();
        forever begin
		    i2c_bus.monitor (.addr(monitored_trans.addr), .op(monitored_trans.op), .data(monitored_trans.data));
            $display ("Op = %s", monitored_trans.op.name);
            $display ("Addr = 0x%x", monitored_trans.addr);
		    $write   ("Data = ");
		    foreach (monitored_trans.data[i]) $write("%0d  ", monitored_trans.data[i]);
		    $display ();
        end
    endtask

endclass