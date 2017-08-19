`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/23 16:05:15
// Design Name: 
// Module Name: MiniMIPS32
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

module MiniMIPS32(
	input  wire 				cpu_clk_75M,
	input  wire 				cpu_rst_n,

	//instruction wishbone interface signal
	input  wire [`InstBus 	 ] 	imem_inst_i,
	input  wire 				imem_ack_i,
	output wire [`InstAddrBus] 	imem_addr_o,
	output wire [`InstBus 	 ] 	imem_inst_o,
	output wire 				imem_we_o,
	output wire [`ByteSelect ] 	imem_sel_o,
	output wire 				imem_stb_o,
	output wire 				imem_cyc_o,
	
	//data wishbone interface signal
	input  wire [`RegBus 	 ] 	dmem_data_i,
	input  wire 				dmem_ack_i,
	output wire [`InstAddrBus] 	dmem_addr_o,
	output wire [`RegBus 	 ] 	dmem_data_o,
	output wire 				dmem_we_o, 
	output wire [`ByteSelect ] 	dmem_sel_o,
	output wire 				dmem_stb_o,
	output wire 				dmem_cyc_o,
	
	input  wire [`AluSelBus  ] 	s0_msel,
	
	input  wire [`Cp0Int] 		int_i,
	output wire 				int_time_o
    );

    // 连接IF/ID模块与译码阶段ID模块的变量 
	wire [`InstAddrBus] pc;//(*mark_debug = "true"*)
	wire [`InstAddrBus] id_pc_i;
	wire [`InstBus 	  ] id_inst_i;//(*mark_debug = "true"*)
	
	wire 				pc_branch_flag_i;
	wire [`InstAddrBus] pc_branch_target_address_i;
	
	wire [`InstBus 	  ] inst_addr;
	wire [`InstBus 	  ] inst_i;
	
	// 连接译码阶段ID模块与通用寄存器Regfile模块的变量 
	wire 				reg1_read;
	wire [`RegAddrBus ] reg1_addr;
	wire [`RegBus     ] reg1_data;
	wire 				reg2_read;
	wire [`RegAddrBus ] reg2_addr;
	wire [`RegBus     ] reg2_data;
	
	// 连接MEM/WB模块的输出与回写阶段的输入的变量
	wire 				wb_wreg_i;
	wire [`RegAddrBus ] wb_wd_i;
	wire [`RegBus     ] wb_wdata_i;
	
	// 连接译码阶段ID模块输出与ID/EX模块的输入的变量 
	wire [`AluOpBus   ] id_aluop_o;
	wire [`AluSelBus  ] id_alusel_o;
	wire [`RegBus 	  ] id_src1_o;
	wire [`RegBus 	  ] id_src2_o;
	wire 				id_wreg_o;
	wire [`ExcCode 	  ] id_wd_o;
	
	wire 				id_in_delay_i;
	wire 				id_in_delay_o;
	wire [`InstAddrBus] id_link_addr_o;
	wire 				id_next_delay;
	wire [`InstBus 	  ] id_inst_o;
	wire [`InstBus 	  ] id_pc_o;
	
	wire [`ExcCode 	  ] id_exc_code_i;
	wire [`InstAddrBus] id_exc_badvaddr_i;
	wire [`ExcCode 	  ] id_exc_code_o;
	wire [`InstBus 	  ] id_exc_epc_o;
	wire [`InstAddrBus] id_exc_badvaddr_o;
	
	// 连接ID/EX模块输出与执行阶段EX模块的输入的变量
	wire [`AluOpBus   ] ex_aluop_i;
	wire [`AluSelBus  ] ex_alusel_i;
	wire [`RegBus 	  ] ex_src1_i;
	wire [`RegBus 	  ] ex_src2_i;
	wire 				ex_wreg_i;
	wire [`RegAddrBus ] ex_wd_i;
	
	// 连接执行阶段EX模块的输出与EX/MEM模块的输入的变量 
	wire 				ex_wreg_o;
	wire [`RegAddrBus ] ex_wd_o;
	wire [`RegBus 	  ] ex_wdata_o;
	
	wire [`RegBus 	  ] ex_hi_i;
	wire [`RegBus 	  ] ex_lo_i;
	
	wire 				ex_whilo_o;
	wire [`RegBus 	  ] ex_hi_o;
	wire [`RegBus 	  ] ex_lo_o;
	
	wire 				ex_is_in_delayslot_i;
	wire				ex_in_delay_o;
	wire [`InstAddrBus] ex_link_address_i;
	
	wire [`InstBus    ] ex_inst_i;
	wire [`InstBus    ] ex_pc_i;
	wire [`InstBus    ] ex_pc_o;
	wire [`AluOpBus   ] ex_aluop_o;
	wire [`InstAddrBus] ex_mem_addr_o;
	wire [`RegBus     ] ex_reg2_o;

	wire			    ex_mem_cp0_reg_we;
	wire [`RegAddrBus ]	ex_mem_cp0_write_addr;
	wire [`RegBus 	  ]	ex_mem_cp0_data;
  	wire				ex_wb_cp0_reg_we;
	wire [`RegAddrBus ] ex_wb_cp0_reg_write_addr;
	wire [`RegBus     ]	ex_wb_cp0_reg_data;
	wire [`RegAddrBus ]	ex_cp0_reg_read_addr_o;
	wire        		ex_cp0_reg_we_o;
	wire [`RegAddrBus ] ex_cp0_reg_write_addr_o;
	wire [`RegBus 	  ] ex_cp0_reg_data_o;
	
	wire [`ExcCode 	  ] ex_exc_code_i;
	wire [`InstBus 	  ] ex_exc_epc_i;
	wire [`InstAddrBus] ex_exc_badvaddr_i;
	wire [`ExcCode 	  ] ex_exc_code_o;
	wire [`InstBus 	  ] ex_exc_epc_o;
	wire [`InstAddrBus] ex_exc_badvaddr_o;
	
	// 连接EX/MEM模块的输出与访存阶段MEM模块的输入的变量  
	wire 				mem_wreg_i;
	wire [`RegAddrBus ] mem_wd_i;
	wire [`RegBus 	  ] mem_wdata_i;
	
	wire 				mem_whilo_i;
	wire [`RegBus 	  ] mem_hi_i;
	wire [`RegBus 	  ] mem_lo_i;

	// 连接访存阶段MEM模块的输出与MEM/WB模块的输入的变量
	wire 				mem_wreg_o;
	wire [`RegAddrBus ] mem_wd_o;
	wire [`RegBus 	  ] mem_wdata_o;
	
	wire 			 	mem_whilo_o;
	wire [`RegBus 	  ] mem_hi_o;
	wire [`RegBus 	  ] mem_lo_o;
	
	wire [`AluOpBus   ] mem_aluop_i;
	wire [`InstAddrBus] mem_addr_i;
	wire [`RegBus 	  ] mem_reg2_i;

	wire 				mem_cp0_reg_we_i;
	wire [`RegAddrBus ] mem_cp0_reg_write_addr_i;
	wire [`RegBus 	  ] mem_cp0_reg_data_i;

	wire 				mem_cp0_reg_we_o;
	wire [`RegAddrBus ] mem_cp0_reg_write_addr_o;
	wire [`RegBus 	  ] mem_cp0_reg_data_o;

	wire [`ExcCode 	  ] mem_exc_code_i;
	wire [`InstBus 	  ] mem_exc_epc_i;
	wire [`InstAddrBus] mem_exc_badvaddr_i;
	wire [`ExcCode 	  ] mem_exc_code_o;
	wire [`InstBus 	  ] mem_exc_epc_o;
	wire [`InstAddrBus] mem_exc_badvaddr_o;
	
	wire 				mem_in_delay_i;
	wire [`InstBus 	  ] mem_pc_i;

	wire 				wb_whilo_i;
	wire [`RegBus 	  ] wb_hi_i;
	wire [`RegBus 	  ] wb_lo_i;
	
	wire [`InstAddrBus] if_addr_o;
	wire [`InstBus 	  ] if_inst_o;
	wire [`ExcCode 	  ] if_exc_code_o;
	wire [`InstAddrBus] if_exc_badvaddr_o;
	
	wire 				cp0_int_com;
	wire [`ExcCode 	  ] cp0_exc_code_i;
	wire [`InstBus 	  ] cp0_exc_epc_i;
	wire [`InstAddrBus] cp0_exc_badvaddr_i;
	wire 				cp0_flush_req;
	wire 				cp0_exc_jump_flag;
	wire [`InstAddrBus] cp0_exc_jump_addr;
	wire [`RegBus 	  ] cp0_data_o;
	wire				cp0_in_delay_i;
	wire [`RegBus 	  ] badvaddr_o;
	wire [`RegBus 	  ] count_o;
	wire [`RegBus 	  ] compare_o;
	wire [`RegBus 	  ] status_o;
	wire [`RegBus 	  ] cause_o;
	wire [`RegBus 	  ] epc_o;
	
	wire 				stop_from_id;
	wire 				stop_from_ex;
	wire 				stop_from_mem;
	wire 				stop_from_pc;
	wire				stop_from_if;
	wire 				ctrl_flush_i;
	wire [`Stall 	  ] stall;
	wire 				flush;
	
	wire 				mem_ce_o;
	wire 				mem_we_o;
	wire [`ByteSelect ] mem_sel_o;
	wire [`InstAddrBus] mem_addr_o;
	wire [`RegBus 	  ] mem_data_o;
	wire [`RegBus 	  ] mem_data_i;
	
	wire 		        int_ack;
	wire [7:0] 	        ser_data_out;
	wire [7:0] 	        ser_data_in;
	wire 		        ser_write_enable;
	wire 		        ser_write_not_busy;
	
	wire 		        read_ready;
	wire 		        write_ready;
	wire 		        has_break;
	wire [7:0]	        com_data_out1;
	wire [7:0]	        com_data_in1;
	wire 		        com_write_enable1;
	wire 		        com_int_ack1;
	wire 		        stop_flag;
	wire [`InstAddrBus] break_addr;

	wire 				cp0_reg_read_o;

	//div
	wire[`DoubleRegBus] div_result;
    wire 				div_ready;
    wire[`RegBus 	  ] div_opdata1;
    wire[`RegBus 	  ] div_opdata2;
    wire 				div_start;
    wire 				signed_div;

	wire		 		pc_rom_ce;	
	wire		 		rom_ce;

	// pc_reg例化
	PC pc0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n), .pc(pc),
			 .branch_flag_i(pc_branch_flag_i), .branch_target_address_i(pc_branch_target_address_i),
			 .stall(stall),
			 .cp0_branch_flag(cp0_exc_jump_flag),
			 .cp0_branch_addr(cp0_exc_jump_addr),
			 .ce(pc_rom_ce));
	

	IF if0 (
		.if_addr_i(pc), 
		.cpu_rst_n(cpu_rst_n),
		.if_inst_addr_o(inst_addr), 
		.if_addr_o(if_addr_o), 
		.if_exc_code_o(if_exc_code_o),
		.if_exc_badvaddr_o(if_exc_badvaddr_o),
		.if_ce_i(pc_rom_ce),
		.if_ce_o(rom_ce)
    );
	
	iwishbone_bus_if iwishbone_bus_if(
    	.cpu_clk_75M(cpu_clk_75M),
    	.cpu_rst_n(cpu_rst_n),
    	
    	.s0_msel(s0_msel),
    
    	.stall_i(stall),
    	.flush_i(flush),
						
    	.cpu_ce_i(rom_ce),
    	.cpu_data_i(`ZeroWord),
    	.cpu_addr_i(inst_addr),
    	.cpu_we_i(`WriteDisable),
    	.cpu_sel_i(4'b1111),
    	.cpu_data_o(if_inst_o),
						
    	.iwishbone_inst_i(imem_inst_i),
    	.iwishbone_ack_i(imem_ack_i),
    	.iwishbone_addr_o(imem_addr_o),
    	.iwishbone_inst_o(imem_inst_o),
    	.iwishbone_we_o(imem_we_o),
    	.iwishbone_sel_o(imem_sel_o),
    	.iwishbone_stb_o(imem_stb_o),
    	.iwishbone_cyc_o(imem_cyc_o),
						
    	.stallreq(stop_from_if)    
	);
	
	// IF/ID模块例化
	IF_ID if_id0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n),
				.if_pc(if_addr_o),
				.if_inst(if_inst_o),
				.exc_code_i(if_exc_code_o),
			 	.id_pc(id_pc_i),
			 	.id_inst(id_inst_i),
				.stall(stall),
				.flush(flush),
				.exc_code_o(id_exc_code_i),
				.exc_badvaddr_i(if_exc_badvaddr_o),
				.exc_badvaddr_o(id_exc_badvaddr_i));

	// 译码阶段ID模块例化
	ID id0(.cpu_rst_n(cpu_rst_n), .id_pc_i(id_pc_i), .id_pc_o(id_pc_o), 
				.id_inst_i(id_inst_i),
			    .id_reg1_data_i(reg1_data), .id_reg2_data_i(reg2_data),
			    .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o), .ex_wd(ex_wd_o),
			    .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o), .mem_wd(mem_wd_o),
			    .id_in_delay_i(id_in_delay_i),
			    .id_reg1_read_o(reg1_read), .id_reg2_read_o(reg2_read), 	  
			    .id_reg1_addr_o(reg1_addr), .id_reg2_addr_o(reg2_addr), 
			    .id_aluop_o(id_aluop_o), .id_alusel_o(id_alusel_o),
			    .id_src1_o(id_src1_o), .id_src2_o(id_src2_o),
			    .id_wd_o(id_wd_o), .id_wreg_o(id_wreg_o),
			    .id_in_delay_o(id_in_delay_o), .id_link_addr_o(id_link_addr_o),    .id_next_delay(id_next_delay),
			    .branch_addr(pc_branch_target_address_i), 
			    .branch_flag(pc_branch_flag_i),
			    .id_inst_o(id_inst_o),
			    .ex_aluop(ex_aluop_o),
			    .stop_from_id(stop_from_id),
			    .id_exc_code_i(id_exc_code_i),
			    .id_exc_badvaddr_i(id_exc_badvaddr_i),
			    .id_exc_code_o(id_exc_code_o),
			    .id_exc_epc_o(id_exc_epc_o),
			    .id_exc_badvaddr_o(id_exc_badvaddr_o));
	
	// 通用寄存器Regfile模块例化
	REG reg0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n), .we(wb_wreg_i), 
				.waddr(wb_wd_i), .wdata(wb_wdata_i),
				.reg1_read(reg1_read), .reg1_addr(reg1_addr), .reg1_data(reg1_data),
				.reg2_read(reg2_read), .reg2_addr(reg2_addr), .reg2_data(reg2_data));
	
	// ID/EX模块例化
	ID_EX id_ex0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n), 
	            .id_alusel(id_alusel_o), .id_aluop(id_aluop_o),
				.id_src1(id_src1_o), .id_src2(id_src2_o), .id_wd(id_wd_o), 
				.id_wreg(id_wreg_o),
				.id_is_in_delayslot(id_in_delay_o), 
				.id_link_address(id_link_addr_o),
				.next_inst_in_delayslot_i(id_next_delay),
				.id_inst(id_inst_o), .id_pc(id_pc_o),
				.ex_alusel(ex_alusel_i), .ex_aluop(ex_aluop_i),
				.ex_src1(ex_src1_i), .ex_src2(ex_src2_i), 
				.ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
				.is_in_delayslot_o(id_in_delay_i), 
				.ex_is_in_delayslot(ex_is_in_delayslot_i), 
				.ex_link_address(ex_link_address_i),
				.ex_inst(ex_inst_i), .ex_pc(ex_pc_i),
				.stall(stall),
				.flush(flush),
				.exc_code_i(id_exc_code_o),
				.exc_epc_i(id_exc_epc_o),
				.exc_badvaddr_i(id_exc_badvaddr_o),
				.exc_code_o(ex_exc_code_i),
				.exc_epc_o(ex_exc_epc_i),
				.exc_badvaddr_o(ex_exc_badvaddr_i));
	
	// EX模块例化
	EX ex0(.cpu_rst_n(cpu_rst_n), .ex_alusel_i(ex_alusel_i), 
				.ex_aluop_i(ex_aluop_i), .ex_pc_i(ex_pc_i), .ex_pc_o(ex_pc_o),
				.ex_src1_i(ex_src1_i), .ex_src2_i(ex_src2_i),
				.ex_wd_i(ex_wd_i), .ex_wreg_i(ex_wreg_i),
				.hi_i(ex_hi_i), .lo_i(ex_lo_i), 
				.mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
				.wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i),
				.in_delay_i(ex_is_in_delayslot_i), .in_delay_o(ex_in_delay_o), 
				.link_addr_i(ex_link_address_i), .ex_inst_i(ex_inst_i),
				.ex_wd_o(ex_wd_o), .ex_wreg_o(ex_wreg_o), .ex_wdata_o(ex_wdata_o),
				.ex_whilo_o(ex_whilo_o), .ex_hi_o(ex_hi_o), .ex_lo_o(ex_lo_o),
				.ex_aluop_o(ex_aluop_o), .mem_addr_o(ex_mem_addr_o), 
				.ex_reg2_o(ex_reg2_o),
				.cp0_reg_read_data_i(cp0_data_o),
				.ex_cp0_reg_read_addr_o(ex_cp0_reg_read_addr_o),
				.ex_cp0_reg_data_o(ex_cp0_reg_data_o),
				.ex_cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
				.ex_cp0_reg_we_o(ex_cp0_reg_we_o),
				.ex_exc_code_i(ex_exc_code_i),
				.ex_exc_epc_i(ex_exc_epc_i),
				.ex_exc_badvaddr_i(ex_exc_badvaddr_i),
				.ex_exc_code_o(ex_exc_code_o),
				.ex_exc_epc_o(ex_exc_epc_o),
				.ex_exc_badvaddr_o(ex_exc_badvaddr_o),
				.cp0_reg_read_o(cp0_reg_read_o),
				 //div
				.div_result_i(div_result),
	            .div_ready_i(div_ready),
	            .div_opdata1_o(div_opdata1),
	            .div_opdata2_o(div_opdata2),
	            .div_start_o(div_start),
	            .signed_div_o(signed_div),    
				.stop_from_ex(stop_from_ex));
		
	EX_MEM ex_mem0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n), 
				.ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o),
				.ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
				.ex_aluop(ex_aluop_o), .ex_mem_addr(ex_mem_addr_o), 
				.ex_reg2(ex_reg2_o),
				.mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i),	.mem_wdata(mem_wdata_i),
				.mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
				.mem_aluop(mem_aluop_i), .mem_mem_addr(mem_addr_i), 
				.mem_reg2(mem_reg2_i),
				.ex_cp0_reg_we(ex_cp0_reg_we_o),
				.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
				.ex_cp0_reg_data(ex_cp0_reg_data_o),
				.mem_cp0_reg_we(mem_cp0_reg_we_i),
				.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
				.mem_cp0_reg_data(mem_cp0_reg_data_i),
				.stall(stall),
				.flush(flush),
				.exc_code_i(ex_exc_code_o),
			    .exc_epc_i(ex_exc_epc_o),
			    .exc_badvaddr_i(ex_exc_badvaddr_o),
			    .exc_code_o(mem_exc_code_i),
			    .exc_epc_o(mem_exc_epc_i),
			    .exc_badvaddr_o(mem_exc_badvaddr_i), 
			    .ex_in_delay(ex_in_delay_o), .mem_in_delay(mem_in_delay_i), 
			    .ex_pc(ex_pc_o), .mem_pc(mem_pc_i));

	// MEM模块例化 
	MEM mem0(.cpu_rst_n(cpu_rst_n), .mem_wd_i(mem_wd_i), 
				.mem_wreg_i(mem_wreg_i), .mem_wdata_i(mem_wdata_i), 
	            .mem_in_delay_i(mem_in_delay_i), .mem_pc_i(mem_pc_i),
				.mem_whilo_i(mem_whilo_i), .mem_hi_i(mem_hi_i), .mem_lo_i(mem_lo_i),
				.mem_aluop_i(mem_aluop_i), .mem_addr_i(mem_addr_i), 
				.mem_reg2_i(mem_reg2_i), .mem_data_i(mem_data_i),
				.mem_wd_o(mem_wd_o), .mem_wreg_o(mem_wreg_o), 
				.mem_wdata_o(mem_wdata_o),
				.mem_whilo_o(mem_whilo_o), .mem_hi_o(mem_hi_o), .mem_lo_o(mem_lo_o),
				.mem_data_o(mem_data_o), .mem_ce_o(mem_ce_o), .mem_sel_o(mem_sel_o),
				.mem_addr_o(mem_addr_o), .mem_we_o(mem_we_o),
				.mem_cp0_reg_we_i(mem_cp0_reg_we_i),
				.mem_cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
				.mem_cp0_reg_data_i(mem_cp0_reg_data_i),
				.ex_mem_cp0_data(ex_mem_cp0_data),
				.ex_mem_cp0_write_addr(ex_mem_cp0_write_addr),
				.ex_mem_cp0_reg_we(ex_mem_cp0_reg_we),
				.mem_exc_code_i(mem_exc_code_i),
				.mem_exc_epc_i(mem_exc_epc_i),
				.mem_exc_badvaddr_i(mem_exc_badvaddr_i),
				.exc_code_o(cp0_exc_code_i),
				.exc_epc_o(cp0_exc_epc_i),
				.exc_badvaddr_o(cp0_exc_badvaddr_i), 
				.in_delay_o(cp0_in_delay_i));
	
	dwishbone_bus_if dwishbone_bus_if(
		    	.cpu_clk_75M(cpu_clk_75M),
		    	.cpu_rst_n(cpu_rst_n),
		    	
		    	.s0_msel(s0_msel),
		    
		    	.stall_i(stall),
		    	.flush_i(flush),
								
		    	.cpu_ce_i(mem_ce_o),
		    	.cpu_data_i(mem_data_o),
		    	.cpu_addr_i(mem_addr_o),
		    	.cpu_we_i(mem_we_o),
		    	.cpu_sel_i(mem_sel_o),
		    	.cpu_data_o(mem_data_i),
								
		    	.wishbone_data_i(dmem_data_i),
		    	.wishbone_ack_i(dmem_ack_i),
		    	.wishbone_addr_o(dmem_addr_o),
		    	.wishbone_data_o(dmem_data_o),
		    	.wishbone_we_o(dmem_we_o),
		    	.wishbone_sel_o(dmem_sel_o),
		    	.wishbone_stb_o(dmem_stb_o),
		    	.wishbone_cyc_o(dmem_cyc_o),
								
		    	.stallreq(stop_from_mem)       
	);
	
	// MEM/WB模块例化			
	MEM_WB mem_wb0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n),
				.mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),	.mem_wdata(mem_wdata_o),
				.mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
				.wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i),
				.wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i),
				.stall(stall),
				.flush(flush));
						
	HILO hilo0(.cpu_clk_75M(cpu_clk_75M), .cpu_rst_n(cpu_rst_n), 
				.we(wb_whilo_i),
				.hi_i(wb_hi_i), .lo_i(wb_lo_i), .hi_o(ex_hi_i), .lo_o(ex_lo_i));
	
	CP0 cp0 (
				.cpu_clk_75M(cpu_clk_75M), 
				.cpu_rst_n(cpu_rst_n), 
				.we_i(ex_mem_cp0_reg_we), 
				.waddr_i(ex_mem_cp0_write_addr), 
				.raddr_i(ex_cp0_reg_read_addr_o), 
				.wdata_i(ex_mem_cp0_data), 
				.int_i(int_i), 
				.exc_code_i(cp0_exc_code_i), 
				.exc_epc_i(cp0_exc_epc_i), 
				.exc_badvaddr_i(cp0_exc_badvaddr_i), 
				.flush_req(ctrl_flush_i), 
				.exc_jump_flag(cp0_exc_jump_flag), 
				.exc_jump_addr(cp0_exc_jump_addr), 
				.data_o(cp0_data_o), 
				.badvaddr_o(badvaddr_o), 
				.count_o(count_o), 
				.compare_o(compare_o), 
				.status_o(status_o), 
				.cause_o(cause_o), 
				.epc_o(epc_o), 
				.int_time_o(int_time_o),
				.re(cp0_reg_read_o),
				.in_delay_i(cp0_in_delay_i)
	);
	
	CTRL ctrl0 (
			    .cpu_clk_75M(cpu_clk_75M), 
			    .cpu_rst_n(cpu_rst_n), 
			    .stop_from_id(stop_from_id), 
			    .stop_from_ex(stop_from_ex), 
			    .stop_from_mem(stop_from_mem), 
			    .stop_from_pc(stop_from_pc), 
			    .stop_from_if(stop_from_if), 
			    .ctrl_flush_i(ctrl_flush_i), 
			    .stall(stall), 
			    .flush_o(flush)
    );
    
    DIV div0(
		        .cpu_clk_75M(cpu_clk_75M),
		        .cpu_rst_n(cpu_rst_n),
		    
		        .signed_div_i(signed_div),
		        .div_opdata1(div_opdata1),
		        .div_opdata2(div_opdata2),
		        .div_start(div_start),
		    
		        .div_result(div_result),
		        .div_ready(div_ready)
    );
	
endmodule
