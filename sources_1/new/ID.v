`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/22 14:31:28
// Design Name: 
// Module Name: ID
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

module ID(
	input wire rst,
	input wire[31:0] pc_i,
	input wire[31:0] inst_i,
	input wire[31:0] reg1_data_i,
	input wire[31:0] reg2_data_i,
	input wire ex_wreg,
	input wire[4:0] ex_wd,
	input wire[31:0] ex_wdata,
	input wire mem_wreg,
	input wire[4:0] mem_wd,
	input wire[31:0] mem_wdata,
	input wire in_delay_i,
	input wire[7:0] ex_aluop,
	
	output wire[31:0] pc_o,
	output reg stop, 
	output wire[31:0] inst_o,			//current instruction
	output reg [2:0] alusel_o,		//defined in header.v, 8 types in total
	output reg [7:0] aluop_o,		//defined in header.v, 47 types of instructions in total 
	output reg [31:0] reg1_o,		//value of register 1
	output reg [31:0] reg2_o,		//value of register 2
	output reg [4:0] wd_o,			//target register if write
	output reg wreg_o,				//whether write to register or not
	output reg reg2_read_o,		//nothing to do with ALU
	output reg [4:0] reg2_addr_o,	//nothing to do with ALU
	output reg reg1_read_o,		//nothing to do with ALU
	output reg [4:0] reg1_addr_o,	//nothing to do with ALU
	output wire in_delay_o,				//indicator of delay slot for CURRENT instruction
	output reg [31:0] link_addr_o,	//link address to be put in wd_o if neccessary
	output reg next_delay,			//indicator of delay slot for NEXT instruction
	output reg branch_flag,		//whether jump/branch or not
	output reg [31:0] branch_addr,	//target address if jump/branch
	
	input wire [4:0] exc_code_i,
	input wire [31:0] exc_badvaddr_i,
	output reg [4:0] exc_code_o,
	output reg [31:0] exc_epc_o,
	output reg [31:0] exc_badvaddr_o
	);
	
	wire[5:0] op=inst_i[31:26];
	wire[4:0] sa=inst_i[10:6];
	wire[5:0] func=inst_i[5:0];
	wire[4:0] rs=inst_i[25:21];
	wire[4:0] rt=inst_i[20:16];
	wire[4:0] rd=inst_i[15:11];

	reg[31:0] imm;

	assign inst_o = inst_i;
	assign pc_o = pc_i;

	//reg1_o
	always @(*) begin
		if (ex_wreg == `WriteEnable && ex_wd == reg1_addr_o && reg1_read_o == `ReadEnable) //forwarding
			reg1_o <= ex_wdata;
		else if (mem_wreg == `WriteEnable && mem_wd == reg1_addr_o && reg1_read_o == `ReadEnable)
			reg1_o <= mem_wdata;
		else if (reg1_read_o == `ReadEnable)
			reg1_o <= reg1_data_i;
		else if (reg1_read_o == `ReadDisable)
			reg1_o <= imm;
		else
			reg1_o <= `ZeroWord;
	end

	//reg2_o
	always @(*) begin
		if (ex_wreg == `WriteEnable && ex_wd == reg2_addr_o && reg2_read_o == `ReadEnable) //
			reg2_o <= ex_wdata;
		else if (mem_wreg == `WriteEnable && mem_wd == reg2_addr_o && reg2_read_o == `ReadEnable)
			reg2_o <= mem_wdata;
		else if (reg2_read_o == `ReadEnable) 
			reg2_o <= reg2_data_i;
		else if (reg2_read_o == `ReadDisable)
			reg2_o <= imm;
		else
			reg2_o <= `ZeroWord;
	end

	assign in_delay_o = in_delay_i;

	wire [31:0] pc_4;
	assign pc_4=pc_i+4;

	wire [31:0] pc_8;
	assign pc_8=pc_i+8;

	wire [31:0] jump_addr_26;
	assign jump_addr_26={pc_4[31:28], inst_i[25:0], 2'b00};

	wire [31:0] jump_addr_16;
	assign jump_addr_16=(pc_i+4)+{{14{inst_i[15]}}, inst_i[15:0], 2'b00};
	//sign extented

	wire [31:0] zero_imm;
	assign zero_imm={ {16{1'b0}} , inst_i[15:0]};

	wire [31:0] signed_imm;
	assign signed_imm={ {16{inst_i[15]}}, inst_i[15:0] };

	/*always @(*)
	begin
		if (rst==`RstEnable)
				stop<=`NoStop;
		else begin
			case (ex_aluop) 
				`LB: stop <= `Stop;
				`LBU: stop <= `Stop;
				`LHU: stop <= `Stop;
				`LW: stop <= `Stop;
				`SB: stop <= `Stop;
				`SW: stop <= `Stop;
				default: stop <= `NoStop;
			endcase
		end
	end*/

	task InvalidInstruction; begin
		alusel_o <= `Shift;
		aluop_o <= `SLL; 
		wreg_o <= 1'b0;
		reg1_read_o <= 1'b0;
		reg2_read_o <= 1'b0;
		next_delay <= 1'b0;
		branch_flag <= 1'b0;
			
		exc_code_o <= `EC_RI;
		if (in_delay_i)
			exc_epc_o <= pc_i - 4;
		else
			exc_epc_o <= pc_i;
		exc_badvaddr_o <= exc_badvaddr_i;
	end 
	endtask

	always @(*) begin
		if (rst == `RstEnable) begin
			//NOP
			alusel_o <= `Shift;
			aluop_o <= `SLL; 
			wd_o <= 0;
			reg1_addr_o <= 0;
			reg2_addr_o <= 0;
			link_addr_o <= 0;
			wreg_o <= 1'b0;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			next_delay <= 1'b0;
			branch_flag <= 1'b0;
			branch_addr <= 0;
			exc_code_o <= `EC_None;
			exc_epc_o <= `ZeroWord;
			exc_badvaddr_o <= `ZeroWord;
			imm <= 0;
		end else if (exc_code_i != `EC_None) begin
			alusel_o <= `Shift;
			aluop_o <= `SLL; 
			wd_o <= 0;
			reg1_addr_o <= 0;
			reg2_addr_o <= 0;
			link_addr_o <= 0;
			wreg_o <= 1'b0;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			next_delay <= 1'b0;
			branch_flag <= 1'b0;
			branch_addr <= 0;
			exc_code_o <= exc_code_i;
			if (in_delay_i)
				exc_epc_o <= pc_i - 4;
			else
				exc_epc_o <= pc_i;	
			exc_badvaddr_o <= exc_badvaddr_i;
			//exc_badvaddr_o <= pc_i;
			imm <= 0;
		end else
		begin
			alusel_o <= `Shift;
			aluop_o <= `SLL; 
			wd_o <= 0;
			reg1_addr_o <= 0;
			reg2_addr_o <= 0;
			link_addr_o <= 0;
			wreg_o <= 1'b0;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			next_delay <= 1'b0;
			branch_flag <= 1'b0;
			branch_addr <= 0;
			exc_code_o <= exc_code_i;
			exc_badvaddr_o <= exc_badvaddr_i;
			if (in_delay_i)
				exc_epc_o <= pc_i - 4;
			else
				exc_epc_o <= pc_i;
			imm <= 0;
			case(op)
				//000000
				`SPECIAL_OP: begin
					case(func)
						//AND
						6'b100100:begin
							alusel_o<=`Logic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`AND;
						end
						
						//OR
						6'b100101:begin
							alusel_o<=`Logic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`OR;
						end
						
						//XOR
						6'b100110:begin
							alusel_o<=`Logic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`XOR;
						end
						
						//NOR
						6'b100111:begin
							alusel_o<=`Logic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`NOR;
						end
						
						//SLL
						//NOP IS IGNORED!!!!
						6'b000000:begin 
							alusel_o<=`Shift;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SLL;
							imm<={{27{1'b0}},inst_i[10:6]};
						end
						
						//SRL
						6'b000010:begin
							alusel_o<=`Shift;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SRL; 
							imm<={{27{1'b0}},inst_i[10:6]};
						end
						
						//SRA
						6'b000011:begin
							alusel_o<=`Shift;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SRA; 
							imm<={{27{1'b0}},inst_i[10:6]};
						end
						
						//SLLV
						6'b000100:begin
							alusel_o<=`Shift;
							wreg_o<=1;
							wd_o<=rd;
							reg1_read_o<=1;
							reg1_addr_o<=rt;
							reg2_read_o<=1;
							reg2_addr_o<=rs;
							next_delay<=0;
							branch_flag<=0;
							aluop_o<=`SLLV; 
						end
						
						//SRLV
						6'b000110:begin
							alusel_o<=`Shift;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rs;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SRLV; 
						end
						
						//SRAV
						6'b000111:begin
							alusel_o<=`Shift;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rs;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SRAV; 
						end
						
						//MFHI
						6'b010000:begin
							alusel_o<=`Move;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b0;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MFHI; 
						end
						
						//MFLO
						6'b010010:begin
							alusel_o<=`Move;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b0;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MFLO;
						end
						
						//MTHI
						6'b010001:begin
							alusel_o<=`Move;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MTHI;
						end
						
						//MTLO
						6'b010011:begin
							alusel_o<=`Move;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MTLO;
						end
						
						//ADD
						6'b100000:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`ADD;
						end
						
						//ADDU
						6'b100001:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`ADDU;
						end

						//SUB
						6'b100010:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SUB;
						end
						
						//SUBU
						6'b100011:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SUBU;
						end

						//SLT
						6'b101010:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SLT;
						end
						
						//SLTU
						6'b101011:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b1;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SLTU;
						end
						
						//MULT
						6'b011000:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MULT;
						end

						//MULTU
						6'b011001:begin
							alusel_o<=`Arithmetic;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b1;
							reg2_addr_o<=rt;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`MULTU;
						end
						
						//JR
						6'b001000:begin
							alusel_o<=`BranchJump;
							aluop_o<=`JR;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b1;
							branch_flag<=1'b1;
							branch_addr<=reg1_o;
						end
						
						//JALR
						6'b001001:begin
							alusel_o<=`BranchJump;
							wreg_o<=1'b1;
							wd_o<=rd;
							link_addr_o<=pc_8;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b1;
							branch_flag<=1'b1;
							branch_addr<=reg1_o;
							aluop_o<=`JALR;
						end

						//BREAK
						6'b001101:begin
							alusel_o<=`Trap;
							wreg_o<=1'b0;
							reg1_read_o<=1'b0;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`BREAK;
							
							exc_code_o <= `EC_Bp;
										 
							if (in_delay_i)
								exc_epc_o <= pc_i - 4; 
							else
								exc_epc_o <= pc_i;
							exc_badvaddr_o <= `ZeroWord;
						end
						
						//SYSCALL
						6'b001100:begin
							alusel_o<=`Trap;
							wreg_o<=1'b0;
							reg1_read_o<=1'b0;
							reg2_read_o<=1'b0;
							next_delay<=1'b0;
							branch_flag<=1'b0;
							aluop_o<=`SYSCALL;
							
							exc_code_o <= `EC_Sys;
										 
							if (in_delay_i)
								exc_epc_o <= pc_i - 4; 
							else
								exc_epc_o <= pc_i;
							exc_badvaddr_o <= `ZeroWord;
						end
						
						//DIV
						6'b011010: begin         
                            alusel_o<=`Arithmetic;
                            wreg_o<=1'b0;
                            reg1_read_o<=1'b1;
                            reg1_addr_o<=rs;
                            reg2_read_o<=1'b1;
                            reg2_addr_o<=rt;
                            next_delay<=1'b0;
                            branch_flag<=1'b0;
                            aluop_o<=`DIV; 
                        end
                        
                        //DIVU
                        6'b011011: begin
                            alusel_o<=`Arithmetic;
                            wreg_o<=1'b0;
                            reg1_read_o<=1'b1;
                            reg1_addr_o<=rs;
                            reg2_read_o<=1'b1;
                            reg2_addr_o<=rt;
                            next_delay<=1'b0;
                            branch_flag<=1'b0;
                            aluop_o<=`DIVU; 
                        end   
						
						default:
							InvalidInstruction();
					endcase
				end
				
				//ORI
				6'b001101: begin
					alusel_o<=`Logic;
					aluop_o<=`ORI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=zero_imm;
				end
				
				//ANDI
				6'b001100:begin
					alusel_o<=`Logic;
					aluop_o<=`ANDI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=zero_imm;
				end
				
				//XORI
				6'b001110:begin
					alusel_o<=`Logic;
					aluop_o<=`XORI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=zero_imm;
				end
				
				//LUI
				6'b001111:begin
					alusel_o<=`Logic;
					aluop_o<=`LUI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b0;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=zero_imm;
				end

				//ADDI
				6'b001000:begin
					alusel_o<=`Arithmetic;
					aluop_o<=`ADDI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//ADDIU
				6'b001001:begin
					alusel_o<=`Arithmetic;
					aluop_o<=`ADDIU;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//SLTI
				6'b001010:begin
					alusel_o<=`Arithmetic;
					aluop_o<=`SLTI;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//SLTIU
				6'b001011:begin
					alusel_o<=`Arithmetic;
					aluop_o<=`SLTIU;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//CP0
				6'b010000:begin
					case(rs)
						
						//MTC0
						5'b00100:begin
							alusel_o<=`Privilege;
							aluop_o<=`MTC0;
							wreg_o<=1'b0;
							wd_o<=rd;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rt;
							reg2_read_o<=1'b0;
							branch_flag<=1'b0;
							next_delay<=1'b0;
						end
						
						//MFC0
						5'b00000:begin
							alusel_o<=`Privilege;
							aluop_o<=`MFC0;
							wreg_o<=1'b1;
							wd_o<=rt;
							reg1_read_o<=1'b0;
							reg1_addr_o<=rd;
							reg2_read_o<=1'b0;
							branch_flag<=1'b0;
							next_delay<=1'b0;
						end
						
						//ERET
						5'b10000:begin
						
							case (func)
								6'b000010: begin
									alusel_o<=`Privilege;
									aluop_o<=`TLBWI;
									wreg_o<=1'b0;
									reg1_read_o<=1'b0;
									reg2_read_o<=1'b0;
									branch_flag<=1'b0;
									next_delay<=1'b0;
									
									exc_code_o <= `EC_None;
									exc_epc_o <= `ZeroWord;
									exc_badvaddr_o <= `ZeroWord;
								end
								
								6'b011000: begin
									alusel_o<=`Privilege;
									aluop_o<=`ERET;
									wreg_o<=1'b0;
									reg1_read_o<=1'b0;
									reg2_read_o<=1'b0;
									branch_flag<=1'b0;
									next_delay<=1'b0;
									
									exc_code_o <= `EC_Eret;
									exc_epc_o <= pc_i;
									exc_badvaddr_o <= `ZeroWord;
								end
								
								default:begin
									InvalidInstruction();
								end
							endcase
						end
						
						default:
							InvalidInstruction();
					endcase
				end
				
				//LB
				6'b100000:begin
					alusel_o<=`Mem;
					aluop_o<=`LB;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
		
				//LBU
				6'b100100:begin
					alusel_o<=`Mem;
					aluop_o<=`LBU;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end

				//LH
				6'b100001:begin
					alusel_o<=`Mem;
					aluop_o<=`LH;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//LHU
				6'b100101:begin
					alusel_o<=`Mem;
					aluop_o<=`LHU;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//LW
				6'b100011:begin
					alusel_o<=`Mem;
					aluop_o<=`LW;
					wreg_o<=1'b1;
					wd_o<=rt;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					branch_flag<=1'b0;
					next_delay<=1'b0;
					imm<=signed_imm;
				end
				
				//SB
				6'b101000:begin
					alusel_o<=`Mem;
					aluop_o<=`SB;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b1;
					reg2_addr_o<=rt;
					branch_flag<=1'b0;
					next_delay<=1'b0;
				end

				//SH
				6'b101001:begin
					alusel_o<=`Mem;
					aluop_o<=`SH;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b1;
					reg2_addr_o<=rt;
					branch_flag<=1'b0;
					next_delay<=1'b0;
				end
				
				//SW
				6'b101011:begin
					alusel_o<=`Mem;
					aluop_o<=`SW;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b1;
					reg2_addr_o<=rt;
					branch_flag<=1'b0;
					next_delay<=1'b0;
				end
				
				//J
				6'b000010:begin
					alusel_o<=`BranchJump;
					aluop_o<=`J;
					wreg_o<=1'b0;
					reg1_read_o<=1'b0;
					reg2_read_o<=1'b0;
					branch_flag<=1'b1;
					next_delay<=1'b1;
					branch_addr<= jump_addr_26;
				end
				
				//JAL
				6'b000011:begin
					alusel_o<=`BranchJump;
					aluop_o<=`JAL;
					wreg_o<=1'b1;
					wd_o<=5'b11111;//reg[31]
					reg1_read_o<=1'b0;
					reg2_read_o<=1'b0;
					next_delay<=1'b1;
					link_addr_o<=pc_8;
					branch_flag<=1'b1;
					branch_addr<=jump_addr_26;
				end
				
				//BEQ
				6'b000100:begin
					alusel_o<=`BranchJump;
					aluop_o<=`BEQ;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b1;
					reg2_addr_o<=rt;
					next_delay<=1'b1;
					if (reg1_o==reg2_o)begin
						branch_flag<=1'b1;
						branch_addr<=jump_addr_16;
					end else
					begin
						branch_flag<=1'b0;
					end
				end
				
				//BGTZ
				6'b000111:begin
					alusel_o<=`BranchJump;
					aluop_o<=`BGTZ; 
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					next_delay<=1'b1;
					if ((reg1_o[31]==1'b0) && (reg1_o!=`ZeroWord))begin
						branch_flag<=1'b1;
						branch_addr<=jump_addr_16;
					end
					else
					begin
						branch_flag<=1'b0;
					end
				end
				
				//BLEZ
				6'b000110:begin
					alusel_o<=`BranchJump;
					aluop_o<=`BLEZ;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b0;
					next_delay<=1'b1;
					if ((reg1_o[31]==1'b1) || (reg1_o==`ZeroWord)) begin
						branch_flag<=1'b1;
						branch_addr<=jump_addr_16;
					end else
					begin
						branch_flag<=1'b0;
					end
				end
				
				//BNE
				6'b000101:begin
					alusel_o<=`BranchJump;
					aluop_o<=`BNE;
					wreg_o<=1'b0;
					reg1_read_o<=1'b1;
					reg1_addr_o<=rs;
					reg2_read_o<=1'b1;
					reg2_addr_o<=rt;
					next_delay<=1'b1;
					if (reg1_o!=reg2_o)begin
						branch_flag<=1'b1;
						branch_addr<=jump_addr_16;
					end else
					begin
						branch_flag<=1'b0;
					end
				end
				
				//BLTZ && BGEZ
				6'b000001:begin
					case(rt)
					
						//BLTZ
						5'b00000:begin
							alusel_o<=`BranchJump;
							aluop_o<=`BLTZ;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b1;
							if (reg1_o[31]==1'b1) begin
								branch_flag<=1'b1;
								branch_addr<=jump_addr_16;
							end else
							begin
								branch_flag<=1'b0;
							end
						end
						
						//BGEZ
						5'b00001: begin
							alusel_o<=`BranchJump;
							aluop_o<=`BGEZ;
							wreg_o<=1'b0;
							reg1_read_o<=1'b1;
							reg1_addr_o<=rs;
							reg2_read_o<=1'b0;
							next_delay<=1'b1;
							if (reg1_o[31]==1'b0) begin
								branch_flag<=1'b1;
								branch_addr<=jump_addr_16;
							end else
							begin
								branch_flag<=1'b0;
							end
						end
						
						//BGEZAL
						5'b10001: begin
							alusel_o <= `BranchJump;
							aluop_o <= `BGEZAL;
							wreg_o <= 1'b1;
							wd_o <= 5'b11111;
							link_addr_o <= pc_8;
							reg1_read_o <= 1'b1;
							reg1_addr_o <= rs;
							reg2_read_o <= 1'b0;
							next_delay <= 1'b1;
							if (reg1_o[31] == 1'b0) begin
								branch_flag <= 1'b1;
								branch_addr <= jump_addr_16;
							end else
							begin
								branch_flag <= 1'b0;
							end
						end
						
						//BLTZAL
						5'b10000:begin
							alusel_o <= `BranchJump;
							aluop_o <= `BLTZAL;
							wreg_o <= 1'b1;
							wd_o <= 5'b11111;
							link_addr_o <= pc_8;
							reg1_read_o <= 1'b1;
							reg1_addr_o <= rs;
							reg2_read_o <= 1'b0;
							next_delay <= 1'b1;
							if (reg1_o[31] == 1'b1) begin
								branch_flag <= 1'b1;
								branch_addr <= jump_addr_16;
							end else
							begin
								branch_flag <= 1'b0;
							end
						end
			
						default:
							InvalidInstruction();
					endcase
				end
				
				default:
					InvalidInstruction();
			endcase
		end
	end

endmodule
