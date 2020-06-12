import rv32i_types::*;

module WB(
    input clk,
    input rst,
    input logic [31:0] WB_u_imm_in,
    input rv32i_control_word WB_ctrl_in,
    input rv32i_word WB_alu_in,
	 input logic [4:0] WB_rd_in,
    input rv32i_word WB_mem_in,
    input rv32i_word WB_pc_in,
	 input logic MEM_WB_cmp,
    output rv32i_word WB_regfilemux_out,
	 output rv32i_control_word WB_ctrl_out,
	 output logic [4:0] WB_rd_out,
    input RVFIMonPacket WB_packet_in,
	 output RVFIMonPacket WB_packet_out,
	 input logic pc_load,
	 input rv32i_word pc_wdata
);

rv32i_word regfilemux_out, alu_in, u_imm_in, mem_in, pc_in;
logic WB_cmp;

assign WB_regfilemux_out = regfilemux_out;
assign u_imm_in = WB_u_imm_in;
assign mem_in = WB_mem_in;
assign WB_ctrl_out = WB_ctrl_in;
assign WB_rd_out = WB_rd_in;
assign pc_in = WB_pc_in;
assign WB_cmp = MEM_WB_cmp;

//rvfi_monitor
	 //synthesis translate_off
	 assign WB_packet_out.commit = pc_load && WB_packet_in.inst != 0;
	 assign WB_packet_out.inst = WB_packet_in.inst;
	 assign WB_packet_out.trap = WB_packet_in.trap;
	 assign WB_packet_out.rs1_addr = WB_packet_in.rs1_addr;
	 assign WB_packet_out.rs2_addr = WB_packet_in.rs2_addr;
	 assign WB_packet_out.rs1_rdata = WB_packet_in.rs1_rdata ;
	 assign WB_packet_out.rs2_rdata = WB_packet_in.rs2_rdata;
	 assign WB_packet_out.load_regfile = WB_ctrl_in.regfile_load;
	 assign WB_packet_out.rd_addr = WB_rd_in;
	 assign WB_packet_out.rd_wdata = (WB_rd_in != 0) ? regfilemux_out : 0;
	 assign WB_packet_out.pc_rdata = WB_packet_in.pc_rdata;
	 assign WB_packet_out.pc_wdata = WB_packet_in.pc_wdata;
	 assign WB_packet_out.mem_addr = WB_packet_in.mem_addr;
	 assign WB_packet_out.mem_rmask = WB_packet_in.mem_rmask;
	 assign WB_packet_out.mem_wmask = WB_packet_in.mem_wmask;
	 assign WB_packet_out.mem_rdata = WB_packet_in.mem_rdata;
	 assign WB_packet_out.mem_wdata = WB_packet_in.mem_wdata;
	 assign WB_packet_out.errorcode = 0;
	 //synthesis translate_on

always_comb begin: Muxes
    unique case (WB_ctrl_in.regfilemux_sel)
        regfilemux::alu_out     : regfilemux_out = WB_alu_in;
        regfilemux::br_en       : regfilemux_out = {30'd0, WB_cmp};
        regfilemux::u_imm       : regfilemux_out = u_imm_in;
        regfilemux::lw          : regfilemux_out = mem_in;
        regfilemux::lh          : regfilemux_out = {{17{mem_in[15]}},mem_in[14:0]};
        regfilemux::lhu         : regfilemux_out = {16'd0, mem_in[15:0]};
        regfilemux::lb          : regfilemux_out = {{25{mem_in[7]}}, mem_in[6:0]};
        regfilemux::lbu         : regfilemux_out = {24'd0, mem_in[7:0]};
        regfilemux::pc_plus4    : regfilemux_out = pc_in + 4;
		default: regfilemux_out = WB_alu_in;
    endcase
end

endmodule : WB