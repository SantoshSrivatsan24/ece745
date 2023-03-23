class i2cmb_test extends ncsu_component #(.T(wb_transaction));

    local i2cmb_env_configuration configuration;
    local i2cmb_environment environment;
    local i2cmb_generator_base generators[3];


    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        configuration = new ("cfg");

        environment = new ("env", this);
        environment.set_configuration (configuration);
        environment.build();
        
        // Generates 32 i2c writes
        $cast (generators[0], ncsu_object_factory::create("i2cmb_write_generator"));
        // Generates 32 i2c reads
        $cast (generators[1], ncsu_object_factory::create("i2cmb_read_generator"));
        // Generates 64 alternating writes and reads
        $cast (generators[2], ncsu_object_factory::create("i2cmb_alt_generator"));

        foreach (generators[i]) begin
            generators[i].set_wb_agent (environment.get_wb_agent());
            generators[i].set_i2c_agent (environment.get_i2c_agent());
        end
    endfunction

    virtual task run();
        environment.run();
        foreach (generators[i])
            generators[i].run();
    endtask

endclass