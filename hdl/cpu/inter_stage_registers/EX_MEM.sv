import rv32i_types::*;

module EX_MEM(
    input clk,
    input rst,
    input rv32i_word rs2_out_IDEX,
    input rv32i_word alu_out,
	 input logic EX_cmp,
    input rv32i_word IDEX_ctrl_out,
    input logic [4:0] rd_in,
    input rv32i_word EX_u_imm_in,
    input rv32i_word EXMEM_pc_in,
	 input logic stall,
    output logic [4:0] rd_out_EXMEM,
    output rv32i_control_word EXMEM_ctrl_out,
    output rv32i_word alu_out_EXMEM,
    output rv32i_word rs2_out_EXMEM,
    output rv32i_word u_imm_out_EXMEM,
    output rv32i_word EXMEM_pc_out,
	 output logic EX_MEM_cmp,
	 input RVFIMonPacket EX_MEM_packet_in,
	 output RVFIMonPacket EX_MEM_packet_out
);

register #(.width($bits(rv32i_control_word))) ctrl_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(IDEX_ctrl_out),
    .out(EXMEM_ctrl_out)
);

register alu_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(alu_out),
    .out(alu_out_EXMEM)
);

register rs2_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(rs2_out_IDEX),
    .out(rs2_out_EXMEM)
);

register #(.width(5)) rd_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(rd_in),
    .out(rd_out_EXMEM)
);

register #(.width(1)) cmp_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(EX_cmp),
    .out(EX_MEM_cmp)
);

register u_imm_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(EX_u_imm_in),
    .out(u_imm_out_EXMEM)
);

register pc_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(EXMEM_pc_in),
    .out(EXMEM_pc_out)
);

register #(.width($bits(RVFIMonPacket))) packet_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(EX_MEM_packet_in),
    .out(EX_MEM_packet_out)
);

endmodule : EX_MEM