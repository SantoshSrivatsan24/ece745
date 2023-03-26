class abc_agent extends ncsu_component#(.T(abc_transaction_base));

  abc_configuration configuration;
  abc_driver        driver;
  abc_monitor       monitor;
  abc_coverage      coverage;
  ncsu_component #(T) subscribers[$];
  virtual abc_if    bus;

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual abc_if)::get(get_full_name(), this.bus))) begin;
      $display("abc_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ",get_full_name());
      $finish;
    end
  endfunction

  function void set_configuration(abc_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    driver = new("driver",this);
    driver.set_configuration(configuration);
    driver.build();
    driver.bus = this.bus;
    if ( configuration.collect_coverage) begin
      coverage = new("coverage",this);
      coverage.set_configuration(configuration);
      coverage.build();
      connect_subscriber(coverage);
    end
    monitor = new("monitor",this);
    monitor.set_configuration(configuration);
    monitor.build();
    monitor.bus = this.bus;
  endfunction

  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  virtual task bl_put(T trans);
    driver.bl_put(trans);
  endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  virtual task run();
     fork monitor.run(); join_none
  endtask

endclass


