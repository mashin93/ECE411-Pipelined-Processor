import rv32i_types::*;

module ID(

    input clk,
    input rst,
    input rv32i_word inst,
    input rv32i_word regfile_in,
    input logic regfile_load,
    input logic [4:0] ID_rd_in,
	 input logic hazard_stall,
	 input logic true_branch,
    
    
    output rv32i_control_word ID_ctrl_out,

    output rv32i_word rs1_out, 
    output rv32i_word rs2_out,
	 output logic [4:0] rs1_hazard,
	 output logic [4:0] rs2_hazard,
	 output logic [4:0] ID_rd_out,
    output rv32i_word ID_inst_out,
	 output logic is_branch,

	 input RVFIMonPacket ID_packet_in,
	 output RVFIMonPacket ID_packet_out,
	 
	 input rv32i_word ID_pcmux_in,
	 output rv32i_word ID_pcmux_out
);

logic [31:0] inst_int;
assign ID_inst_out = inst_int;
rv32i_control_word ctrl_out;
rv32i_opcode opcode;
logic [4:0] rs1, rs2, rd_int;
logic [2:0] funct3;
logic [6:0] funct7;

//Instruction Split
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign opcode = rv32i_opcode'(inst[6:0]);
assign rd_int = inst[11:7];

//ID Control Out
//assign ID_ctrl_out = ctrl_out;

//rs1 and 2 for hazard output
assign rs1_hazard = rs1;
assign rs2_hazard = rs2;

//rvfi_monitor
	 //synthesis translate_off
	assign ID_packet_out.commit = 0;
	assign ID_packet_out.inst = inst;
	assign ID_packet_out.trap = 0;
	assign ID_packet_out.rs1_addr = rs1;
	assign ID_packet_out.rs2_addr = rs2;
	assign ID_packet_out.rs1_rdata = rs1_out;
	assign ID_packet_out.rs2_rdata = rs2_out;
	assign ID_packet_out.load_regfile = regfile_load;
	assign ID_packet_out.rd_addr = 0;
	assign ID_packet_out.rd_wdata = rd_int;
	assign ID_packet_out.pc_rdata = ID_packet_in.pc_rdata;
	assign ID_packet_out.pc_wdata = ID_pcmux_in;
	assign ID_packet_out.mem_addr = 0;
	assign ID_packet_out.mem_rmask = 0;
	assign ID_packet_out.mem_wmask = 0;
	assign ID_packet_out.mem_rdata = 0;
	assign ID_packet_out.mem_wdata = 0;
	assign ID_packet_out.errorcode = 0;
	//synthesis translate_on

	assign ID_pcmux_out = ID_pcmux_in;
	
control_rom control_rom(
    .opcode,
    .funct7,
    .funct3,
    .ctrl(ctrl_out)
);

regfile regfile(
    .clk,
    .rst,
    .load(regfile_load),
    .in(regfile_in),
    .src_a(rs1), 
    .src_b(rs2), 
    .dest(ID_rd_in),
    .reg_a(rs1_out), 
    .reg_b(rs2_out)
);

always_comb begin
	if (opcode == op_br || opcode == op_jal || opcode == op_jalr) begin
		is_branch = 1'b1;
	end
	else begin
		is_branch = 1'b0;
	end
end

logic stall_miss;
assign stall_miss = hazard_stall || true_branch;


always_comb begin 
	 unique case(stall_miss)
				1'b0: begin
					ID_ctrl_out = ctrl_out;
					ID_rd_out = rd_int;
					inst_int = inst;
				end
				1'b1: begin
					ID_ctrl_out = 32'b0;
					ID_rd_out = 5'b0;
					inst_int = 32'b0;
				end
				default: begin
					ID_ctrl_out = ctrl_out;
					ID_rd_out = rd_int;
					inst_int = inst;
				end
	 endcase
end

endmodule : ID