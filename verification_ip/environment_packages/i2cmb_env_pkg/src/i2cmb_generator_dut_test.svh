class i2cmb_generator_dut_test extends i2cmb_generator_base;

    `ncsu_register_object(i2cmb_generator_dut_test)

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual task run ();

        // TODO: Testplan 2.1: i2cmb reset test
        // TODO: Testplan 2.4: i2cmb bus ID test
        // TODO: Testplan 2.14: i2cmb response reception

    endtask

endclass