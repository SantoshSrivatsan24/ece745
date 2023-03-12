`define CSR_ADDR	2'h0
`define DPR_ADDR 	2'h1
`define CMDR_ADDR 	2'h2

`define CMD_START     8'bxxxx_x100
`define CMD_STOP      8'bxxxx_x101
`define CMD_READ_ACK  8'bxxxx_x010
`define CMD_READ_NACK 8'bxxxx_x011
`define CMD_WRITE     8'bxxxx_x001
`define CMD_SET_BUS   8'bxxxx_x110
`define CMD_WAIT      8'bxxxx_x000

class wb_driver extends ncsu_component #(.T(wb_transaction));

    virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)) wb_bus;
    ncsu_component #(T) wb_agent;
    // T wb_trans;

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
    endfunction

    virtual task bl_put (input T trans);
        bit [7:0] cmdr_rdata;
        if (trans.cmd) begin
            wb_bus.master_write(.addr(trans.addr), .data(trans.data));
            wb_bus.wait_for_interrupt ();
            wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
        end else begin
            wb_bus.master_write(.addr(trans.addr), .data(trans.data));
        end
    endtask

	//////////////////////////////////////////////////////////////////////
endclass