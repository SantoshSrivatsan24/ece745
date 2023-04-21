// Bind interface to internal command status signals
// The purpose of this interface is to validate the 
// values of internal registers *during* command execution

import i2cmb_env_pkg::*;

interface i2cmb_probe_if (
    input wire          clk,
    input wire          s_rst,

    input wire          irq_y,
    input wire          mcmd_wr_y,
    input wire [2:0]    mcmd_id_y,

    // Probe the internal state of the CSR register
    input wire          e_reg,
    input wire          ie_reg,
    input wire          busy,
    input wire          captured,

    // Probe the internal state of the DPR register
    input wire [7:0]    tx_data_reg,
    input wire [7:0]    rx_data_reg,

    // Probe the internal state of the CMDR register
    input wire          don_reg,
    input wire          nak_reg,
    input wire          al_reg,
    input wire          err_reg,
    input wire [2:0]    cmd_code_reg,
    input wire          command_completed,

    // Probe the internal state of the FSMR register
    input wire [3:0]    byte_state,
    input wire [3:0]    bit_state
);

    // Determine whether a command is executing or not from the diagram of the byte-level FSM
    // From the diagram, the states colored blue are when a command is NOT executing
    // busy != command executing
    wire command_executing = (byte_state == S_START) || (byte_state == S_STOP) || (byte_state == S_WRITE_BYTE) || (byte_state == S_READ_BYTE);

    // Testplan 2.2: Ensure that the IRQ signal stays low when interrupts are disabled
    property int_disabled_irq_low;
        disable iff (s_rst)
        @(posedge clk) !ie_reg |-> !irq_y[*0:$];
    endproperty

    // Testplan 2.3: Ensure that the IRQ signal goes high when a command is completed and the CSR IE bit is 1
    property cmd_complete_irq_high;
        disable iff (s_rst)
        @(posedge clk) (command_completed && ie_reg) |-> ##[0:$] irq_y;
    endproperty

    // Testplan 2.6: Ensure that the CMDR DON bit is 0 during command execution
    property cmd_exec_don_low;
        disable iff (s_rst)
        @(posedge clk) command_executing |-> !don_reg;
    endproperty

    // Testplan 2.7: Ensure that the CMDR NAK bit is 0 during command execution
    property cmd_exec_nak_low;
        disable iff (s_rst)
        @(posedge clk) command_executing |-> !nak_reg;
    endproperty

    // Testplan 2.8: Ensure that the CMDR AL bit is 0 during command execution
    property cmd_exec_al_low;
        disable iff (s_rst)
        @(posedge clk) command_executing |-> !al_reg;
    endproperty

    // Testplan 2.9: Ensure that the CMDR ERR bit is 0 during command execution
    property cmd_exec_err_low;
        disable iff (s_rst)
        @(posedge clk) command_executing |-> !err_reg;
    endproperty
    
    // Testplan 2.10: Only one of the CMDR status bits is set upon command completion
    property cmd_status_onehot;
        disable iff (s_rst)
        @(posedge clk) command_completed |-> $onehot ({don_reg, nak_reg, al_reg, err_reg});
    endproperty 

    // Testplan 3.3: Ensure that the byte-level FSM never reaches an invalid state
    property byte_fsm_valid;
        disable iff (s_rst)
        @(posedge clk) (byte_state < 4'd8);
    endproperty

    // Testplan 3.4: Ensure that the bit-level FSM never reaches an invalid state
    property bit_fsm_valid;
        disable iff (s_rst)
        @(posedge clk) (bit_state < 4'd15);
    endproperty

    assert property (int_disabled_irq_low) else $fatal ("IRQ signal high when interrupts are disabled");
    assert property (cmd_complete_irq_high) else $fatal ("IRQ signal doesn't go high when command completes");
    assert property (cmd_exec_don_low) else $fatal ("CMDR DON bit high during command execution");
    assert property (cmd_exec_nak_low) else $fatal ("CMDR NAK bit high during command execution");
    assert property (cmd_exec_al_low) else $fatal ("CMDR AL bit high during command execution");
    assert property (cmd_exec_err_low) else $fatal ("CMDR ERR bit high during command execution");
    assert property (cmd_status_onehot) else $fatal ("Multiple status bits high");
    assert property (byte_fsm_valid) else $fatal ("Invalid byte-level FSM state");
    assert property (bit_fsm_valid) else $fatal ("Invalid bit-level FSM state");

endinterface

