class i2cmb_generator_register_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_register_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 1.1: Validate the default value of each register after a system and core reset
    local task test_reset();
        bit [7:0] csr_value;
        bit [7:0] cmdr_value;
        bit [7:0] dpr_value;
        bit [7:0] fsmr_value;

        generate_wb_transaction_read (CSR_ADDR, csr_value);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_value);
        generate_wb_transaction_read (DPR_ADDR, dpr_value);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_value);

        assert (csr_value   == `CSR_DEFAULT_VALUE)  else $fatal ("Invalid CSR default value: %b", csr_value);
        assert (cmdr_value  == `CMDR_DEFAULT_VALUE) else $fatal ("Invalid CMDR default value: %b", cmdr_value);
        assert (dpr_value   == `DPR_DEFAULT_VALUE)  else $fatal ("Invalid DPR default value: %b", dpr_value);
        assert (fsmr_value  == `FSMR_DEFAULT_VALUE) else $fatal ("Invalid FSMR default value: %b", fsmr_value);
    endtask

    // Testplan 1.3: Read from and write to every register
    // Testplan 1.4: Ensure that read only fields cannot be written
    // Testplan 1.5: Ensure that a write to one register doesn't affect another
    local task test_register_rw();
        bit [7:0] csr_value;
        bit [7:0] cmdr_value;
        bit [7:0] dpr_value;
        bit [7:0] fsmr_value;

        bit [7:0] csr_before, csr_after;
        bit [7:0] cmdr_before, cmdr_after;
        bit [7:0] dpr_before, dpr_after;
        bit [7:0] fsmr_before, fsmr_after;

        ///////////////////////////////////////////////////

        generate_wb_transaction_read (DPR_ADDR, dpr_before);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_before);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_before);

        // CSR
        // 7    6   5   4   3   2   1   0
        // ^    ^   ^   ^   ^   ^   ^   ^
        // rw   rw  ro  ro  ro  ro  ro  ro
        generate_wb_transaction_write (CSR_ADDR, 8'b1111_1111);
        generate_wb_transaction_read (CSR_ADDR, csr_value);
        assert (csr_value == 8'b1100_0000) else $fatal ("Write to read-only CSR field: %b", csr_value);

        generate_wb_transaction_read (DPR_ADDR, dpr_after);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_after);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_after);

        // Ensure that a write to the CSR doesn't affect other registers
        assert (dpr_before == dpr_after) else $fatal ("Write to CSR affects DPR. Before: %b, After: %b", dpr_before, dpr_after);
        assert (cmdr_before == cmdr_after) else $fatal ("Write to CSR affects CMDR. Before: %b, After: %b", cmdr_before, cmdr_after);
        assert (fsmr_before == fsmr_after) else $fatal ("Write to CSR affects FSMR. Before: %b, After: %b", fsmr_before, fsmr_after);

        ///////////////////////////////////////////////////

        generate_wb_transaction_read (CSR_ADDR, csr_before);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_before);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_before);

        // DPR
        // 7    6   5   4   3   2   1   0
        // ^    ^   ^   ^   ^   ^   ^   ^
        // rw   rw  rw  rw  rw  rw  rw  rw
        generate_wb_transaction_write (DPR_ADDR, 8'h1111_1111);
        generate_wb_transaction_read (DPR_ADDR, dpr_value);
        // Reading the DPR returns the last byte received by the I2C bus
        assert (dpr_value == 8'b0000_0000) else $fatal ("Invalid DPR read value: %b", dpr_value);

        generate_wb_transaction_read (CSR_ADDR, csr_after);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_after);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_after);

        // Ensure that a write to the DPR doesn't affect other registers
        assert (csr_before == csr_after) else $fatal ("Write to DPR affects CSR. Before: %b, After: %b", csr_before, csr_after);
        assert (cmdr_before == cmdr_after) else $fatal ("Write to DPR affects CMDR. Before: %b, After: %b", cmdr_before, cmdr_after);
        assert (fsmr_before == fsmr_after) else $fatal ("Write to DPR affects FSMR. Before: %b, After: %b", fsmr_before, fsmr_after);

        ///////////////////////////////////////////////////

        generate_wb_transaction_read (CSR_ADDR, csr_before);
        generate_wb_transaction_read (DPR_ADDR, dpr_before);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_before);

        // CMDR
        // 7    6   5   4   3   2   1   0
        // ^    ^   ^   ^   ^   ^   ^   ^
        // ro   ro  ro  ro  ro  rw  rw  rw
        generate_wb_transaction_write (CMDR_ADDR, 8'b1111_1111);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_value);
        // We should get an error since 111 is an invalid command
        assert (cmdr_value == 8'b0001_0111) else $fatal ("Write to read-only CMDR field: %b", cmdr_value);

        generate_wb_transaction_read (CSR_ADDR, csr_after);
        generate_wb_transaction_read (DPR_ADDR, dpr_after);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_after);

        // Ensure that a write to the CMDR doesn't affect other registers
        assert (csr_before == csr_after) else $fatal ("Write to CMDR affects CSR. Before: %b, After: %b", csr_before, csr_after);
        assert (dpr_before == dpr_after) else $fatal ("Write to CMDR affects DPR. Before: %b, After: %b", dpr_before, dpr_after);
        assert (fsmr_before == fsmr_after) else $fatal ("Write to CMDR affects FSMR. Before: %b, After: %b", fsmr_before, fsmr_after);

        ///////////////////////////////////////////////////

        generate_wb_transaction_read (CSR_ADDR, csr_before);
        generate_wb_transaction_read (DPR_ADDR, dpr_before);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_before);

        // FSMR
        // 7    6   5   4   3   2   1   0
        // ^    ^   ^   ^   ^   ^   ^   ^
        // ro   ro  ro  ro  ro  ro  ro  ro
        generate_wb_transaction_write (FSMR_ADDR, 8'b1111_1111);
        generate_wb_transaction_read (FSMR_ADDR, fsmr_value);
        assert (fsmr_value == 8'b0000_0000) else $fatal ("Write to read-only FSMR field: %b", fsmr_value);

        generate_wb_transaction_read (CSR_ADDR, csr_after);
        generate_wb_transaction_read (DPR_ADDR, dpr_after);
        generate_wb_transaction_read (CMDR_ADDR, cmdr_after);

        // Ensure that a write to the FSMR doesn't affect other registers
        assert (csr_before == csr_after) else $fatal ("Write to FSMR affects CSR. Before: %b, After: %b", csr_before, csr_after);
        assert (dpr_before == dpr_after) else $fatal ("Write to FSMR affects DPR. Before: %b, After: %b", dpr_before, dpr_after);
        assert (cmdr_before == cmdr_after) else $fatal ("Write to FSMR affects CMDR. Before: %b, After: %b", cmdr_before, cmdr_after);
    endtask

    virtual task run ();
        // Test system reset
        this.test_reset();
        this.test_register_rw();
        // Reset core
        generate_wb_transaction_write (CSR_ADDR, 8'b0000_0000);
        // Test core reset
        this.test_reset();
    endtask

endclass