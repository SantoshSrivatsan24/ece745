module top();

  import ncsu_pkg::*;
  import abc_pkg::*;
  import first_project_pkg::*;

   bit clk;
   initial begin : clk_gen 
     forever #5ns clk <= ~clk;
   end

   bit rst_n;
   initial begin : rst_gen
      #50ns rst_n <= 1'b1;
   end

   test_base tst;

   abc_if p0_bus(.clk(clk),.rst_n(rst_n));
   abc_if p1_bus(.clk(clk),.rst_n(rst_n));

   first_dut DUT(.abc_p0(p0_bus), .abc_p1(p1_bus));

  initial begin : test_flow
    ncsu_config_db#(virtual abc_if)::set("tst.env.p0_agent", p0_bus);
    ncsu_config_db#(virtual abc_if)::set("tst.env.p1_agent", p1_bus);
    p0_bus.enable_driver = 1'b1;
    tst = new("tst",null);
    wait ( rst_n == 1);
    tst.run();
    #100ns $finish();
  end

endmodule
