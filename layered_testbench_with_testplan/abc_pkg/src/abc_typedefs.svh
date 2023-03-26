  //   header [63:60] header type
  //   Routing table:  4'h1
  //   Statistics:     4'h2
  //   Payload:        4'h4 
  //   Secure payload: 4'h8
  typedef enum bit [3:0] { ROUTING_TABLE=4'h1, STATISTICS=4'h2, PAYLOAD=4'h4, SECURE_PAYLOAD=4'h8 } header_type_t;
  // header [59:56] header sub-type
  //   Control: 4'h1
  //   Data:    4'h2
  //   Reset:   4'h4
  typedef enum bit [3:0] { CONTROL=4'h1, DATA=4'h2, RESET=4'h4 } header_sub_type_t;
  // header [55:52] payload size
  // header [51:48] payload index
  // header [47:40] source address high
  // header [39:32] source address low
  // header [31:24] destination address high
  // header [23:16] destination address low
  // header [15:12] QOS
  // header [11: 8] priority
  // header [ 7: 0] trailer type
  //   Zeros:   8'h1
  //   Ones:    8'h2
  //   Sync:    8'h4
  //   Parity:  8'h8
  //   ECC:     8'h16
  //   CRC:     8'h32
  typedef enum bit [7:0] { ZEROS=8'h01, ONES=8'h02, SYNC=8'h04, PARITY=8'h08, ECC=8'h16, CRC=8'h32 } trailer_type_t;

