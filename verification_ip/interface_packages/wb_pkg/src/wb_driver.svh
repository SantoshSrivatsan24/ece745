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
    T wb_trans;

    function new (string name = "", ncsu_component #(T) parent = null);
        super.new (name, parent);
        if ( !(ncsu_config_db#(virtual wb_if #(.ADDR_WIDTH(2), .DATA_WIDTH(8)))::get(get_full_name(), this.wb_bus))) begin;
            $display("abc_agent::ncsu_config_db::get() call for BFM handle failed for name: %s ", get_full_name());
            $finish;
        end 
    endfunction

    // Enable the IICMB core
    virtual task wb_enable();
        wb_bus.master_write (.addr(`CSR_ADDR), .data('b11xx_xxxx)); 
    endtask

    // Wait for IRQ to go high. Clear IRQ by reading the CMDR register
    virtual task wb_wait();
        logic [7:0] cmdr_rdata;
        wb_bus.wait_for_interrupt ();
        wb_bus.master_read (.addr(`CMDR_ADDR), .data(cmdr_rdata));
    endtask

    virtual task wb_set_bus(input byte bus_id);
        wb_bus.master_write (.addr(`DPR_ADDR), .data(bus_id));
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_SET_BUS));
        wb_wait();
    endtask

    // Issue a START command
    virtual task wb_start();
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_START));
        wb_wait();
    endtask

    // Issue a STOP command
    virtual task wb_stop();
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_STOP));
        wb_wait();
    endtask

    // Issue a WRITE command
    virtual task wb_write(input byte wdata);
        wb_bus.master_write (.addr(	`DPR_ADDR), .data (wdata));
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_WRITE));
        wb_wait();
    endtask;

    // Issue a READ with ACK command (slave writes to the DPR)
    virtual task wb_read_ack(output byte rdata);
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_READ_ACK));
        wb_wait();
        wb_bus.master_read (.addr(`DPR_ADDR), .data(rdata));
    endtask

    // Issue a READ with NACK command
    // Signal slave to stop transfer
    virtual task wb_read_nack(output byte rdata);
        wb_bus.master_write (.addr(`CMDR_ADDR), .data(`CMD_READ_NACK));
        wb_wait();
        wb_bus.master_read (.addr(`DPR_ADDR), .data(rdata));
    endtask

    // Override parent's bl_put
    virtual task bl_put (input T trans);
        bit [7:0] addr = {trans.wb_addr, trans.wb_op};
        ncsu_info("ncsu_component::bl_put()", $sformatf(" of %s called",get_full_name()), NCSU_NONE);
        wb_start();
        wb_write(.wdata(addr));
	    foreach(trans.wb_data[i]) begin
		    wb_write(.wdata(trans.wb_data[i]));
	    end
	    wb_stop();
    endtask

endclass