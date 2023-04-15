class i2cmb_generator_register_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_register_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 1.1: i2cmb register default values
    local task test_system_reset();
        bit [7:0] csr_value;
        bit [7:0] cmdr_value;
        bit [7:0] dpr_value;
        bit [7:0] fsmr_value;

        generate_wb_transaction_read (CSR_ADDR, csr_value);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_value);
        generate_wb_transaction_read (DPR_ADDR, dpr_value);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_value);

        assert (csr_value == `CSR_DEFAULT_VALUE)    else $fatal ("ERR: Invalid CSR default value%b", csr_value);
        assert (cmdr_value == `CMDR_DEFAULT_VALUE)  else $fatal ("ERR: Invalid CMDR default value: %b", cmdr_value);
        assert (dpr_value == `DPR_DEFAULT_VALUE)    else $fatal ("ERR: Invalid DPR default value: %b", dpr_value);
        assert (fsmr_value == `FSMR_DEFAULT_VALUE)  else $fatal ("ERR: Invalid FSMR default value %b", fsmr_value);
    endtask

    local task test_register_addr();


    endtask

    virtual task run ();

        this.test_system_reset();

        // TODO: Testplan 1.2: i2cmb register address check
        // TODO: Testplan 1.3: i2cmb register read write
        // TODO: Testplan 1.4: i2cmb register access permissions enforced
        // TODO: Testplan 1.5: i2cmb register aliasing

    endtask

endclass