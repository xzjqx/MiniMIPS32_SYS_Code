`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:45:08
// Design Name: 
// Module Name: EX
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

module EX(
	input wire 			rst,
	input wire [2:0] 	alusel_i,
	input wire [7:0] 	aluop_i,
	input wire [31:0] 	reg1_i,
	input wire [31:0] 	reg2_i,
	input wire [4:0] 	wd_i,
	input wire 			wreg_i,
	
	input wire [31:0] 	hi_i,
	inout wire [31:0] 	lo_i,
	input wire 			mem_whilo_i,
	input wire [31:0] 	mem_hi_i,
	input wire [31:0] 	mem_lo_i,
	input wire 			wb_whilo_i,
	input wire [31:0] 	wb_hi_i,
	input wire [31:0] 	wb_lo_i,
	
	input wire 			in_delay_i,
	input wire [31:0] 	link_addr_i,
	
	input wire [31:0] 	inst_i,
	
	input wire		  	mem_cp0_we,
	input wire [4:0]	mem_cp0_waddr,
	input wire [31:0]	mem_cp0_wdata,	

	input wire[31:0]    cp0_reg_read_data_i,
	output reg[4:0]     cp0_reg_read_addr_o,

	output reg          cp0_reg_we_o,
	output reg[4:0]     cp0_reg_waddr_o,
	output reg[31:0] 	cp0_reg_wdata_o,

	output reg [4:0] 	wd_o,
	output reg 			wreg_o,
	output reg [31:0] 	wdata_o,
	
	output reg 			whilo_o,
	output reg [31:0] 	hi_o,
	output reg [31:0] 	lo_o,
	
	output wire [7:0] 	aluop_o,
	output reg [31:0] 	mem_addr_o,
	output wire [31:0] 	reg2_o,
	
	input wire [`EXC_CODE_WIDTH-1:0]exc_code_i,
	input wire [31:0] exc_epc_i,
	input wire [31:0] exc_badvaddr_i,
	
	output reg [`EXC_CODE_WIDTH-1:0]exc_code_o,
	output reg [31:0] exc_epc_o,
	output reg [31:0] exc_badvaddr_o,
	
	output reg cp0_reg_read_o
    );
	
	wire[31:0] signed_low16_inst;
	assign signed_low16_inst = { {16{inst_i[15]}}, inst_i[15:0] };

	reg[31:0] logicout;
	reg[31:0] shiftout;
	reg[31:0] moveout;
	reg[31:0] hi_t;
	reg[31:0] lo_t;
	reg[63:0] arithout;
	reg[31:0] cp0out;

	assign aluop_o = aluop_i;
	assign reg2_o = reg2_i;
  
	always @(*)begin
		if (rst==`RstEnable) begin
			exc_code_o<=`EC_None;
			exc_epc_o <= 0;
			exc_badvaddr_o <= 0;
		end else begin
			exc_code_o <= exc_code_i;
			exc_epc_o <= exc_epc_i;
			exc_badvaddr_o <= exc_badvaddr_i;
		end
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			cp0_reg_we_o <= 1'b0;
			cp0_reg_wdata_o <= 32'h00000000;
			cp0_reg_waddr_o <= 5'b00000;
			cp0_reg_read_addr_o <= 5'b00000;
			cp0_reg_read_o <= 1'b0;
			cp0out <= `ZeroWord;
		end else begin
			case (aluop_i)
				`MFC0: begin
					cp0_reg_read_o <= 1'b1;
					cp0_reg_read_addr_o <= inst_i[15:11];
					cp0_reg_we_o <= 1'b0;
					cp0_reg_wdata_o <= 32'h00000000;
					cp0_reg_waddr_o <= 5'b00000;
					// if (mem_cp0_we == `WriteEnable && mem_cp0_waddr == inst_i[15:11]) begin
					//     cp0out <= mem_cp0_wdata;
					// end
					// else begin
					cp0out <= cp0_reg_read_data_i;
					// end
				end
				`MTC0: begin
					cp0_reg_read_o <= 1'b0;
					cp0_reg_read_addr_o <= 5'b00000;
					cp0_reg_we_o <= 1'b1;
					cp0_reg_waddr_o <= inst_i[15:11];
					cp0_reg_wdata_o <= reg1_i;
					cp0out <= `ZeroWord;
				end
				default: begin
					cp0_reg_we_o <= 1'b0;
					cp0_reg_wdata_o <= 32'h00000000;
					cp0_reg_waddr_o <= 5'b00000;
					cp0_reg_read_addr_o <= 5'b00000;
					cp0_reg_read_o <= 1'b0;
					cp0out <= `ZeroWord;
				end
			endcase
		end
	end

	// 8/8 logic instructions=====================================================
	always @ (*) begin
		if (rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`AND: begin
					logicout <= reg1_i & reg2_i;
				end
				`ANDI: begin                   // immdiate should be load to reg2_i
					logicout <= reg1_i & reg2_i;
				end
				`LUI: begin                    // immdiate should be load to reg1_i
					logicout <= {reg1_i[15:0], 16'b0};
				end
				`NOR: begin
					logicout <= ~(reg1_i | reg2_i);
				end
				`OR: begin
					logicout <= reg1_i | reg2_i;
				end
				`ORI: begin                    // immdiate should be load to reg2_i
					logicout <= reg1_i | reg2_i;
				end
				`XOR: begin
					logicout <= reg1_i ^ reg2_i;
				end
				`XORI: begin                   // immdiate should be load to reg2_i
					logicout <= reg1_i ^ reg2_i;
				end
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end
	end


	// 6/6 shift word instructions================================================
	always @ (*) begin
		if (rst == `RstEnable) begin
			shiftout <= 32'b0;
		end else begin
			case (aluop_i)
				`SLL: begin
					shiftout <= reg1_i << reg2_i;
				end
				`SLLV: begin                 // reg2_i should be 0 at [31:5]
					shiftout <= reg1_i << reg2_i;
				end
				`SRA: begin
					// shiftout <= reg1_i >>> reg2_i;
					shiftout <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
				end
				`SRAV: begin                 // reg2_i should be 0 at [31:5]
					//shiftout <= reg1_i >>> reg2_i;
					shiftout <= ({32{reg1_i[31]}} << (6'd32-{1'b0, reg2_i[4:0]}))
												| reg1_i >> reg2_i[4:0];
				end
				`SRL: begin
					shiftout <= reg1_i >> reg2_i;
				end
				`SRLV: begin                 // reg2_i should be 0 at [31:5]
					shiftout <= reg1_i >> reg2_i;
				end
				default: begin
					shiftout <= `ZeroWord;
				end
			endcase
		end
	end

	// 4/6 move instructions======================================================
	always @ (*) begin
		if (rst == `RstEnable) begin
			hi_t <= `ZeroWord;
			lo_t <= `ZeroWord;
		end else begin
			hi_t <= (mem_whilo_i == 1'b1) ? mem_hi_i :
              (wb_whilo_i == 1'b1) ? wb_hi_i : hi_i;
			lo_t <= (mem_whilo_i == 1'b1) ? mem_lo_i :
              (wb_whilo_i == 1'b1) ? wb_lo_i : lo_i;
		end
	end

	always @ (*) begin
		if (rst == `RstEnable) begin
			moveout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`MFHI: begin
					moveout <= hi_t;
				end
				`MFLO: begin
					moveout <= lo_t;
				end
				default: begin
					moveout <= `ZeroWord;
				end
			endcase
		end
	end

	// 8/21 arithmetic instructions===============================================
	always @ (*) begin
		if (rst == `RstEnable) begin
			arithout <= 64'b0;
		end else begin
			case (aluop_i)
				`ADDIU: begin              // immdiate should be load to reg2_i
					arithout <= reg1_i + reg2_i;
				end
				`ADDU: begin
					arithout <= reg1_i + reg2_i;
				end
				`SLT: begin
					arithout <= ($signed(reg1_i) < $signed(reg2_i)) ? 64'b1 : 64'b0;
				end
				`SLTI: begin               // immdiate should be load to reg2_i
					arithout <= ($signed(reg1_i) < $signed(reg2_i)) ? 64'b1 : 64'b0;
				end
				`SLTU: begin
					arithout <= (reg1_i < reg2_i) ? 64'b1 : 64'b0;
				end
				`SLTIU: begin              // immdiate should be load to reg2_i
					arithout <= (reg1_i < reg2_i) ? 64'b1 : 64'b0;
				end
				`SUBU: begin
					arithout <= reg1_i - reg2_i;
				end
				`MULT: begin
					arithout <= $signed(reg1_i) * $signed(reg2_i);
				end
				default: begin
					arithout <= 64'b0;
				end
			endcase
		end
	end

	// 10/12 branch jump instructions just do nothing ^_^ Yeah!===================

	// 6/15 load save instructions just do nothing ^_^ Yeah!======================



	// output general
	always @ (*) begin
		wd_o <= wd_i;
		wreg_o <= wreg_i;
		case (alusel_i)
			`Logic: begin
				wdata_o <= logicout;
			end
			`Shift: begin
				wdata_o <= shiftout;
			end
			`Move: begin
				wdata_o <= moveout;
			end
			`Arithmetic: begin
				wdata_o <= arithout[31:0];
			end
			`BranchJump: begin
				wdata_o <= link_addr_i;
			end
			`Privilege: begin
				wdata_o <= cp0out;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
	end


	// output hi lo
	always @ (*) begin
		if (rst == `RstEnable) begin
			lo_o <= `ZeroWord;
			hi_o <= `ZeroWord;
			whilo_o <= 1'b0;
		end else begin
			case (aluop_i)
				`MULT: begin
					{hi_o, lo_o} <= arithout;
					whilo_o <= 1'b1;
				end
				`MTHI: begin
					hi_o <= reg1_i;
					lo_o <= lo_t;
					whilo_o <= 1'b1;
				end
				`MTLO: begin
					hi_o <= hi_t;
					lo_o <= reg1_i;
					whilo_o <= 1'b1;
				end
				default: begin
					lo_o <= `ZeroWord;
					hi_o <= `ZeroWord;
					whilo_o <= 1'b0;
				end
			endcase
		end
	end

	// output mem addr
	always @ (*) begin
		if (rst == `RstEnable) begin
			mem_addr_o <= `ZeroWord;
		end else begin
			case (alusel_i)
				`Mem: begin                      // get offset directly from inst_i
					mem_addr_o <= reg1_i + signed_low16_inst;
				end
				default: begin
					mem_addr_o <= `ZeroWord;
				end
			endcase
		end
	end
	
	
endmodule