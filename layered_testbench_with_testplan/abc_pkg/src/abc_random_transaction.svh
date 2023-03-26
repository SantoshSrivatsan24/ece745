class abc_random_transaction extends abc_transaction_base;
  `ncsu_register_object(abc_random_transaction)

  rand header_type_t     header_type;
  rand header_sub_type_t header_sub_type;
  rand trailer_type_t    trailer_type;
  rand bit [63:0]        data[8];

  bit [3:0] payload_size;
  bit [3:0] payload_index;
  bit [15:0] source_address;
  bit [15:0] destination_address;
  bit [3:0] qos;
  bit [3:0] priorty;

  function new(string name=""); 
    super.new(name);
  endfunction

  constraint header_c { 
             header_type == ROUTING_TABLE  -> header_sub_type inside {CONTROL,RESET};
             header_type == STATISTICS     -> header_sub_type inside {CONTROL,DATA,RESET};
             header_type == PAYLOAD        -> header_sub_type ==      DATA;
             header_type == SECURE_PAYLOAD -> header_sub_type inside {CONTROL,DATA};
             }

  constraint trailer_c { 
             header_sub_type == CONTROL -> trailer_type inside {SYNC,PARITY};
             header_sub_type == DATA    -> trailer_type inside {PARITY,ECC,CRC};
             header_sub_type == RESET   -> trailer_type inside {ZEROS,ONES,SYNC};
             }  

  function void post_randomize();
    header = {header_type,header_sub_type,
              payload_size,payload_index,
              source_address,
              destination_address,
              qos,priorty,trailer_type};
    payload = data;
    case ( trailer_type )
      ZEROS:  trailer = 64'h00000000_00000000;
      ONES:   trailer = 64'hffffffff_ffffffff;
      SYNC:   trailer = 64'ha5a5a5a5_c3c3c3c3;
      PARITY: calculate_parity();
      ECC:    calculate_ecc();
      CRC:    calculate_crc();
    endcase
  endfunction        

  virtual function void calculate_parity();
     // calculate parity on data and place in trailer variable
  endfunction 

  virtual function void calculate_ecc();
     // calculate ecc on data and place in trailer variable
  endfunction 

  virtual function void calculate_crc();
     // calculate crc on data and place in trailer variable
  endfunction          


endclass

