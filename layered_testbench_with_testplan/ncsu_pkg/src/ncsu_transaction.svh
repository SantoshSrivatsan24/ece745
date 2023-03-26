class ncsu_transaction extends ncsu_object;
  int transaction_id;
  static int transaction_count;

  function new(string name=""); 
    super.new(name);
    this.name = name;
    transaction_id = transaction_count++;
  endfunction

  virtual function string convert2string();
     return $sformatf("name: %s transaction_count: %0d ",name,transaction_id);
  endfunction

endclass
