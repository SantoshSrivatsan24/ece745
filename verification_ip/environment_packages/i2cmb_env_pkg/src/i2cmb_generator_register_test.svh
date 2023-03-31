class i2cmb_generator_register_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_register_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 1.1: i2cmb register default values
    local task test_system_reset();
        bit [7:0] reg_value;

        generate_wb_transaction_read (CSR_ADDR, reg_value);
        default_CSR_value: assert (reg_value == 8'h00) $display ("CSR PASS!"); else $fatal ("CSR FAIL: %b", reg_value);
        generate_wb_transaction_read (CMDR_ADDR, reg_value);
        default_CMDR_value: assert (reg_value == 8'h80) $display ("CMDR PASS!"); else $fatal ("CMDR FAIL: %b", reg_value);
        generate_wb_transaction_read (DPR_ADDR, reg_value);
        default_DPR_value: assert (reg_value == 8'h00) $display ("DPR PASS!"); else $fatal ("DPR FAIL: %b", reg_value);
    endtask

    virtual task run ();

        this.test_system_reset();

        // TODO: Testplan 1.2: i2cmb register address check
        // TODO: Testplan 1.3: i2cmb register read write
        // TODO: Testplan 1.4: i2cmb register access permissions enforced
        // TODO: Testplan 1.5: i2cmb register aliasing

    endtask

endclass