module first_dut( abc_if abc_p0, abc_if abc_p1);

  bit sop_d1, sop_d2;
  bit eop_d1, eop_d2;
  reg [63:0] data_d1, data_d2;

  always @(posedge abc_p0.clk) begin
    sop_d1 <= abc_p0.sop;
    sop_d2 <= sop_d1;
    data_d1 <= abc_p0.data;
    data_d2 <= data_d1;
    eop_d1 <= abc_p0.eop;
    eop_d2 <= eop_d1;
  end

  assign abc_p1.sop  =  sop_d2;
  assign abc_p1.data =  data_d2;
  assign abc_p1.eop  =  eop_d2;

endmodule
