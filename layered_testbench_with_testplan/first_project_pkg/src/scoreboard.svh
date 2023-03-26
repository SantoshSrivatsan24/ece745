class scoreboard extends ncsu_component#(.T(abc_transaction_base));
  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
  endfunction

  T trans_in;
  T trans_out;

  virtual function void nb_transport(input T input_trans, output T output_trans);
    $display({get_full_name()," nb_transport: expected transaction ",input_trans.convert2string()});
    this.trans_in = input_trans;
    output_trans = trans_out;
  endfunction

  virtual function void nb_put(T trans);
    $display({get_full_name()," nb_put: actual transaction ",trans.convert2string()});
    if ( this.trans_in.compare(trans) ) $display({get_full_name()," abc_transaction MATCH!"});
    else                                $display({get_full_name()," abc_transaction MISMATCH!"});
  endfunction
endclass


