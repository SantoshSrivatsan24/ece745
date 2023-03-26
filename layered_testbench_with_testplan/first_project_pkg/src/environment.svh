class environment extends ncsu_component#(.T(abc_transaction_base));

  env_configuration configuration;
  abc_agent         p0_agent,p1_agent;
  predictor         pred;
  scoreboard        scbd;
  coverage          coverage;

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    p0_agent = new("p0_agent",this);
    p0_agent.set_configuration(configuration.p0_agent_config);
    p0_agent.build();
    p1_agent = new("p1_agent",this);
    p1_agent.set_configuration(configuration.p1_agent_config);
    p1_agent.build();
    pred  = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd  = new("scbd", this);
    scbd.build();
    coverage = new("coverage", this);
    coverage.set_configuration(configuration);
    coverage.build();
    p0_agent.connect_subscriber(coverage);
    p0_agent.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    p1_agent.connect_subscriber(scbd);
  endfunction

  function ncsu_component#(T) get_p0_agent();
    return p0_agent;
  endfunction

  function ncsu_component#(T) get_p1_agent();
    return p1_agent;
  endfunction

  virtual task run();
     p0_agent.run();
     p1_agent.run();
  endtask

endclass
