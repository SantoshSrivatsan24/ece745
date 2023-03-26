class abc_random_statistics_transaction extends abc_random_transaction;
  `ncsu_register_object(abc_random_statistics_transaction)

  constraint header_statistics_c { 
             header_type == STATISTICS;
             }         

  function new(string name=""); 
    super.new(name);
  endfunction

endclass

