`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/08/02 15:24:40
// Design Name: 
// Module Name: data_ram_delay
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


module data_ram_delay(
	wb_clk_i, wb_rst_i, wb_cyc_i, wb_adr_i, wb_dat_i, wb_sel_i, wb_we_i, wb_stb_i,
    wb_dat_o, wb_ack_o,
    
    wea, ram_addr, ram_data_i, ram_data_o
    );
    
    //
    // WISHBONE Interface
    //
    input                 wb_clk_i;    // Clock
    input                 wb_rst_i;    // Reset
    input                wb_cyc_i;    // cycle valid input
    input   [31:0]        wb_adr_i;    // address bus inputs
    input   [31:0]        wb_dat_i;    // input data bus
    input    [3:0]         wb_sel_i;    // byte select inputs
    input                 wb_we_i;    // indicates write transfer
    input                 wb_stb_i;    // strobe input
    output  [31:0]        wb_dat_o;    // output data bus
    output                 wb_ack_o;    // normal termination
    
    output 	[3:0]		wea;
    output  [17:0]         ram_addr;
    input   [31:0]         ram_data_i;
    output  [31:0]         ram_data_o;
    
    wire mask;
    random_mask delay_mask(
        .clk   (wb_clk_i),
        .resetn(wb_rst_i),
        .mask  (mask    )
    );
    
    wire wb_cyc_i_masked;
    wire wb_stb_i_masked;
    wire wb_ack_o_unmasked;
    
    assign wb_cyc_i_masked = wb_cyc_i & mask;
    assign wb_stb_i_masked = wb_stb_i & mask;
    assign wb_ack_o = wb_ack_o_unmasked & mask;
    
    BRAM bram0(
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i), 
        .wb_cyc_i(wb_cyc_i_masked), 
        .wb_adr_i(wb_adr_i), 
        .wb_dat_i(wb_dat_i), 
        .wb_sel_i(wb_sel_i), 
        .wb_we_i(wb_we_i), 
        .wb_stb_i(wb_stb_i_masked),
        .wb_dat_o(wb_dat_o), 
        .wb_ack_o(wb_ack_o_unmasked),
        
        .wea(wea), 
        .ram_addr(ram_addr), 
        .ram_data_i(ram_data_i), 
        .ram_data_o(ram_data_o)
    );
    
endmodule
