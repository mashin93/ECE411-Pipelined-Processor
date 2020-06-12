import rv32i_types::*;

module MEM(
    input clk,
    input rst,
    input rv32i_word rs2_in,
    input rv32i_control_word MEM_ctrl_in,
    input logic [31:0] data_rdata,
    input rv32i_word alu_out_in,
	 input logic [4:0] MEM_rd_in,
    input rv32i_word MEM_pc_in,
	 input rv32i_word u_imm_in,
	 input logic EX_MEM_cmp,
    output logic [31:0] data_wdata,
    output logic [31:0] data_addr,
    output logic [3:0] data_mbe,
    output logic data_read,
    output logic data_write,
    output logic [31:0] MEM_data_read,
    output rv32i_word MEM_alu_out,
    output rv32i_control_word MEM_ctrl_out,
	 output logic [4:0] MEM_rd_out,
    output rv32i_word MEM_pc_out,
	 output rv32i_word MEM_u_imm_out,
	 output logic MEM_cmp,
    input RVFIMonPacket MEM_packet_in,
	 output RVFIMonPacket MEM_packet_out
);


    assign data_mbe = MEM_ctrl_in.mem_byte_enable << alu_out_in[1:0];
    assign data_read = MEM_ctrl_in.mem_read;
    assign data_write = MEM_ctrl_in.mem_write;
    assign data_addr = {alu_out_in[31:2], 2'b00};
    assign MEM_data_read = data_rdata >> (8 * alu_out_in[1:0]);
	 assign data_wdata = rs2_in << (8 * alu_out_in[1:0]);
    assign MEM_alu_out = alu_out_in;
    assign MEM_ctrl_out = MEM_ctrl_in;
	 assign MEM_rd_out = MEM_rd_in;
    assign MEM_pc_out = MEM_pc_in;
	 assign MEM_u_imm_out = u_imm_in;
	 assign MEM_cmp = EX_MEM_cmp;

	 //rvfi_monitor
 	 //synthesis translate_off
	 assign MEM_packet_out.commit = 0;
	 assign MEM_packet_out.inst = MEM_packet_in.inst;
	 assign MEM_packet_out.trap = MEM_packet_in.trap;
	 assign MEM_packet_out.rs1_addr = MEM_packet_in.rs1_addr;
	 assign MEM_packet_out.rs2_addr = MEM_packet_in.rs2_addr;
	 assign MEM_packet_out.rs1_rdata = MEM_packet_in.rs1_rdata ;
	 assign MEM_packet_out.rs2_rdata = MEM_packet_in.rs2_rdata;
	 assign MEM_packet_out.load_regfile = MEM_packet_in.load_regfile;
	 assign MEM_packet_out.rd_addr = 0;
	 assign MEM_packet_out.rd_wdata = MEM_packet_in.rd_wdata;
	 assign MEM_packet_out.pc_rdata = MEM_packet_in.pc_rdata;
	 assign MEM_packet_out.pc_wdata = MEM_packet_in.pc_wdata;
	 assign MEM_packet_out.mem_addr = data_addr;
	 assign MEM_packet_out.mem_rmask = (data_read) ? data_mbe : 0;
	 assign MEM_packet_out.mem_wmask = (data_write) ? data_mbe : 0;
	 assign MEM_packet_out.mem_rdata = data_rdata;
	 assign MEM_packet_out.mem_wdata = data_wdata;
	 assign MEM_packet_out.errorcode = 0;
	 //synthesis translate_on


endmodule : MEM