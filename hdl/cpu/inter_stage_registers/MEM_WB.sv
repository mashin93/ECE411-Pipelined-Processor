import rv32i_types::*;

module MEM_WB(
    input clk,
    input rst,
    input logic [31:0] read_data,
    input rv32i_word u_imm_in,
    input logic [4:0] MEMWB_rd_in,
    input rv32i_word alu_out_EXMEM,
    input rv32i_control_word MEM_ctrl_out,
    input rv32i_word MEMWB_pc_in,
	 input logic stall,
	 input logic MEM_cmp,
    output rv32i_word read_data_out_MEMWB,
    output rv32i_word u_imm_out_MEMWB,
    output logic [4:0] rd_out_MEMWB,
    output rv32i_word alu_out_MEMWB,
    output rv32i_control_word MEMWB_ctrl_out,
    output rv32i_word MEMWB_pc_out,
	 output logic MEM_WB_cmp,
	 input RVFIMonPacket MEM_WB_packet_in,
	 output RVFIMonPacket MEM_WB_packet_out
);

register alu_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(alu_out_EXMEM),
    .out(alu_out_MEMWB)
);

register u_imm_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(u_imm_in),
    .out(u_imm_out_MEMWB)
);

register rdata_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(read_data),
    .out(read_data_out_MEMWB)
);

register #(.width(5)) rd_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(MEMWB_rd_in),
    .out(rd_out_MEMWB)
);

register #(.width(1)) cmp_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(MEM_cmp),
    .out(MEM_WB_cmp)
);

register #(.width($bits(rv32i_control_word))) ctrl_EXMEM(
    .clk,
    .rst,
    .load(stall),
    .in(MEM_ctrl_out),
    .out(MEMWB_ctrl_out)
);

register pc_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(MEMWB_pc_in),
    .out(MEMWB_pc_out)
);

register #(.width($bits(RVFIMonPacket))) packet_MEMWB(
    .clk,
    .rst,
    .load(stall),
    .in(MEM_WB_packet_in),
    .out(MEM_WB_packet_out)
);


endmodule : MEM_WB