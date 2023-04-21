class i2cmb_generator_dut_operation extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_dut_operation)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 4.2: Read from and write to every possible I2C slave address
    virtual task run ();
        bit [7:0] i2c_data[] = new[1];
        super.init();
        
        // Data written to the I2C bus
        // for (byte i = 8'd0; i < 8'd16; i++) begin
        //     i2c_data[i] = i;
        // end

        i2c_data[0] = 8'd10;

        super.generate_sequence (
            .seq_type   (SEQ_START_WRITE_START),
            .i2c_addr   (7'h00), 
            .i2c_data   (i2c_data)
        );

        for (byte i2c_addr = 7'h00; i2c_addr <= 7'h7f; i2c_addr++) begin
            super.generate_sequence (
                .seq_type   (SEQ_READ_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data)
            );
            super.generate_sequence (
                .seq_type   (SEQ_WRITE_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data)
            );
        end

        super.generate_sequence (
            .seq_type   (SEQ_READ_STOP),
            .i2c_addr   (7'h7f), 
            .i2c_data   (i2c_data)
        );

    endtask

endclass