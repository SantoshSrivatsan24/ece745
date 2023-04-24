class rand_data;
    rand bit [7:0] data[];

    constraint data_size {
        data.size() inside {[1:48]};
    }

    constraint data_unique {
        unique {data};
    }
endclass

class i2cmb_generator_i2c_operation extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_i2c_operation)
    
    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 4.2: Read from and write to every possible I2C slave address
    // Testplan 4.3: Read and write every possible value of data
    virtual task run ();
        rand_data i2c_data = new();
        super.init_core();
        
        `FANCY_BANNER ("BEGIN I2C OPERATION TEST")
        void'(i2c_data.randomize());
        super.generate_sequence (
            .seq_type   (SEQ_START_WRITE_START),
            .i2c_addr   (7'h00), 
            .i2c_data   (i2c_data.data)
        );

        for (byte i2c_addr = 7'h00; i2c_addr <= 7'h7f; i2c_addr++) begin
            void'(i2c_data.randomize());
            super.generate_sequence (
                .seq_type   (SEQ_READ_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data.data)
            );
            void'(i2c_data.randomize());
            super.generate_sequence (
                .seq_type   (SEQ_WRITE_START),
                .i2c_addr   (i2c_addr), 
                .i2c_data   (i2c_data.data)
            );
        end
        void'(i2c_data.randomize());
        super.generate_sequence (
            .seq_type   (SEQ_READ_STOP),
            .i2c_addr   (7'h7f), 
            .i2c_data   (i2c_data.data)
        );
        `FANCY_BANNER ("END I2C OPERATION TEST")
    endtask

endclass