`define BANNER(t, x) \
	$display ("==========================================================================="); \
	$display ("%s (%t)", x, t); \
	$display ("---------------------------------------------------------------------------");

`define FANCY_BANNER(x) \
	$display ("\n***************************************************************************"); \
	$display ("%s", x); \
	$display ("***************************************************************************\n");

`define CSR_DEFAULT_VALUE 	8'h00
`define CMDR_DEFAULT_VALUE 	8'h80
`define DPR_DEFAULT_VALUE 	8'h00
`define FSMR_DEFAULT_VALUE	8'h00