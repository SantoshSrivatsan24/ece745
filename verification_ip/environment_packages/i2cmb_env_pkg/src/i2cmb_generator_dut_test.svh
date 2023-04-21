class i2cmb_generator_dut_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_dut_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 2.3: Ensure that the `BUS ID` field in the CSR matches the selected bus ID
    local task test_bus_id ();
        bit [7:0] csr_value;

        generate_wb_transaction_write (CSR_ADDR, 8'b11xx_xxxx);
        for (byte i = 4'd0; i < 4'd16; i++) begin 
            generate_wb_transaction_write (DPR_ADDR, 8'h00);
            generate_wb_transaction_write (CMDR_ADDR, CMD_SET_BUS);
            generate_wb_transaction_read (CSR_ADDR, csr_value);
            assert (csr_value == i);
        end
    endtask

    

    virtual task run ();

        this.test_bus_id();

        // TODO: Testplan 2.1: i2cmb reset test
        


        // TODO: Testplan 2.14: Ensure that a command issued before a response to a previous command is ignored

    endtask

endclass