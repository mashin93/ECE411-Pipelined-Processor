import rv32i_types::*;

module IF(
    input clk,
    input rst,
    input pcmux::pcmux_sel_t pcmux_sel,
    input rv32i_word pc_imm,
	input rv32i_word pc_alu_mod2,
    input logic pc_load,
	 input logic is_branch,
	 input logic true_branch,
    output rv32i_word pc_out,
	output logic [31:0] inst_addr,
	output logic inst_read,

	output RVFIMonPacket IF_packet_out,
	output rv32i_word IF_pcmux_out
);

rv32i_word pcmux_out;
pcmux::pcmux_sel_t pc_mux;

always_comb begin
	if(is_branch == 1'b1 && !true_branch) begin
		pc_mux = pcmux::pc_plus4;
	end
	else if (true_branch) begin
		pc_mux = pcmux_sel;
	end
	else begin
		pc_mux = pcmux::pc_plus4;
	end
end


assign inst_read = 1'b1;
assign inst_addr = pc_out;
assign IF_pcmux_out = pcmux_out;

	RVFIMonPacket packet;

	//rvfi_monitor
	 //synthesis translate_off
	assign packet.commit = 0;
	assign packet.inst = 0;
	assign packet.trap = 0;
	assign packet.rs1_addr = 0;
	assign packet.rs2_addr = 0;
	assign packet.rs1_rdata = 0;
	assign packet.rs2_rdata = 0;
	assign packet.load_regfile = 0;
	assign packet.rd_addr = 0;
	assign packet.rd_wdata = 0;
	assign packet.pc_rdata = pc_out;
	assign packet.pc_wdata = pcmux_out;
	assign packet.mem_addr = 0;
	assign packet.mem_rmask = 0;
	assign packet.mem_wmask = 0;
	assign packet.mem_rdata = 0;
	assign packet.mem_wdata = 0;
	assign packet.errorcode = 0;
	//synthesis translate_on
	assign IF_packet_out = packet;

pc_register pc(
    .clk,
    .rst,
    .load(pc_load),  
    .in(pcmux_out),
    .out(pc_out)
);

always_comb begin : MUXES
    unique case (pc_mux)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out : pcmux_out = pc_imm;
		  pcmux::alu_mod2 : pcmux_out = pc_alu_mod2;
		  default: pcmux_out = pc_out + 4;
	 endcase
end



endmodule : IF