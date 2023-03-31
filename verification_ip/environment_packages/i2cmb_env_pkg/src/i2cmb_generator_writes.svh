class i2cmb_generator_writes extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_writes)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Testplan 5.1
    // Round 1: 32 incrementing writes from 0 to 31
    virtual task run ();
        bit [7:0] i2c_data[] = new[32];
        super.init();
        
        `FANCY_BANNER("ROUND 1 BEGIN: 32 incrementing writes from 0 to 31")
        // Data written to the I2C bus
        for (byte i = 8'd0; i < 8'd32; i++) begin
            i2c_data[i] = i;
        end
        // Generate a sequence beginning with a START and ending with
        // a STOP command
        this.generate_sequence (
            .seq_type   (SEQ_START_WRITE_STOP),
            .i2c_addr   (7'h24), 
            .i2c_data   (i2c_data)
        );

    endtask

endclass