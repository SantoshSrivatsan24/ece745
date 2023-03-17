`define CSR_ADDR	2'h0
`define DPR_ADDR 	2'h1
`define CMDR_ADDR 	2'h2

`define CMD_START     3'b100
`define CMD_STOP      3'b101
`define CMD_READ_ACK  3'b010
`define CMD_READ_NACK 3'b011
`define CMD_WRITE     3'b001
`define CMD_SET_BUS   3'b110
`define CMD_WAIT      3'b000

`define SLAVE_ADDR	(8'h22 << 1)
