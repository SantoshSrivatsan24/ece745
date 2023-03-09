class abc_driver extends ncsu_component#(.T(abc_transaction_base));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual abc_if bus;
  abc_configuration configuration;
  abc_transaction_base abc_trans;

  function void set_configuration(abc_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    $display({get_full_name()," ",trans.convert2string()});
    bus.drive(trans.header, 
              trans.payload, 
              trans.trailer, 
              trans.delay
              );
  endtask

endclass
