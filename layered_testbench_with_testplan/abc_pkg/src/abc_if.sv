interface abc_if(input wire clk, rst_n);

  wire sop, eop;
  wire [63:0] data;

  bit enable_driver;
  bit sop_o, eop_o;
  reg [63:0] data_o;

  property abc_eop_follows_sop;
    @(posedge clk) disable iff (!rst_n) sop  |=> (!sop & !eop)[*1:64] ##1 (eop) ##1 (!sop & !eop);
  endproperty

  assert property(abc_eop_follows_sop) else $error("Invalid SOP/EOP operation for ABC Protocol");


  assign sop  = (enable_driver)? sop_o:'bz;
  assign data = (enable_driver)? data_o:'bz;
  assign eop  = (enable_driver)? eop_o:'bz;

  task drive(input bit [63:0] header, payload[8], trailer, input bit [5:0]delay);
    repeat(delay) @(posedge clk);
    @(posedge clk);
    sop_o <= 1'b1;
    data_o <= header;
    foreach (payload[i]) begin
      @(posedge clk);
      sop_o <= 1'b0;
      data_o <= payload[i];
    end
      @(posedge clk);
      eop_o <= 1'b1;
      data_o <= trailer;
      @(posedge clk);
      eop_o <= 1'b0;
      data_o <= 'bx;
  endtask

  task wait_for_reset();
    wait ( rst_n == 1 );
  endtask

  task monitor(output bit [63:0] header, output bit [63:0] payload[8], output bit [63:0] trailer, output bit [5:0] delay);
    delay = 0;
    while (sop != 1'b1) @(posedge clk) delay++;
    header = data;
    foreach (payload[i]) begin
      @(posedge clk);
      payload[i] = data;
    end
    @(posedge clk);
    trailer = data;
    delay = delay - 2;
  endtask

endinterface
