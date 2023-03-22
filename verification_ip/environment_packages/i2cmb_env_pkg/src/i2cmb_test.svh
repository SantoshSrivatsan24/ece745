class i2cmb_test extends ncsu_component #(.T(wb_transaction_base));

    i2cmb_environment environment;
    i2cmb_generator_base generator;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        environment = new ("env", this);
        environment.build();
        $cast (generator, ncsu_object_factory::create("i2cmb_alt_generator"));
        generator.set_wb_agent (environment.get_wb_agent());
        generator.set_i2c_agent (environment.get_i2c_agent());
    endfunction

    virtual task run();
        environment.run();
        generator.run();
    endtask

endclass