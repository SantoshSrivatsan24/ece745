class abc_coverage extends ncsu_component#(.T(abc_transaction_base));

    abc_configuration configuration;
  	header_type_t     header_type;
  	header_sub_type_t header_sub_type;
  	trailer_type_t    trailer_type;

  covergroup abc_transaction_cg;
  	option.per_instance = 1;
    option.name = get_full_name();

  	header_type:     coverpoint header_type
  	{
  	bins ROUTING_TABLE = {ROUTING_TABLE};
  	bins STATISTICS = {STATISTICS};
  	bins PAYLOAD = {PAYLOAD};
  	bins SECURE_PAYLOAD = {SECURE_PAYLOAD};
  	}

  	header_sub_type: coverpoint header_sub_type
  	{
  	bins CONTROL = {CONTROL};
  	bins DATA = {DATA};
  	bins RESET = {RESET};
  	}

  	trailer_type:    coverpoint trailer_type
  	{
  	bins ZEROS = {ZEROS};
  	bins ONES = {ONES};
  	bins SYNC = {SYNC};
  	bins PARITY = {PARITY};
  	bins ECC = {ECC};
  	bins CRC = {CRC};  	
  	} 

  	header_x_header_sub: cross header_type, header_sub_type
  	  {
  	   illegal_bins routing_table_sub_types_illegal = 
  	           binsof(header_type.ROUTING_TABLE) && 
  	           binsof(header_sub_type.DATA);
  	   illegal_bins payload_sub_types_illegal = 
  	           binsof(header_type.PAYLOAD) && 
  	           ( binsof(header_sub_type.CONTROL) || 
  	           	 binsof(header_sub_type.RESET));
  	   illegal_bins secure_payload_sub_types_illegal = 
  	           binsof(header_type.SECURE_PAYLOAD) && 
  	           binsof(header_sub_type.RESET);
  	  }

  	  header_x_trailer: cross header_type, trailer_type;
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    abc_transaction_cg = new;
  endfunction

  function void set_configuration(abc_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void nb_put(T trans);
    $display("abc_coverage::nb_put() %s called",get_full_name());
    header_type     = header_type_t'(trans.header[63:60]);
  	header_sub_type = header_sub_type_t'(trans.header[59:56]);
  	trailer_type    = trailer_type_t'(trans.header[7:0]); 
    abc_transaction_cg.sample();
  endfunction

endclass
