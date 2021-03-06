`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/25 15:39:13
// Design Name: 
// Module Name: BRAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "defines.v"

module BRAM(
	       wb_clk_i, wb_rst_i, 
           wb_cyc_i, wb_adr_i, wb_dat_i, wb_sel_i, wb_we_i, wb_stb_i,
	       wb_dat_o, wb_ack_o,
	
	       wea, ram_ce, ram_addr, ram_data_i, ram_data_o
    );
    
    // WISHBONE Interface
    input             	     wb_clk_i;	// Clock
    input             	     wb_rst_i;	// Reset
    input            	     wb_cyc_i;	// cycle valid input
    input   [`InstAddrBus]	 wb_adr_i;	// address bus inputs
    input   [`RegBus     ]	 wb_dat_i;	// input data bus
    input	[`ByteSelect ]   wb_sel_i;	// byte select inputs
    input             	     wb_we_i ;	// indicates write transfer
    input             	     wb_stb_i;	// strobe input
    output  [`RegBus     ]	 wb_dat_o;	// output data bus
    output 				     wb_ack_o;	// normal termination
    
    output 	[`ByteSelect ]	 wea;
    output                   ram_ce;
	output  [`RamAddr    ] 	 ram_addr;
    input   [`RegBus     ]   ram_data_i;
    output  [`RegBus     ] 	 ram_data_o;
    
	wire    [`InstAddrBus]   addr    = wb_adr_i;
	wire    [`RegBus     ]   data_in = wb_dat_i;
	
    assign  wea        = (wb_stb_i && wb_we_i) ? wb_sel_i : 4'b0;
    assign  ram_ce     = |wb_sel_i;
    assign	ram_data_o = wb_dat_i;
    assign  ram_addr   = wb_adr_i[19:2];
    assign  wb_dat_o   = ram_data_i;

    assign  wb_ack_o   = wb_cyc_i & wb_stb_i;

endmodule