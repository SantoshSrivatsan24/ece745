class i2cmb_alt_generator extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_alt_generator)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    // Round 3: Alternating writes and reads for 64 transfers
    virtual task run ();
        bit [7:0] i2c_data[] = new[1];
        byte wdata = 64;
        byte rdata = 63;

        super.run();

        `FANCY_BANNER("ROUND 3 BEGIN: Alternating writes and reads for 64 transfers")
        i2c_data[0] = wdata;
        // Generate a sequence that begins and ends with a START command
        this.generate_sequence (
            .seq_type   (SEQ_START_WRITE_START),
            .i2c_addr   (7'h24), 
            .i2c_data   (i2c_data)
        );
        for (int i = 0; i < 63; i++) begin
            i2c_data[0] = rdata;
            this.generate_sequence (
                .seq_type   (SEQ_READ_START),
                .i2c_addr   (7'h24), 
                .i2c_data   (i2c_data)
            );
            wdata++;
            rdata--;
            i2c_data[0] = wdata;
            this.generate_sequence (
                .seq_type   (SEQ_WRITE_START),
                .i2c_addr   (7'h24), 
                .i2c_data   (i2c_data)
            );
        end
        i2c_data[0] = rdata;
        this.generate_sequence (
            .seq_type   (SEQ_READ_STOP),
            .i2c_addr   (7'h24), 
            .i2c_data   (i2c_data)
        );
    endtask

endclass