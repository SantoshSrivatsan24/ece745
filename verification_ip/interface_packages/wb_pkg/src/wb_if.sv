import wb_pkg::*;

interface wb_if       #(
      int ADDR_WIDTH = 32,                                
      int DATA_WIDTH = 16                                
      )
(
  // System sigals
  input wire clk_i,
  input wire rst_i,
  input wire irq_i,
  // Master signals
  output reg cyc_o,
  output reg stb_o,
  input wire ack_i,
  output reg [ADDR_WIDTH-1:0] adr_o,
  output reg we_o,
  // Slave signals
  input wire cyc_i,
  input wire stb_i,
  output reg ack_o,
  input wire [ADDR_WIDTH-1:0] adr_i,
  input wire we_i,
  // Shred signals
  output reg [DATA_WIDTH-1:0] dat_o,
  input wire [DATA_WIDTH-1:0] dat_i
  );

  initial reset_bus();

   csr_u csr;
   cmdr_u cmdr;

   logic is_write;
   logic is_read;

   assign csr_write = cyc_o && stb_o && we_o && (adr_o == CSR_ADDR);
   assign cmdr_read = cyc_o && stb_o && !we_o && (adr_o == CMDR_ADDR) && ack_i; // read upon command completion

   always @(*) begin
      if (csr_write) begin
         csr.value = dat_o;
      end else begin
         csr.value = csr.value;
      end

      if (cmdr_read) begin
         cmdr.value = dat_i;
      end else begin
         cmdr.value = cmdr.value;
      end
   end

   // Testplan 1.3: Check that every address is to a valid register
   property addr_valid;
      // Active high reset
      disable iff (rst_i)
      @(posedge clk_i) stb_o |-> (adr_o == CSR_ADDR || adr_o == DPR_ADDR || adr_o == CMDR_ADDR || adr_o == FSMR_ADDR);
   endproperty

   assert property (addr_valid) else $fatal ("Invalid address: %b", adr_o);

   // Testplan 2.1: Ensure that the IRQ signal stays low when interrupts are disabled
   property csr_irq_disabled_int_low;
      disable iff (rst_i)
      // irq_i must always be 0
      @(posedge clk_i) !csr.fields.ie |-> !irq_i[*0:$];
   endproperty 

   assert property (csr_irq_disabled_int_low) else $fatal ("IRQ signal high when interrupts are disabled: %b", csr.fields);

   // Testplan 2.4: Ensure that the reserved bit of the CMDR is always 0
   property cmdr_res_bit_low;
      disable iff (rst_i)
      @(posedge clk_i) !cmdr.fields.r;
   endproperty

   assert property (cmdr_res_bit_low) else $fatal ("CMDR reserved bit high: %p", cmdr.fields);

   // 2.9: Ensure the IRQ signal goes low upon reading the CMDR
   property cmdr_irq_low;
      disable iff (rst_i)
      @(posedge clk_i) stb_o |=> ##[0:$] irq_i until ack_i ##1 !irq_i;
   endproperty

   assert property (cmdr_irq_low) else $fatal ("IRQ signal doesn't go low after reading the CMDR: %p", cmdr.fields);

   // 2.10: One of the CMDR status bits is set upon command completion
   property cmdr_status_onehot;
      disable iff (rst_i)
      @(posedge clk_i) cmdr_read |-> $onehot ({cmdr.fields.don, cmdr.fields.nak, cmdr.fields.al, cmdr.fields.err});
   endproperty 

   assert property (cmdr_status_onehot) else $fatal ("CMDR multiple status bits high: %p", cmdr.fields);

// ****************************************************************************              
   task wait_for_reset();
       if (rst_i !== 0) @(negedge rst_i);
   endtask

// ****************************************************************************              
   task wait_for_num_clocks(int num_clocks);
       repeat (num_clocks) @(posedge clk_i);
   endtask

// ****************************************************************************              
   task wait_for_interrupt();
       @(posedge irq_i);
   endtask

// ****************************************************************************              
   task reset_bus();
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        adr_o <= 'b0;
        dat_o <= 'b0;
   endtask

// ****************************************************************************              
  task master_write(
                   input bit [ADDR_WIDTH-1:0]  addr,
                   input bit [DATA_WIDTH-1:0]  data
                   );  

        @(posedge clk_i);
        adr_o <= addr;
        dat_o <= data;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        while (!ack_i) @(posedge clk_i);
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        adr_o <= 'bx;
        dat_o <= 'bx;
        we_o <= 1'b0;
        @(posedge clk_i);

endtask        

// ****************************************************************************              
task master_read(
                 input bit [ADDR_WIDTH-1:0]  addr,
                 output bit [DATA_WIDTH-1:0] data
                 );                                                  

        @(posedge clk_i);
        adr_o <= addr;
        dat_o <= 'bx;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b0;
        @(posedge clk_i);
        while (!ack_i) @(posedge clk_i);
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        adr_o <= 'bx;
        dat_o <= 'bx;
        we_o <= 1'b0;
        data = dat_i;

endtask        

// ****************************************************************************              
     task master_monitor(
                   output bit [ADDR_WIDTH-1:0] addr,
                   output bit [DATA_WIDTH-1:0] data,
                   output bit we                    
                  );
                         
          while (!cyc_o) @(posedge clk_i);                                                  
          while (!ack_i) @(posedge clk_i);
          addr = adr_o;
          we = we_o;
          if (we_o) begin
            data = dat_o;
          end else begin
            data = dat_i;
          end
          while (cyc_o) @(posedge clk_i);                                                  
     endtask 

endinterface
