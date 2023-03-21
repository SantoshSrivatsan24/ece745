class wb_randseq_transaction extends wb_transaction_base #(.ADDR_WIDTH(2), .DATA_WIDTH(8));

    `ncsu_register_object(wb_randseq_transaction)

    rand bit [6:0] dpr_addr;
    rand bit [7:0] dpr_data;

    function new (string name = "");
        super.new(name);
    endfunction

    function void post_randomize();
        randsequence (main)
            main        : one two;
            one         : {addr = CMDR_ADDR; data = CMD_START; };
            two         : temp1 temp3;
            three       : temp2 temp3;
            four        : {addr = CMDR_ADDR; data = CMD_STOP; };
            temp1       : {addr = DPR_ADDR; data = {dpr_addr, WRITE}; };
            temp2       : {addr = DPR_ADDR; data = dpr_data; };
            temp3       : {addr = CMDR_ADDR; data = CMD_WRITE; };
        endsequence
    endfunction

    // function void post_randomize();
    //     randsequence (main)
    //         main        : one two three;
    //         one         : four five;
    //         two         : {$display("two");};
    //         three       : six | seven;
    //         four        : {$display("four");};
    //         five        : {$display("five");};
    //         six         : {$display("six");};
    //         seven       : {$display("seven");};
    //     endsequence
    // endfunction

endclass