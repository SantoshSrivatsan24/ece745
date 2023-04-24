class i2cmb_generator_32_reads extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_32_reads)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 5.2
    // Round 2: 32 incrementing reads from 100 to 131
    virtual task run ();
        bit [7:0] i2c_data[] = new[32];
        super.init_core();

        `FANCY_BANNER("ROUND 2 BEGIN: 32 incrementing reads from 100 to 131")
        // Data read from the I2C bus
        for (byte i = 8'd0; i < 8'd32; i++) begin
            i2c_data[i] = i + 8'd100;
        end
        // Generate a sequence beginning with a START and ending with
        // a STOP command
        this.generate_sequence (
            .seq_type   (SEQ_START_READ_STOP),
            .i2c_addr   (7'h24), 
            .i2c_data   (i2c_data)
        );
    endtask

endclass