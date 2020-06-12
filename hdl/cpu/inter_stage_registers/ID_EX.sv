import rv32i_types::*;

module ID_EX(
    input clk,
    input rst,
    input rv32i_word pc_out_IFID,
    input rv32i_control_word ID_ctrl_out,
    input rv32i_word inst_out_IFID,
    input rv32i_word rs1_out,
    input rv32i_word rs2_out,
	 input logic [4:0] rs1_hazard,
	 input logic [4:0] rs2_hazard,
	 input logic [4:0] ID_rd_out,
	 input logic stall,
	 input logic hazard_stall,
	 input logic true_branch,
    output rv32i_word pc_out_IDEX,
    output rv32i_control_word IDEX_ctrl_out,
    output rv32i_word inst_out_IDEX,
    output rv32i_word rs1_out_IDEX,
    output rv32i_word rs2_out_IDEX,
	 output logic [4:0] rs1_hazard_out_IDEX,
	 output logic [4:0] rs2_hazard_out_IDEX,
	 output logic [4:0] rd_out_IDEX,
	 
	 input RVFIMonPacket ID_EX_packet_in,
	 output RVFIMonPacket ID_EX_packet_out,
	 
	 input rv32i_word ID_EX_pcmux_in,
	 output rv32i_word ID_EX_pcmux_out
);

register pc_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(pc_out_IFID),
    .out(pc_out_IDEX)
);

register inst_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(inst_out_IFID),
    .out(inst_out_IDEX)
);

register #(.width($bits(rv32i_control_word))) ctrl_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(ID_ctrl_out),
    .out(IDEX_ctrl_out)
);

register rs1_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(rs1_out),
    .out(rs1_out_IDEX)
);

register rs2_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(rs2_out),
    .out(rs2_out_IDEX)
);

register #(.width(5)) rs1_h(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(rs1_hazard),
    .out(rs1_hazard_out_IDEX)
);

register #(.width(5)) rs2_h(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(rs2_hazard),
    .out(rs2_hazard_out_IDEX)
);

register #(.width(5)) _rd(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(ID_rd_out),
    .out(rd_out_IDEX)
);

register #(.width($bits(RVFIMonPacket))) packet_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(ID_EX_packet_in),
    .out(ID_EX_packet_out)
);

register pcmux_out_IDEX(
    .clk,
    .rst(rst || true_branch),
    .load(stall),
    .in(ID_EX_pcmux_in),
    .out(ID_EX_pcmux_out)
);


endmodule : ID_EX