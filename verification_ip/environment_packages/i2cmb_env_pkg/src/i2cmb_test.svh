class i2cmb_test extends ncsu_component;

    local i2cmb_env_configuration configuration;
    local i2cmb_environment environment;
    local i2cmb_generator_base generator; // was [3]


    function new (string name = "", ncsu_component_base parent = null);
        string gen_name;

        super.new (name, parent);
        if ( !$value$plusargs("GEN_TYPE=%s", gen_name)) begin
            $fatal("FATAL: +GEN_TYPE plusarg not found on command line");
        end
        $display("%m found +GEN_TRANS_TYPE=%s", gen_name);

        configuration = new ("cfg");
        environment = new ("env", this);
        environment.set_configuration (configuration);
        environment.build();
        
        // TODO: Project 3
        $cast (generator, ncsu_object_factory::create(gen_name));
        generator.set_wb_agent (environment.get_wb_agent());
        generator.set_i2c_agent (environment.get_i2c_agent());
    endfunction

    virtual task run();
        environment.run();
        generator.run();
    endtask

endclass