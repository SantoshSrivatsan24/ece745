class ncsu_component#(type T=ncsu_transaction) extends ncsu_object;

  ncsu_component #(T) parent;

  function new(string name="", ncsu_component #(T) parent=null); 
    super.new(name);
    this.parent = parent;
  endfunction

  virtual function string get_name();
    return(name);
  endfunction

  virtual function string get_full_name();
    if ( parent == null ) return (name);
    else                  return ({parent.get_full_name(),".",name});
  endfunction

  virtual function void build();
      ncsu_info("ncsu_component::build()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endfunction

  virtual task run();
      ncsu_info("ncsu_component::run()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endtask

  virtual task bl_put(input T trans); 
    ncsu_info("ncsu_component::bl_put()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endtask

  virtual function void nb_put(input T trans);
    ncsu_info("ncsu_component::nb_put()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endfunction

  virtual task bl_get(output T trans);
    ncsu_info("ncsu_component::bl_get()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endtask

  virtual function void nb_get(output T trans);
    ncsu_info("ncsu_component::nb_get()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endfunction

  virtual task bl_transport(input T input_trans, output T output_trans);
    ncsu_info("ncsu_component::bl_transport()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endtask

  virtual function void nb_transport(input T input_trans, output T output_trans);
    ncsu_info("ncsu_component::nb_transport()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
  endfunction

endclass
