import rv32i_types::*;

module cpu(
    input clk,
    input rst,
    input logic [31:0] inst_rdata,
	input logic [31:0] data_rdata,
    input logic inst_resp,
    input logic data_resp,
	 input logic icache_hit,
	 input logic dcache_hit,

    output logic inst_read,
    output logic [31:0] inst_addr,
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata
);



    //Signals for IF
    rv32i_word pc_out;
    pcmux::pcmux_sel_t pcmux_sel;
	 rv32i_word pc_imm;

    //Signals for IF_ID
    rv32i_word pc_out_IFID, inst_out_IFID;

    //Signals for ID
    rv32i_control_word ID_ctrl_out;
    rv32i_word rs1_out, rs2_out, ID_inst_out;
	 logic [4:0] ID_rd_in, ID_rd_out;
	 logic is_branch;

    //Signals for ID_EX
    rv32i_word inst_out_IDEX, pc_out_IDEX, rs1_out_IDEX, rs2_out_IDEX; 
    rv32i_control_word IDEX_ctrl_out;
	 logic [4:0] rs1_hazard_out_IDEX, rd_out_IDEX;
	 logic [4:0] rs2_hazard_out_IDEX;

    //Signals for EX
    rv32i_control_word EX_ctrl_out;
    rv32i_word EX_pc_imm, alu_out;
	 rv32i_word EX_rs2_out;
    logic [4:0] rd;
    logic [31:0] EX_u_imm_out, branch_pc;
	 rv32i_word EX_alu_mod2;
    rv32i_word EX_pc_out;
	 logic true_branch;
	 logic EX_cmp;

    //Signals for EX_MEM
	 logic [4:0] rd_in;
    logic [4:0] rd_out_EXMEM;
    rv32i_control_word EXMEM_ctrl_out;
    rv32i_word alu_out_EXMEM;
    rv32i_word rs2_out_EXMEM;
    rv32i_word u_imm_out_EXMEM;
    rv32i_word EXMEM_pc_in, EXMEM_pc_out;
	 logic EX_MEM_cmp;

    //Signals for MEM
    logic [31:0] MEM_data_read;
    rv32i_word MEM_alu_out;
    rv32i_control_word MEM_ctrl_out;
	 logic [4:0] MEM_rd_in, MEM_rd_out;
    rv32i_word MEM_pc_in, MEM_pc_out, MEM_u_imm_out;
	 logic MEM_cmp;

    //Signals for MEM_WB
    rv32i_word read_data_out_MEMWB;
    rv32i_word u_imm_out_MEMWB;
    logic [4:0] rd_out_MEMWB;
    rv32i_word alu_out_MEMWB;
    rv32i_control_word MEMWB_ctrl_out;
    rv32i_word MEMWB_pc_in, MEMWB_pc_out;
	 logic MEM_WB_cmp;

    //Signals for WB
    rv32i_word WB_regfilemux_out;
	 rv32i_word regfile_in;
	 rv32i_control_word WB_ctrl_out;
	 logic [4:0] WB_rd_out;
    rv32i_word WB_pc_in;
    
    //Signals for Fwd Unit
    logic [1:0] forward1;
    logic [1:0] forward2;
	 //assign forward1 = 2'b00;
	 //assign forward2 = 2'b00;
	 
	 //Signals for Hazard detection
	 logic [4:0] rs1_hazard;
	 logic [4:0] rs2_hazard;
	 logic hazard_stall;

     //Signals for RVFI
	 RVFIMonPacket IF_packet_out;
	 RVFIMonPacket IF_ID_packet_out;
	 RVFIMonPacket ID_packet_out;
	 RVFIMonPacket ID_EX_packet_out;
	 RVFIMonPacket EX_packet_out;
	 RVFIMonPacket EX_MEM_packet_out;
	 RVFIMonPacket MEM_packet_out;
	 RVFIMonPacket MEM_WB_packet_out;
	 RVFIMonPacket WB_packet_out;
	 rv32i_word IF_pcmux_out;
	 rv32i_word IF_ID_pcmux_out;
	 rv32i_word ID_pcmux_out;
	 rv32i_word ID_EX_pcmux_out;
	 rv32i_word EX_pcmux_out;
	 
	 logic stall;
	 assign stall = (inst_read && !inst_resp) || (data_read && !data_resp) || (data_write && !data_resp);

    IF IF(
        .clk,
        .rst,
        .pcmux_sel,
		  .is_branch,
		  .true_branch,
        .pc_imm(branch_pc),
		  .pc_alu_mod2(EX_alu_mod2),
        .pc_load(!stall && !hazard_stall),
		  .inst_read,
		  .inst_addr,
        .pc_out,
		  .IF_packet_out,
		  .IF_pcmux_out
    );

    IF_ID IF_ID(
        .clk,
        .rst,
        .pc_out,
		  .true_branch(true_branch && !stall),
        .inst_rdata,
        .pc_out_IFID,
        .inst_out_IFID,
		  .stall(!stall && !hazard_stall),
		  .IF_ID_packet_in(IF_packet_out),
		  .IF_ID_packet_out,
		  .IF_ID_pcmux_in(IF_pcmux_out),
		  .IF_ID_pcmux_out
    );

    ID ID(
        .clk,
        .rst,
        .inst(inst_out_IFID),
        .regfile_in(WB_regfilemux_out),
        .regfile_load(WB_ctrl_out.regfile_load),
        .ID_rd_in(rd_out_MEMWB),
		  .hazard_stall,
        .ID_ctrl_out,
        .rs1_out, 
        .rs2_out,
		  .rs1_hazard,
		  .rs2_hazard,
        .ID_inst_out,
		  .is_branch,
		  .true_branch,
		  .ID_rd_out,
		  .ID_packet_in(IF_ID_packet_out),
		  .ID_packet_out,
		  .ID_pcmux_in(IF_ID_pcmux_out),
		  .ID_pcmux_out
    );
    

    ID_EX ID_EX(
        .clk,
        .rst,
        .pc_out_IFID,
        .ID_ctrl_out,
        .inst_out_IFID(ID_inst_out),
		  .ID_rd_out,
		  .rs1_hazard, 
		  .rs2_hazard,
        .rs1_out,
        .rs2_out,
        .pc_out_IDEX,
        .IDEX_ctrl_out,
        .inst_out_IDEX,
		  .rs1_out_IDEX,
		  .rs2_out_IDEX,
		  .rs1_hazard_out_IDEX,
		  .rs2_hazard_out_IDEX,
		  .stall(!stall),
		  .hazard_stall,
		  .true_branch(true_branch && !stall),
		  .rd_out_IDEX,
		  .ID_EX_packet_in(ID_packet_out),
		  .ID_EX_packet_out,
		  .ID_EX_pcmux_in(ID_pcmux_out),
		  .ID_EX_pcmux_out
    );

    EX EX(
        .clk,
        .rst,
        .inst(inst_out_IDEX),
        .rs1_in(rs1_out_IDEX),
        .rs2_in(rs2_out_IDEX),
        .EX_ctrl_in(IDEX_ctrl_out),
        .pc_in(pc_out_IDEX),
		  .rd_out_IDEX,
        .forward1,
        .forward2,
        .WB_regfile_in(WB_regfilemux_out),
        .alu_out_EXMEM,
        .EX_rs2_out,
        .alu_out,
        .EX_ctrl_out,
        .rd,
        .EX_u_imm_out,
	     .EX_alu_mod2,
		  .hazard_stall,
		  .pcmux_sel,
        .EX_pc_out,
		  .branch_pc,
		  .true_branch,
		  .EX_packet_in(ID_EX_packet_out),
		  .EX_packet_out,
		  .EX_pcmux_in(ID_EX_pcmux_out),
		  .EX_pcmux_out,
		  .EX_cmp
    );


    EX_MEM EX_MEM(
        .clk,
        .rst,
        .rs2_out_IDEX(EX_rs2_out),
        .alu_out,
        .IDEX_ctrl_out(EX_ctrl_out),
		  .EX_cmp,
		  .EX_u_imm_in(EX_u_imm_out),
        .rd_in(rd),
        .u_imm_out_EXMEM,
        .rd_out_EXMEM,
        .EXMEM_ctrl_out,
        .alu_out_EXMEM,
        .rs2_out_EXMEM,
        .EXMEM_pc_in(EX_pc_out),
        .EXMEM_pc_out,
		  .stall(!stall),
		  .EX_MEM_packet_in(EX_packet_out),
		  .EX_MEM_packet_out,
		  .EX_MEM_cmp
    );
 
    MEM MEM(
        .clk,
        .rst,
        .rs2_in(rs2_out_EXMEM),
        .MEM_ctrl_in(EXMEM_ctrl_out),
        .data_rdata,
		  .EX_MEM_cmp,
		  .u_imm_in(u_imm_out_EXMEM),
        .alu_out_in(alu_out_EXMEM),
		  .MEM_rd_in(rd_out_EXMEM),
        .data_wdata,
        .data_addr,
        .data_mbe,
        .data_read,
        .data_write,
        .MEM_data_read,
        .MEM_alu_out,
        .MEM_ctrl_out,
		  .MEM_rd_out,
        .MEM_pc_in(EXMEM_pc_out),
		  .MEM_u_imm_out,
		  .MEM_cmp,
        .MEM_pc_out,
		  .MEM_packet_in(EX_MEM_packet_out),
		  .MEM_packet_out
    );

    MEM_WB MEM_WB(
        .clk,
        .rst,
        .read_data(MEM_data_read),
        .u_imm_in(MEM_u_imm_out),
        .MEMWB_rd_in(MEM_rd_out),
        .alu_out_EXMEM(MEM_alu_out),
		  .MEM_cmp,
        .MEM_ctrl_out,
        .read_data_out_MEMWB,
        .u_imm_out_MEMWB,
        .rd_out_MEMWB,
        .alu_out_MEMWB,
        .MEMWB_ctrl_out,
        .MEMWB_pc_in(MEM_pc_out),
        .MEMWB_pc_out,
		  .stall(!stall),
		  .MEM_WB_packet_in(MEM_packet_out),
		  .MEM_WB_packet_out,
		  .MEM_WB_cmp
    );


    WB WB(
       .clk,
       .rst,
		 .MEM_WB_cmp,
       .WB_u_imm_in(u_imm_out_MEMWB),
		 .WB_rd_in(rd_out_MEMWB),
       .WB_ctrl_in(MEMWB_ctrl_out),
       .WB_alu_in(alu_out_MEMWB),
       .WB_mem_in(read_data_out_MEMWB), 
		 .WB_ctrl_out,
       .WB_regfilemux_out,
		 .WB_rd_out,
       .WB_pc_in(MEMWB_pc_out),
		 .WB_packet_in(MEM_WB_packet_out),
		 .WB_packet_out,
		 .pc_load(!stall),
		 .pc_wdata(EX_pcmux_out)
    );

	 
    forwarding_unit forwarding_unit(
        .rs1_in(rs1_hazard_out_IDEX),
        .rs2_in(rs2_hazard_out_IDEX),
        .EXMEM_rd(rd_out_EXMEM),
        .MEMWB_rd(rd_out_MEMWB),
		  .regwrite_exmem(EXMEM_ctrl_out.regfile_load),
		  .regwrite_memwb(MEMWB_ctrl_out.regfile_load),
        .forward1,
        .forward2
    );
	 
	 hazard_detection hazard_detection(
			.mem_read(IDEX_ctrl_out.mem_read),
			.rs1_hazard,
			.rs2_hazard,
			.rs2_out_IDEX(rd_out_IDEX),
			.hazard_stall
    );

endmodule : cpu