class i2cmb_generator_i2c_operation extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_i2c_operation)
    
    rand bit [7:0] i2c_data[];

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 4.2: Read from and write to every possible I2C slave address
    // Testplan 4.3: Read and write every possible value of data
    virtual task run ();

        super.init();
        i2c_data = new[32];
        
        randomize (i2c_data);
        super.generate_sequence (
            .seq_type   (SEQ_START_WRITE_START),
            .i2c_addr   (7'h00), 
            .i2c_data   (i2c_data)
        );

        for (byte i2c_addr = 7'h00; i2c_addr <= 7'h7f; i2c_addr++) begin
            randomize (i2c_data);
            super.generate_sequence (
                .seq_type   (SEQ_READ_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data)
            );
            randomize (i2c_data);
            super.generate_sequence (
                .seq_type   (SEQ_WRITE_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data)
            );
        end

        randomize (i2c_data);
        super.generate_sequence (
            .seq_type   (SEQ_READ_STOP),
            .i2c_addr   (7'h7f), 
            .i2c_data   (i2c_data)
        );
    endtask

endclass