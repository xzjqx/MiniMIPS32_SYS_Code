`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:48:42
// Design Name: 
// Module Name: MEM
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

module MEM(
	input wire rst,
	input wire [4:0] wd_i,
	input wire wreg_i,
	input wire [31:0] wdata_i,
	
	input wire whilo_i,
	input wire [31:0] hi_i,
	input wire [31:0] lo_i,
	
	input wire [7:0] aluop_i,
	input wire [31:0] mem_addr_i,
	input wire [31:0] reg2_i,
	
	input wire [31:0] mem_data_i,
	input wire cp0_reg_we_i,
	input wire [4:0] cp0_reg_write_addr_i,
	input wire [31:0] cp0_reg_data_i,

	output reg cp0_reg_we_o,
	output reg [4:0] cp0_reg_write_addr_o,
	output reg [31:0] cp0_reg_data_o,
	
	output reg [4:0] wd_o,
	output reg wreg_o,
	output reg [31:0] wdata_o,
	
	output reg whilo_o,
	output reg [31:0] hi_o,
	output reg [31:0] lo_o,
	
	output reg [31:0] mem_data_o,
	output reg mem_ce_o,
	output reg [3:0] mem_sel_o,
	output reg [31:0] mem_addr_o,
	output reg mem_we_o,
	
	input wire [`EXC_CODE_WIDTH-1:0] exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	
	output reg [`EXC_CODE_WIDTH-1:0] exc_code_o,
	output reg [31:0] exc_epc_o,
	output reg [31:0] exc_badvaddr_o,
	
	input in_delay_i,
	output in_delay_o,
	input wire [31:0] pc_i
    );
    
    assign in_delay_o = in_delay_i;
    
    wire [31:0] mem_unaligned_addr = mem_addr_i;
    wire [31:0] mem_vrt_addr = {mem_unaligned_addr[31:2], 2'b00};
    wire wordAlignedFlag = mem_unaligned_addr[1:0] == 2'b00;
    wire halfAlignedFlag = mem_unaligned_addr[0] == 1'b0;
	
	always @(*) begin
		if (rst == `RstEnable) begin
			wd_o = 5'b0;
			wreg_o = 1'b0;
			wdata_o = 32'b0;
			whilo_o = 1'b0;
			hi_o = 32'b0;
			lo_o = 32'b0;
			mem_data_o = 32'b0;
			mem_ce_o = 1'b0;
			mem_sel_o = 4'b0;
			mem_addr_o = 32'b0;
			mem_we_o = 1'b0;
			cp0_reg_we_o <= 1'b0;
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_data_o <= 32'b0;
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
		end
		else if (exc_code_i != `EC_None) begin
			wd_o = 5'b0;
			wreg_o = 1'b0;
			wdata_o = 32'b0;
			whilo_o = 1'b0;
			hi_o = 32'b0;
			lo_o = 32'b0;
			mem_data_o = 32'b0;
			mem_ce_o = 1'b0;
			mem_sel_o = 4'b0;
			mem_addr_o = 32'b0;
			mem_we_o = 1'b0;
			cp0_reg_we_o <= 1'b0;
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_data_o <= 32'b0;
			exc_code_o <= exc_code_i;
			exc_epc_o <= exc_epc_i;
			exc_badvaddr_o <= exc_badvaddr_i;
		end
		else begin
			wd_o = wd_i;
			wreg_o = wreg_i;
			wdata_o = wdata_i;
			whilo_o = whilo_i;
			hi_o = hi_i;
			lo_o = lo_i;
			mem_data_o = 32'b0;
			mem_ce_o = 1'b0;
			mem_sel_o = 4'b1;
			mem_addr_o = 32'b0;
			mem_we_o = 1'b0;
			cp0_reg_we_o = cp0_reg_we_i;
			cp0_reg_write_addr_o = cp0_reg_write_addr_i;
			cp0_reg_data_o = cp0_reg_data_i;
			exc_code_o <= exc_code_i;
			exc_epc_o <= exc_epc_i;
			exc_badvaddr_o <= exc_badvaddr_i;
			case(aluop_i)
				`LB: begin
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `LBU: begin
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
                            mem_sel_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
                            mem_sel_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
                            mem_sel_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
                            mem_sel_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `LH: begin
                	if(!halfAlignedFlag) begin 
                		exc_code_o <= `EC_AdEL;
						if(in_delay_i) exc_epc_o <= pc_i -4;
					    else exc_epc_o <= pc_i;
						exc_badvaddr_o <= mem_addr_i;
                    end
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `LHU: begin
                	if(!halfAlignedFlag) begin 
                		exc_code_o <= `EC_AdEL;
						if(in_delay_i) exc_epc_o <= pc_i -4;
					    else exc_epc_o <= pc_i;
						exc_badvaddr_o <= mem_addr_i;
                    end
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
                            mem_sel_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
                            mem_sel_o <= 4'b1100;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `LW: begin
                	if(!wordAlignedFlag) begin 
                		exc_code_o <= `EC_AdEL;
						if(in_delay_i) exc_epc_o <= pc_i -4;
					    else exc_epc_o <= pc_i;
						exc_badvaddr_o <= mem_addr_i;
                    end
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteDisable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
							wdata_o <= mem_data_i;
                            mem_sel_o <= 4'b1111;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `SB: begin
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteEnable;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b0001;
                            mem_data_o <= {24'b0, reg2_i[7:0]};
                        end
                        2'b01: begin
                            mem_sel_o <= 4'b0010;
                        	mem_data_o <= {16'b0, reg2_i[7:0], 8'b0};
                        end
                        2'b10: begin
                            mem_sel_o <= 4'b0100;
                        	mem_data_o <= {8'b0, reg2_i[7:0], 16'b0};
                        end
                        2'b11: begin
                            mem_sel_o <= 4'b1000;
                            mem_data_o <= {reg2_i[7:0], 24'b0};
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
                `SH: begin
                	if(!halfAlignedFlag) begin 
                	exc_code_o <= `EC_AdEL;
						if(in_delay_i) exc_epc_o <= pc_i -4;
					    else exc_epc_o <= pc_i;
						exc_badvaddr_o <= mem_addr_i;
                    end
                	mem_addr_o <= {3'b0,mem_addr_i[28:0]};
					mem_we_o <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
					    2'b00: begin
					        mem_sel_o <= 4'b0011;
					        mem_data_o <= {16'b0, reg2_i[15:0]};
					    end
					    2'b10: begin
					        mem_sel_o <= 4'b1100;
					        mem_data_o <= {reg2_i[15:0], 16'b0};
					    end
					    default: begin
					        mem_sel_o <= 4'b0000;
					    end
					endcase
                end
                `SW: begin
                	if(!wordAlignedFlag) begin 
                		exc_code_o <= `EC_AdES;
						if(in_delay_i) exc_epc_o <= pc_i -4;
					    else exc_epc_o <= pc_i;
						exc_badvaddr_o <= mem_addr_i;
                    end
                    mem_addr_o <= {3'b0,mem_addr_i[28:0]};
                    mem_we_o <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce_o <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_sel_o <= 4'b1111;
                        end
                        default: begin
                            mem_sel_o <= 4'b0000;
                        end
                    endcase
                end
				default: begin
					mem_addr_o <= `ZeroWord;
					mem_we_o <= `WriteDisable;
					mem_data_o <= `ZeroWord;
					mem_sel_o <= 4'b1111;
					mem_ce_o <= `ChipDisable;
				end		 
			endcase
		end
	end
	
endmodule