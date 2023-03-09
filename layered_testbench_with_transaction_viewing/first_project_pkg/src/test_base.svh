class test_base extends ncsu_component#(.T(abc_transaction_base));

  env_configuration  cfg;
  environment        env;
  generator          gen;


  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    cfg = new("cfg");
    cfg.sample_coverage();
    env = new("env",this);
    env.set_configuration(cfg);
    env.build();
    gen = new("gen",this);
    gen.set_agent(env.get_p0_agent());
  endfunction

  virtual task run();
     env.run();
     gen.run();
  endtask

endclass
