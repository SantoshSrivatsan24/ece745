class abc_randseq_transaction extends abc_transaction_base;
  `ncsu_register_object(abc_randseq_transaction)

       header_type_t     header_type;
       header_sub_type_t header_sub_type;
       trailer_type_t    trailer_type;
  rand bit [63:0]        payload_data[8];

  bit [3:0] payload_size;
  bit [3:0] payload_index;
  bit [15:0] source_address;
  bit [15:0] destination_address;
  bit [3:0] qos;
  bit [3:0] priorty;

  function void post_randomize();
    randsequence ( main )
      main           : header payload trailer ;
      header         : routing_table | statistics | payload_ | secure_payload ;
      routing_table  : { header[63:60] = ROUTING_TABLE; } control | reset ;
      statistics     : { header[63:60] = STATISTICS; } control | data | reset ;
      payload_       : { header[63:60] = PAYLOAD;} data;
      secure_payload : { header[63:60] = SECURE_PAYLOAD; } control | data ;
      control        : { header[59:56] = CONTROL; } ;
      data           : { header[59:56] = DATA; } ;
      reset          : { header[59:56] = RESET; } ;
      payload        : { payload = payload_data; } ;
      trailer        : zeros | ones | sync | parity | ecc | crc ;
      zeros          : { header [7:0] = ZEROS; trailer = 64'h00000000_00000000; } ;
      ones           : { header [7:0] = ONES; trailer = 64'hffffffff_ffffffff; } ;
      sync           : { header [7:0] = SYNC; trailer = 64'ha5a5a5a5_c3c3c3c3; } ;
      parity         : { header [7:0] = PARITY; calculate_parity(); } ;
      ecc            : { header [7:0] = ECC; calculate_ecc(); } ;
      crc            : { header [7:0] = CRC; calculate_crc(); } ;
    endsequence
    header [55:52] = payload_size;
    header [51:48] = payload_index;
    header [47:32] = source_address;
    header [31:16] = destination_address;
    header [15:12] = qos;
    header [11: 8] = priorty;
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

  function new(string name=""); 
    super.new(name);
  endfunction

endclass

