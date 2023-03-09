class env_configuration extends ncsu_configuration;

  bit       loopback;
  bit       invert;
  bit [3:0] port_delay;

  covergroup env_configuration_cg;
  	option.per_instance = 1;
    option.name = name;
  	coverpoint loopback;
  	coverpoint invert;
  	coverpoint port_delay;
  endgroup

  function void sample_coverage();
  	env_configuration_cg.sample();
  endfunction
  
  abc_configuration p0_agent_config;
  abc_configuration p1_agent_config;

  function new(string name=""); 
    super.new(name);
    env_configuration_cg = new;
    p0_agent_config = new("p0_agent_config");
    p1_agent_config = new("p1_agent_config");
    p1_agent_config.collect_coverage=0;
    p0_agent_config.sample_coverage();
    p1_agent_config.sample_coverage();
  endfunction

endclass
