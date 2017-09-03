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
    input  wire                         cpu_rst_n,

    // 来自执行阶段的信息
    input  wire [`RegAddrBus ]          mem_wd_i,
    input  wire                         mem_wreg_i,
    input  wire [`RegBus     ]          mem_wdata_i,
    
    input  wire                         mem_whilo_i,
    input  wire [`RegBus     ]          mem_hi_i,
    input  wire [`RegBus     ]          mem_lo_i,
    
    //来自执行阶段的信息 
    input  wire [`AluOpBus   ]          mem_aluop_i,
    input  wire [`InstAddrBus]          mem_addr_i,
    input  wire [`RegBus     ]          mem_reg2_i,
    
    //来自外部数据存储器RAM的信息
    input  wire [`RegBus     ]          mem_data_i,
    input  wire                         mem_cp0_reg_we_i,
    input  wire [`RegAddrBus ]          mem_cp0_reg_write_addr_i,
    input  wire [`RegBus     ]          mem_cp0_reg_data_i,

    output wire                         ex_mem_cp0_reg_we,
    output wire [`RegAddrBus ]          ex_mem_cp0_write_addr,
    output wire [`RegBus     ]          ex_mem_cp0_data,
    
    // 访存阶段的结果
    output wire [`RegAddrBus ]          mem_wd_o,
    output wire                         mem_wreg_o,
    output wire [`RegBus     ]          mem_wdata_o,
    
    output wire                         mem_whilo_o,
    output wire [`RegBus     ]          mem_hi_o,
    output wire [`RegBus     ]          mem_lo_o,
    
    output wire [`RegBus     ]          mem_data_o,
    output wire                         mem_ce_o,
    output wire [`ByteSelect ]          mem_sel_o,
    output wire [`InstAddrBus]          mem_addr_o,
    output wire                         mem_we_o,
    
    input  wire [`EXC_CODE_WIDTH-1:0]   mem_exc_code_i,
    input  wire [`InstAddrBus]          mem_exc_epc_i,
    input  wire [`InstAddrBus]          mem_exc_badvaddr_i,
    
    output wire [`EXC_CODE_WIDTH-1:0]   exc_code_o,
    output wire [`InstAddrBus]          exc_epc_o,
    output wire [`InstAddrBus]          exc_badvaddr_o,
    
    input                               mem_in_delay_i,
    output                              in_delay_o,
    input  wire [`InstAddrBus]          mem_pc_i
    );
    
    assign in_delay_o = mem_in_delay_i;
    
    wire [`InstAddrBus] mem_unaligned_addr = mem_addr_i;
    wire [`InstAddrBus] mem_vrt_addr       = {mem_unaligned_addr[31:2], 2'b00};
    wire wordAlignedFlag = mem_unaligned_addr[1:0] == 2'b00;
    wire halfAlignedFlag = mem_unaligned_addr[0]   == 1'b0 ;

    assign mem_wd_o              = (cpu_rst_n == `RstEnable) ? 5'b0  : mem_wd_i;
    assign mem_wreg_o            = (cpu_rst_n == `RstEnable) ? 1'b0  : mem_wreg_i;
    assign mem_whilo_o           = (cpu_rst_n == `RstEnable) ? 1'b0  : mem_whilo_i;
    assign mem_hi_o              = (cpu_rst_n == `RstEnable) ? 32'b0 : mem_hi_i;
    assign mem_lo_o              = (cpu_rst_n == `RstEnable) ? 32'b0 : mem_lo_i;
    assign ex_mem_cp0_reg_we     = (cpu_rst_n == `RstEnable) ? 1'b0  : mem_cp0_reg_we_i;
    assign ex_mem_cp0_write_addr = (cpu_rst_n == `RstEnable) ? 5'b00000 : mem_cp0_reg_write_addr_i;
    assign ex_mem_cp0_data       = (cpu_rst_n == `RstEnable) ? 32'b0 : mem_cp0_reg_data_i;
    
    assign mem_wdata_o = (cpu_rst_n == `RstEnable) ? 32'b0 : 
                      ((mem_aluop_i == `LB  ) && (mem_addr_i[1:0] == 2'b00))  ? {{24{mem_data_i[7]}},   mem_data_i[7:0]  } :
                      ((mem_aluop_i == `LB  ) && (mem_addr_i[1:0] == 2'b01))  ? {{24{mem_data_i[15]}},  mem_data_i[15:8] } :
                      ((mem_aluop_i == `LB  ) && (mem_addr_i[1:0] == 2'b10))  ? {{24{mem_data_i[23]}},  mem_data_i[23:16]} :
                      ((mem_aluop_i == `LB  ) && (mem_addr_i[1:0] == 2'b11))  ? {{24{mem_data_i[31]}},  mem_data_i[31:24]} :
                      ((mem_aluop_i == `LB) ) ? `ZeroWord :

                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b00))  ? {{24{1'b0}}, mem_data_i[7:0]  } :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b01))  ? {{24{1'b0}}, mem_data_i[15:8] } :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b10))  ? {{24{1'b0}}, mem_data_i[23:16]} :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b11))  ? {{24{1'b0}}, mem_data_i[31:24]} :
                      ((mem_aluop_i == `LBU))  ? `ZeroWord :
                      
                      ((mem_aluop_i == `LH  ) && (mem_addr_i[1:0] == 2'b00))  ? {{16{mem_data_i[15]}},  mem_data_i[15:0] } :
                      ((mem_aluop_i == `LH  ) && (mem_addr_i[1:0] == 2'b10))  ? {{16{mem_data_i[31]}},  mem_data_i[31:16]} :
                      ((mem_aluop_i == `LH) ) ? `ZeroWord : 
                      
                      ((mem_aluop_i == `LHU ) && (mem_addr_i[1:0] == 2'b00))  ? {{16{1'b0}}, mem_data_i[15:0] } :
                      ((mem_aluop_i == `LHU ) && (mem_addr_i[1:0] == 2'b10))  ? {{16{1'b0}}, mem_data_i[31:16]} :
                      ((mem_aluop_i == `LHU)) ? `ZeroWord :    

                      ((mem_aluop_i == `LW  ) && (mem_addr_i[1:0] == 2'b00))  ? mem_data_i :
                      ((mem_aluop_i == `LW) ) ? `ZeroWord : mem_wdata_i; 
    
    assign mem_data_o = (cpu_rst_n == `RstEnable) ? 32'b0 : 
                      ((mem_aluop_i == `SB  ) && (mem_addr_i[1:0] == 2'b00))  ? {24'b0, mem_reg2_i[7:0]} :
                      ((mem_aluop_i == `SB  ) && (mem_addr_i[1:0] == 2'b01))  ? {16'b0, mem_reg2_i[7:0], 8'b0} :
                      ((mem_aluop_i == `SB  ) && (mem_addr_i[1:0] == 2'b10))  ? {8'b0, mem_reg2_i[7:0], 16'b0}  :
                      ((mem_aluop_i == `SB  ) && (mem_addr_i[1:0] == 2'b11))  ? {mem_reg2_i[7:0], 24'b0} :

                      ((mem_aluop_i == `SH  ) && (mem_addr_i[1:0] == 2'b00))  ? {16'b0, mem_reg2_i[15:0]} :
                      ((mem_aluop_i == `SH  ) && (mem_addr_i[1:0] == 2'b10))  ? {mem_reg2_i[15:0], 16'b0} :

                      (mem_aluop_i == `SW   ) ? mem_reg2_i : `ZeroWord;
    
    assign mem_ce_o = (cpu_rst_n == `RstEnable) ? 1'b0 : 
                      (mem_aluop_i == `LB )  ? `ChipEnable : 
                      (mem_aluop_i == `LBU)  ? `ChipEnable : 
                      (mem_aluop_i == `LH )  ? `ChipEnable : 
                      (mem_aluop_i == `LHU)  ? `ChipEnable :
                      (mem_aluop_i == `LW )  ? `ChipEnable : 
                      (mem_aluop_i == `SB )  ? `ChipEnable : 
                      (mem_aluop_i == `SH )  ? `ChipEnable : 
                      (mem_aluop_i == `SW )  ? `ChipEnable : `ChipDisable;
    
    assign mem_sel_o = (cpu_rst_n == `RstEnable) ? 4'b0 : 
                      ((mem_aluop_i == `LB ) && (mem_addr_i[1:0] == 2'b00)) ? 4'b0001 :
                      ((mem_aluop_i == `LB ) && (mem_addr_i[1:0] == 2'b01)) ? 4'b0010 :
                      ((mem_aluop_i == `LB ) && (mem_addr_i[1:0] == 2'b10)) ? 4'b0100 :
                      ((mem_aluop_i == `LB ) && (mem_addr_i[1:0] == 2'b11)) ? 4'b1000 :
                      ((mem_aluop_i == `LB)) ? 4'b0000 :

                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b00))? 4'b0001 :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b01))? 4'b0010 :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b10))? 4'b0100 :
                      ((mem_aluop_i == `LBU ) && (mem_addr_i[1:0] == 2'b11))? 4'b1000 :
                      ((mem_aluop_i == `LBU)) ? 4'b0000 :

                      ((mem_aluop_i == `LH  ) && (mem_addr_i[1:0] == 2'b00))? 4'b0011 :
                      ((mem_aluop_i == `LH  ) && (mem_addr_i[1:0] == 2'b10))? 4'b1100 :
                      ((mem_aluop_i == `LH) ) ? 4'b0000 :                                           
                      ((mem_aluop_i == `LHU ) && (mem_addr_i[1:0] == 2'b00))? 4'b0011 :
                      ((mem_aluop_i == `LHU ) && (mem_addr_i[1:0] == 2'b10))? 4'b1100 :
                      ((mem_aluop_i == `LHU)) ? 4'b0000 :                          
                      
                      ((mem_aluop_i == `LW  ) && (mem_addr_i[1:0] == 2'b00))? 4'b1111 :
                      ((mem_aluop_i == `LW) ) ? 4'b0000 :  
 
                      ((mem_aluop_i == `SB ) && (mem_addr_i[1:0] == 2'b00)) ? 4'b0001 :
                      ((mem_aluop_i == `SB ) && (mem_addr_i[1:0] == 2'b01)) ? 4'b0010 :
                      ((mem_aluop_i == `SB ) && (mem_addr_i[1:0] == 2'b10)) ? 4'b0100 :
                      ((mem_aluop_i == `SB ) && (mem_addr_i[1:0] == 2'b11)) ? 4'b1000 :
                      ((mem_aluop_i == `SB)) ? 4'b0000 :

                      ((mem_aluop_i == `SH ) && (mem_addr_i[1:0] == 2'b00)) ? 4'b0011 :
                      ((mem_aluop_i == `SH ) && (mem_addr_i[1:0] == 2'b10)) ? 4'b1100 :
                      ((mem_aluop_i == `SH)) ? 4'b0000 :  
                      
                      ((mem_aluop_i == `SW ) && (mem_addr_i[1:0] == 2'b00)) ? 4'b1111 :
                      ((mem_aluop_i == `SW)) ? 4'b0000 : 4'b1111;

    assign mem_addr_o = (cpu_rst_n == `RstEnable) ? 32'b0 : 
                      (mem_aluop_i == `LB )  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `LBU)  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `LH )  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `LHU)  ? {3'b0,mem_addr_i[28:0]} :
                      (mem_aluop_i == `LW )  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `SB )  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `SH )  ? {3'b0,mem_addr_i[28:0]} : 
                      (mem_aluop_i == `SW )  ? {3'b0,mem_addr_i[28:0]} : `ZeroWord;

    assign mem_we_o = (cpu_rst_n == `RstEnable) ? `WriteDisable : 
                      (mem_aluop_i == `LB )  ? `WriteDisable : 
                      (mem_aluop_i == `LBU)  ? `WriteDisable : 
                      (mem_aluop_i == `LH )  ? `WriteDisable : 
                      (mem_aluop_i == `LHU)  ? `WriteDisable :
                      (mem_aluop_i == `LW )  ? `WriteDisable : 
                      (mem_aluop_i == `SB )  ? `WriteEnable  : 
                      (mem_aluop_i == `SH )  ? `WriteEnable  : 
                      (mem_aluop_i == `SW )  ? `WriteEnable  : `WriteDisable;

    assign exc_code_o = (cpu_rst_n == `RstEnable) ? `EC_None : 
                      ((mem_aluop_i == `LH ) && (!halfAlignedFlag))  ? `EC_AdEL :
                      ((mem_aluop_i == `LHU) && (!halfAlignedFlag))  ? `EC_AdEL :
                      ((mem_aluop_i == `LW ) && (!wordAlignedFlag))  ? `EC_AdEL :
                      ((mem_aluop_i == `SH ) && (!halfAlignedFlag))  ? `EC_AdES :
                      ((mem_aluop_i == `SW ) && (!wordAlignedFlag))  ? `EC_AdES : mem_exc_code_i;

    assign exc_epc_o = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
                      ((mem_aluop_i == `LH ) && (!halfAlignedFlag) && (mem_in_delay_i))   ?   (mem_pc_i -4) :
                      ((mem_aluop_i == `LH ) && (!halfAlignedFlag) && (!mem_in_delay_i)) ?   mem_pc_i :

                      ((mem_aluop_i == `LHU) && (!halfAlignedFlag) && (mem_in_delay_i))   ?   (mem_pc_i -4) :
                      ((mem_aluop_i == `LHU) && (!halfAlignedFlag) && (!mem_in_delay_i)) ?   mem_pc_i :

                      ((mem_aluop_i == `LW ) && (!halfAlignedFlag) && (mem_in_delay_i))   ?   (mem_pc_i -4) :
                      ((mem_aluop_i == `LW ) && (!halfAlignedFlag) && (!mem_in_delay_i)) ?   mem_pc_i :

                      ((mem_aluop_i == `SH ) && (!halfAlignedFlag) && (mem_in_delay_i))   ?   (mem_pc_i -4) :
                      ((mem_aluop_i == `SH ) && (!halfAlignedFlag) && (!mem_in_delay_i)) ?   mem_pc_i :

                      ((mem_aluop_i == `SW ) && (!halfAlignedFlag) && (mem_in_delay_i))   ?   (mem_pc_i -4) :
                      ((mem_aluop_i == `SW ) && (!halfAlignedFlag) && (!mem_in_delay_i)) ?   mem_pc_i : mem_exc_epc_i;

    assign exc_badvaddr_o = (cpu_rst_n == `RstEnable) ? `ZeroWord : 
                      ((mem_aluop_i == `LH ) && (!halfAlignedFlag))  ? mem_addr_i :
                      ((mem_aluop_i == `LHU) && (!halfAlignedFlag))  ? mem_addr_i :
                      ((mem_aluop_i == `LW ) && (!wordAlignedFlag))  ? mem_addr_i :
                      ((mem_aluop_i == `SH ) && (!halfAlignedFlag))  ? mem_addr_i :
                      ((mem_aluop_i == `SW ) && (!wordAlignedFlag))  ? mem_addr_i : mem_exc_badvaddr_i;
    

endmodule