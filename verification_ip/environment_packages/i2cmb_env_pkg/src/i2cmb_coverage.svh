class i2cmb_coverage extends ncsu_component #(.T(wb_transaction));


    covergroup i2cmb_fsm_cg with function sample (fsmr_u fsmr);

    // Testplan 3.1: Ensure that all byte-level FSM states are covered
    byte_fsm_state: coverpoint fsmr.fields.byte_fsm_state
    {
        bins valid_states[] = {S_IDLE, S_BUS_TAKEN, S_START_PENDING, S_START, S_STOP, S_WRITE_BYTE, S_READ_BYTE, S_WAIT};
    }

    // Testplan 3.2: Ensure that all byte-level FSM state transitions are exercised
    byte_fsm_transition: coverpoint fsmr.fields.byte_fsm_state
    {
        bins valid_transitions[] =
            (S_IDLE => S_START_PENDING, S_WAIT, S_IDLE), 
            (S_START_PENDING => S_START),
            (S_START => S_BUS_TAKEN, S_IDLE),
            (S_BUS_TAKEN => S_START, S_WRITE_BYTE, S_READ_BYTE, S_STOP, S_BUS_TAKEN),
            (S_WRITE_BYTE => S_IDLE, S_BUS_TAKEN, S_WRITE_BYTE),
            (S_READ_BYTE => S_IDLE, S_BUS_TAKEN, S_READ_BYTE),
            (S_STOP => S_IDLE),
            (S_WAIT => S_IDLE);
        // illegal_bins invalid_transitions[] = default;
    }

    // Testplan 3.3: Ensure that all bit-level FSM states are covered
    bit_fsm_state: coverpoint fsmr.fields.bit_fsm_state
    {   
    
    }
    endgroup

    function new (string name = "", ncsu_component_base parent = null);
        super.new (name, parent);
        i2cmb_fsm_cg = new;
    endfunction

    virtual function void nb_put (T trans);
        fsmr_u fsmr;
        if (trans.addr == FSMR_ADDR) begin
            fsmr.value = trans.data;
            i2cmb_fsm_cg.sample(fsmr);
        end
    endfunction


endclass