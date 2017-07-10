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
	input wire clk,
	input wire rst,
	input wire clk_2,
	//output wire clk,
	//output wire rst_1,

	//instruction wishbone interface signal
	input wire[31:0] iwishbone_data_i,
	input wire iwishbone_ack_i,
	output wire[31:0] iwishbone_addr_o,
	output wire[31:0] iwishbone_data_o,
	output wire iwishbone_we_o,
	output wire[3:0] iwishbone_sel_o,
	output wire iwishbone_stb_o,
	output wire iwishbone_cyc_o,
	
	//data wishbone interface signal
	input wire[31:0] dwishbone_data_i,
	input wire dwishbone_ack_i,
	output wire[31:0] dwishbone_addr_o,
	output wire[31:0] dwishbone_data_o,
	output wire dwishbone_we_o,
	output wire[3:0] dwishbone_sel_o,
	output wire dwishbone_stb_o,
	output wire dwishbone_cyc_o,
	
	input wire [5:0] int_i,
	output wire int_time_o
    );

	wire [31:0] pc;//(*mark_debug = "true"*)
	wire [31:0] id_pc_i;
	wire [31:0] id_inst_i;//(*mark_debug = "true"*)
	
	wire 		pc_branch_flag_i;
	wire [31:0] pc_branch_target_address_i;
	
	wire [31:0] inst_addr;
	wire [31:0] inst_i;
	
	wire 		reg1_read;
	wire [4:0] 	reg1_addr;
	wire [31:0] reg1_data;
	wire 		reg2_read;
	wire [4:0] 	reg2_addr;
	wire [31:0] reg2_data;
	
	wire 		wb_wreg_i;
	wire [4:0] 	wb_wd_i;
	wire [31:0] wb_wdata_i;
	
	wire [7:0] 	id_aluop_o;
	wire [2:0] 	id_alusel_o;
	wire [31:0] id_reg1_o;
	wire [31:0] id_reg2_o;
	wire 		id_wreg_o;
	wire [4:0] 	id_wd_o;
	
	wire 		id_is_in_delayslot_i;
	wire 		id_is_in_delayslot_o;
	wire [31:0] id_link_addr_o;
	wire 		id_next_inst_in_delayslot_o;
	wire [31:0] id_inst_o;
	wire [31:0] id_pc_o;
	
	wire [4:0] 	id_exc_code_i;
	wire [31:0] id_exc_badvaddr_i;
	wire [4:0] 	id_exc_code_o;
	wire [31:0] id_exc_epc_o;
	wire [31:0] id_exc_badvaddr_o;
	
	wire [7:0] 	ex_aluop_i;
	wire [2:0] 	ex_alusel_i;
	wire [31:0] ex_reg1_i;
	wire [31:0] ex_reg2_i;
	wire 		ex_wreg_i;
	wire [4:0] 	ex_wd_i;
	
	wire 		ex_wreg_o;
	wire [4:0] 	ex_wd_o;
	wire [31:0] ex_wdata_o;
	
	wire [31:0] ex_hi_i;
	wire [31:0] ex_lo_i;
	
	wire 		ex_whilo_o;
	wire [31:0] ex_hi_o;
	wire [31:0] ex_lo_o;
	
	wire 		ex_is_in_delayslot_i;
	wire [31:0] ex_link_address_i;
	
	wire [31:0] ex_inst_i;
	wire [31:0] ex_pc_i;
	wire [7:0] 	ex_aluop_o;
	wire [31:0] ex_mem_addr_o;
	wire [31:0] ex_reg2_o;

	wire		ex_mem_cp0_reg_we;
	wire [4:0]	ex_mem_cp0_write_addr;
	wire [31:0]	ex_mem_cp0_data;
  	wire		ex_wb_cp0_reg_we;
	wire [4:0]  ex_wb_cp0_reg_write_addr;
	wire [31:0]	ex_wb_cp0_reg_data;
	wire [4:0]	ex_cp0_reg_read_addr_o;
	wire        ex_cp0_reg_we_o;
	wire [4:0]  ex_cp0_reg_write_addr_o;
	wire [31:0] ex_cp0_reg_data_o;
	
	wire [4:0] 	ex_exc_code_i;
	wire [31:0] ex_exc_epc_i;
	wire [31:0] ex_exc_badvaddr_i;
	wire [4:0] 	ex_exc_code_o;
	wire [31:0] ex_exc_epc_o;
	wire [31:0] ex_exc_badvaddr_o;
	
	wire 		mem_wreg_i;
	wire [4:0] 	mem_wd_i;
	wire [31:0] mem_wdata_i;
	
	wire 		mem_whilo_i;
	wire [31:0] mem_hi_i;
	wire [31:0] mem_lo_i;

	wire 		mem_wreg_o;
	wire [4:0] 	mem_wd_o;
	wire [31:0] mem_wdata_o;
	
	wire 		mem_whilo_o;
	wire [31:0] mem_hi_o;
	wire [31:0] mem_lo_o;
	
	wire [7:0] 	mem_aluop_i;
	wire [31:0] mem_addr_i;
	wire [31:0] mem_reg2_i;

	wire 		mem_cp0_reg_we_i;
	wire [4:0] 	mem_cp0_reg_write_addr_i;
	wire [31:0] mem_cp0_reg_data_i;

	wire 		mem_cp0_reg_we_o;
	wire [4:0] 	mem_cp0_reg_write_addr_o;
	wire [31:0] mem_cp0_reg_data_o;

	wire [4:0] 	mem_exc_code_i;
	wire [31:0] mem_exc_epc_i;
	wire [31:0] mem_exc_badvaddr_i;
	wire [4:0] 	mem_exc_code_o;
	wire [31:0] mem_exc_epc_o;
	wire [31:0] mem_exc_badvaddr_o;

	
	wire 		wb_whilo_i;
	wire [31:0] wb_hi_i;
	wire [31:0] wb_lo_i;
	
	wire [31:0] if_addr_o;
	wire [31:0] if_inst_o;
	wire [4:0] 	if_exc_code_o;
	wire [31:0] if_exc_badvaddr_o;
	
	wire 		cp0_int_com;
	wire [4:0] 	cp0_exc_code_i;
	wire [31:0] cp0_exc_epc_i;
	wire [31:0] cp0_exc_badvaddr_i;
	wire 		cp0_flush_req;
	wire 		cp0_exc_jump_flag;
	wire [31:0] cp0_exc_jump_addr;
	wire [31:0] cp0_data_o;
	wire [31:0] badvaddr_o;
	wire [31:0] count_o;
	wire [31:0] compare_o;
	wire [31:0] status_o;
	wire [31:0] cause_o;
	wire [31:0] epc_o;
	
	wire 		stop_from_id;
	wire 		stop_from_ex;
	wire 		stop_from_mem;
	wire 		stop_from_pc;
	wire		stop_from_if;
	wire 		ctrl_flush_i;
	wire [5:0] 	stall;
	wire 		flush;
	
	wire 		mem_ce_o;
	wire 		mem_we_o;
	wire [3:0] 	mem_sel_o;
	wire [31:0] mem_addr_o;
	wire [31:0] mem_data_o;
	wire [31:0] mem_data_i;
	
	wire 		int_ack;
	wire [7:0] 	ser_data_out;
	wire [7:0] 	ser_data_in;
	wire 		ser_write_enable;
	wire 		ser_write_not_busy;
	
	wire 		read_ready;
	wire 		write_ready;
	wire 		has_break;
	wire [7:0]	com_data_out1;
	wire [7:0]	com_data_in1;
	wire 		com_write_enable1;
	wire 		com_int_ack1;
	wire 		stop_flag;
	wire [31:0] break_addr;

	wire 		cp0_reg_read_o;

	//div
	wire[`DoubleRegBus] div_result;
    wire div_ready;
    wire[`RegBus] div_opdata1;
    wire[`RegBus] div_opdata2;
    wire div_start;
    wire signed_div;

	wire		pc_rom_ce;	
	wire		rom_ce;
	PC pc0(.clk(clk), .rst(rst), .pc(pc),
			 .branch_flag_i(pc_branch_flag_i), .branch_target_address_i(pc_branch_target_address_i),
			 .stall(stall),
			 .cp0_branch_flag(cp0_exc_jump_flag),
			 .cp0_branch_addr(cp0_exc_jump_addr),
			 .ce(pc_rom_ce));
	
	IF if0 (
		.addr_i(pc), 
		.rst(rst),
		.inst_addr_o(inst_addr), 
		.addr_o(if_addr_o), 
		.exc_code_o(if_exc_code_o),
		.exc_badvaddr_o(if_exc_badvaddr_o),
		.ce_i(pc_rom_ce),
		.ce_o(rom_ce)
    );
	
	wishbone_bus_if iwishbone_bus_if(
    	.clk(clk_2),
    	.rst(rst),
    
    	.stall_i(stall),
    	.flush_i(flush),
						
    	.cpu_ce_i(rom_ce),
    	.cpu_data_i(`ZeroWord),
    	.cpu_addr_i(inst_addr),
    	.cpu_we_i(`WriteDisable),
    	.cpu_sel_i(4'b1111),
    	.cpu_data_o(if_inst_o),
						
    	.wishbone_data_i(iwishbone_data_i),
    	.wishbone_ack_i(iwishbone_ack_i),
    	.wishbone_addr_o(iwishbone_addr_o),
    	.wishbone_data_o(iwishbone_data_o),
    	.wishbone_we_o(iwishbone_we_o),
    	.wishbone_sel_o(iwishbone_sel_o),
    	.wishbone_stb_o(iwishbone_stb_o),
    	.wishbone_cyc_o(iwishbone_cyc_o),
						
    	.stallreq(stop_from_if)       
	);
	
	IF_ID if_id0(.clk(clk), .rst(rst),
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

	ID id0(.rst(rst), .pc_i(id_pc_i), .pc_o(id_pc_o), .inst_i(id_inst_i),
			 .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
			 .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o), .ex_wd(ex_wd_o),
			 .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o), .mem_wd(mem_wd_o),
			 .in_delay_i(id_is_in_delayslot_i),
			 .reg1_read_o(reg1_read), .reg2_read_o(reg2_read), 	  
			 .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr), 
			 .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
			 .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
			 .wd_o(id_wd_o), .wreg_o(id_wreg_o),
			 .in_delay_o(id_is_in_delayslot_o), .link_addr_o(id_link_addr_o), .next_delay(id_next_inst_in_delayslot_o),
			 .branch_addr(pc_branch_target_address_i), .branch_flag(pc_branch_flag_i),
			 .inst_o(id_inst_o),
			 .ex_aluop(ex_aluop_o),
			 .stop(stop_from_id),
			 .exc_code_i(id_exc_code_i),
			 .exc_badvaddr_i(id_exc_badvaddr_i),
			 .exc_code_o(id_exc_code_o),
			 .exc_epc_o(id_exc_epc_o),
			 .exc_badvaddr_o(id_exc_badvaddr_o));
	
	REG reg0(.clk(clk), .rst(rst), .we(wb_wreg_i), .waddr(wb_wd_i), .wdata(wb_wdata_i),
				.re1(reg1_read), .raddr1(reg1_addr), .rdata1(reg1_data),
				.re2(reg2_read), .raddr2(reg2_addr), .rdata2(reg2_data));
	
	ID_EX id_ex0(.clk(clk), .rst(rst), .id_alusel(id_alusel_o), .id_aluop(id_aluop_o),
					 .id_reg1(id_reg1_o), .id_reg2(id_reg2_o), .id_wd(id_wd_o), .id_wreg(id_wreg_o),
					 .id_is_in_delayslot(id_is_in_delayslot_o), .id_link_address(id_link_addr_o), .next_inst_in_delayslot_i(id_next_inst_in_delayslot_o),
					 .id_inst(id_inst_o), .id_pc(id_pc_o),
					 .ex_alusel(ex_alusel_i), .ex_aluop(ex_aluop_i),
					 .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i), .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
					 .is_in_delayslot_o(ex_is_in_delayslot_i), .ex_is_in_delayslot(id_is_in_delayslot_i), .ex_link_address(ex_link_address_i),
					 .ex_inst(ex_inst_i), .ex_pc(ex_pc_i),
					 .stall(stall),
					 .flush(flush),
					 .exc_code_i(id_exc_code_o),
					 .exc_epc_i(id_exc_epc_o),
					 .exc_badvaddr_i(id_exc_badvaddr_o),
					 .exc_code_o(ex_exc_code_i),
					 .exc_epc_o(ex_exc_epc_i),
					 .exc_badvaddr_o(ex_exc_badvaddr_i));
	
	EX ex0(.rst(rst), .alusel_i(ex_alusel_i), .aluop_i(ex_aluop_i), .pc_i(ex_pc_i),
			 .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
			 .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
			 .hi_i(ex_hi_i), .lo_i(ex_lo_i), 
			 .mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
			 .wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i),
			 .in_delay_i(ex_is_in_delayslot_i), .link_addr_i(ex_link_address_i),
			 .inst_i(ex_inst_i),
			 .wd_o(ex_wd_o), .wreg_o(ex_wreg_o), .wdata_o(ex_wdata_o),
			 .whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
			 .aluop_o(ex_aluop_o), .mem_addr_o(ex_mem_addr_o), .reg2_o(ex_reg2_o),
			 .cp0_reg_read_data_i(cp0_data_o),
			 .mem_cp0_wdata(ex_mem_cp0_data),
			 .mem_cp0_we(ex_mem_cp0_reg_we),
			 .mem_cp0_waddr(ex_mem_cp0_write_addr),
			 .cp0_reg_read_addr_o(ex_cp0_reg_read_addr_o),
			 .cp0_reg_wdata_o(ex_cp0_reg_data_o),
			 .cp0_reg_waddr_o(ex_cp0_reg_write_addr_o),
			 .cp0_reg_we_o(ex_cp0_reg_we_o),
			 .exc_code_i(ex_exc_code_i),
			 .exc_epc_i(ex_exc_epc_i),
			 .exc_badvaddr_i(ex_exc_badvaddr_i),
			 .exc_code_o(ex_exc_code_o),
			 .exc_epc_o(ex_exc_epc_o),
			 .exc_badvaddr_o(ex_exc_badvaddr_o),
			 .cp0_reg_read_o(cp0_reg_read_o),
			 //div
			 .div_result_i(div_result),
             .div_ready_i(div_ready),
             .div_opdata1_o(div_opdata1),
             .div_opdata2_o(div_opdata2),
             .div_start_o(div_start),
             .signed_div_o(signed_div),    
			 .stop(stop_from_ex));
	
	EX_MEM ex_mem0(.clk(clk), .rst(rst), .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o),
						.ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
						.ex_aluop(ex_aluop_o), .ex_mem_addr(ex_mem_addr_o), .ex_reg2(ex_reg2_o),
						.mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i),	.mem_wdata(mem_wdata_i),
						.mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
						.mem_aluop(mem_aluop_i), .mem_mem_addr(mem_addr_i), .mem_reg2(mem_reg2_i),
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
					   .exc_badvaddr_o(mem_exc_badvaddr_i));
	
	MEM mem0(.rst(rst), .wd_i(mem_wd_i), .wreg_i(mem_wreg_i), .wdata_i(mem_wdata_i), 
				.whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
				.aluop_i(mem_aluop_i), .mem_addr_i(mem_addr_i), .reg2_i(mem_reg2_i), .mem_data_i(mem_data_i),
				.wd_o(mem_wd_o), .wreg_o(mem_wreg_o), .wdata_o(mem_wdata_o),
				.whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o),
				.mem_data_o(mem_data_o), .mem_ce_o(mem_ce_o), .mem_sel_o(mem_sel_o),
				.mem_addr_o(mem_addr_o), .mem_we_o(mem_we_o),
				.cp0_reg_we_i(mem_cp0_reg_we_i),
				.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
				.cp0_reg_data_i(mem_cp0_reg_data_i),
				.cp0_reg_data_o(ex_mem_cp0_data),
				.cp0_reg_write_addr_o(ex_mem_cp0_write_addr),
				.cp0_reg_we_o(ex_mem_cp0_reg_we),
				.exc_code_i(mem_exc_code_i),
				.exc_epc_i(mem_exc_epc_i),
				.exc_badvaddr_i(mem_exc_badvaddr_i),
				.exc_code_o(cp0_exc_code_i),
				.exc_epc_o(cp0_exc_epc_i),
				.exc_badvaddr_o(cp0_exc_badvaddr_i));
				
	/*DEV_MEM dev_mem0(
    .clk(clk), 
	.rst(rst), 
	.ce(mem_ce_o), 
	.we_i(mem_we_o), 
	.sel(mem_sel_o), 
	.data_i(mem_data_o), 
	.addr(mem_addr_o), 
	.data_o(mem_data_i), 
	.dev_mem_addr(dev_mem_addr), 
	.dev_mem_data_in(dev_mem_data_in), 
	.dev_mem_data_out(dev_mem_data_out), 
	.dev_mem_is_write(dev_mem_is_write), 
	.stop_from_mem(stop_from_mem)
	);*/
				
	wishbone_bus_if dwishbone_bus_if(
    	.clk(clk_2),
    	.rst(rst),
    
    	.stall_i(stall),
    	.flush_i(flush),
						
    	.cpu_ce_i(mem_ce_o),
    	.cpu_data_i(mem_data_o),
    	.cpu_addr_i(mem_addr_o),
    	.cpu_we_i(mem_we_o),
    	.cpu_sel_i(mem_sel_o),
    	.cpu_data_o(mem_data_i),
						
    	.wishbone_data_i(dwishbone_data_i),
    	.wishbone_ack_i(dwishbone_ack_i),
    	.wishbone_addr_o(dwishbone_addr_o),
    	.wishbone_data_o(dwishbone_data_o),
    	.wishbone_we_o(dwishbone_we_o),
    	.wishbone_sel_o(dwishbone_sel_o),
    	.wishbone_stb_o(dwishbone_stb_o),
    	.wishbone_cyc_o(dwishbone_cyc_o),
						
    	.stallreq(stop_from_mem)       
	);
				
	MEM_WB mem_wb0(.clk(clk), .rst(rst),
						.mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),	.mem_wdata(mem_wdata_o),
						.mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
						.wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i),
						.wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i),
						.stall(stall),
						.flush(flush));
						
	HILO hilo0(.clk(clk), .rst(rst), .we(wb_whilo_i),
				  .hi_i(wb_hi_i), .lo_i(wb_lo_i), .hi_o(ex_hi_i), .lo_o(ex_lo_i));
	
	CP0 cp0 (
		.clk(clk), 
		.rst(rst), 
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
		.re(cp0_reg_read_o)
	);
	
	CTRL ctrl0 (
    .clk(clk), 
    .rst(rst), 
    .stop_from_id(stop_from_id), 
    .stop_from_ex(stop_from_ex), 
    .stop_from_mem(stop_from_mem), 
    .stop_from_pc(stop_from_pc), 
    .stop_from_if(stop_from_if), 
    .flush_i(ctrl_flush_i), 
    .stall(stall), 
    .flush_o(flush)
    );
    
    DIV div0(
        .clk(clk),
        .rst(rst),
    
        .signed_div_i(signed_div),
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
    
        .result_o(div_result),
        .ready_o(div_ready)
    );
	
endmodule
