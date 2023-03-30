class i2cmb_generator_register_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_register_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    local task test_system_reset();
        bit [7:0] reg_value;

        generate_wb_transaction_read (CSR_ADDR, reg_value);
        assert (reg_value == 8'h00) $display ("CSR PASS!"); else $fatal ("CSR FAIL: %b", reg_value);
        generate_wb_transaction_read (CMDR_ADDR, reg_value);
        assert (reg_value == 8'h80) $display ("CMDR PASS!"); else $fatal ("CMDR FAIL: %b", reg_value);
        generate_wb_transaction_read (DPR_ADDR, reg_value);
        assert (reg_value == 8'h00) $display ("DPR PASS!"); else $fatal ("DPR FAIL: %b", reg_value);
    endtask

    // Round 1: 32 incrementing writes from 0 to 31
    virtual task run ();

        this.test_system_reset();

        // TODO: 1.1: i2cmb address check
        // TODO: 1.2: i2cmb command 
        // TODO: 1.3: i2cmb register access permissions enforced

    endtask

endclass