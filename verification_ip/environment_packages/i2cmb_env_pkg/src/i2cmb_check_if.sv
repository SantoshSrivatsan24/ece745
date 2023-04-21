// The purpose of this interface is to validate the 
// value of the CMDR register *after* command execution

import i2cmb_env_pkg::*;
import wb_pkg::*;

interface i2cmb_check_if #(
      int ADDR_WIDTH = 32,                                
      int DATA_WIDTH = 16                                
)
(
   // System sigals
   input wire clk_i,
   input wire rst_i,
   input wire irq_i,
   // Master signals
   input wire cyc_o,
   input wire stb_o,
   input wire ack_i,
   input wire [ADDR_WIDTH-1:0] adr_o,
   input wire we_o,
   // Shred signals
   input wire [DATA_WIDTH-1:0] dat_o,
   input wire [DATA_WIDTH-1:0] dat_i
);

   cmdr_u cmdr;
   logic cmdr_read;

   assign cmdr_read = cyc_o && stb_o && !we_o && (adr_o == CMDR_ADDR) && ack_i; // read upon command completion

   assign cmdr.value = cmdr_read ? dat_i : cmdr.value;

   // Testplan 1.3: Check that every address is to a valid register
   property addr_valid;
      disable iff (rst_i) // Active high reset
      @(posedge clk_i) stb_o |-> (adr_o == CSR_ADDR || adr_o == DPR_ADDR || adr_o == CMDR_ADDR || adr_o == FSMR_ADDR);
   endproperty

   // Testplan 2.4: Ensure the IRQ signal goes low upon reading the CMDR
   property cmdr_read_irq_low;
      disable iff (rst_i)
      @(posedge clk_i) cmdr_read |=> !irq_i;
   endproperty

   // Testplan 2.5: Ensure that the reserved bit of the CMDR is always 0
   property cmdr_res_bit_low;
      disable iff (rst_i)
      @(posedge clk_i) cmdr_read |-> !cmdr.fields.r;
   endproperty

   assert property (addr_valid) else $fatal ("Invalid address: %b", adr_o);
   assert property (cmdr_read_irq_low) else $fatal ("IRQ signal doesn't go low after reading the CMDR: %p", cmdr.fields);
   assert property (cmdr_res_bit_low) else $fatal ("CMDR reserved bit high: %p", cmdr.fields);

endinterface
