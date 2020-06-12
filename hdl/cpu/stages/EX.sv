import rv32i_types::*;

module EX(
    input clk,
    input rst,
    input rv32i_word inst,
    input rv32i_word rs1_in,
    input rv32i_word rs2_in,
    input rv32i_control_word EX_ctrl_in,
    input rv32i_word pc_in,
	 input logic hazard_stall,
    input logic [1:0] forward1,
    input logic [1:0] forward2,
    input rv32i_word WB_regfile_in,
    input rv32i_word alu_out_EXMEM,
	 input logic [4:0] rd_out_IDEX,
    output rv32i_word EX_rs2_out,
    output rv32i_word alu_out,
    output rv32i_control_word EX_ctrl_out,
    output logic [4:0] rd,
    output [31:0] EX_u_imm_out,
	 output rv32i_word EX_alu_mod2,
	 output pcmux::pcmux_sel_t pcmux_sel,
    output rv32i_word EX_pc_out,
	 output logic [31:0] branch_pc,
	 output logic true_branch,
	 input RVFIMonPacket EX_packet_in,
	 output RVFIMonPacket EX_packet_out,
	 input rv32i_word EX_pcmux_in,
	 output rv32i_word EX_pcmux_out,
	 output logic EX_cmp
);


logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;
logic [4:0] rd_temp;
rv32i_word alu_mux1_out;
rv32i_word alu_mux2_out, alu_mod2;
rv32i_word EX_rs1_in, EX_rs2_in;
rv32i_word fwdmux1_out;
rv32i_word fwdmux2_out;

logic cmp_out;
assign EX_cmp = cmp_out;

assign EX_rs1_in = rs1_in;
assign EX_rs2_in = rs2_in;
assign EX_rs2_out = fwdmux2_out;

logic true_branch_int;
assign true_branch = true_branch_int;

logic [31:0] branch_pc_int, alu_out_int;
assign branch_pc = branch_pc_int;

pcmux::pcmux_sel_t pcmux_sel_int;
assign pcmux_sel = pcmux_sel_int;

assign EX_pcmux_out = EX_pcmux_in;

//Imm Gen
assign i_imm = {{21{inst[31]}}, inst[30:20]};
assign s_imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign b_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign u_imm = {inst[31:12], 12'h000};
assign j_imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
assign rd = rd_out_IDEX;
assign EX_ctrl_out = EX_ctrl_in;

assign EX_u_imm_out = u_imm;
assign EX_pc_out = pc_in;

//rvfi_monitor
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;
rv32i_opcode opcode;
logic [2:0] funct3;
assign funct3 = inst[14:12];
assign opcode = rv32i_opcode'(inst[6:0]);
assign alu_out = ((arith_funct3_t'(funct3) == slt || arith_funct3_t'(funct3) == sltu) && (EX_ctrl_in.opcode == op_reg || EX_ctrl_in.opcode == op_imm)) ? cmp_out : alu_out_int;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;

assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);


always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011;
                lb, lbu: rmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011;
                sb: wmask = 4'b0001;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end

	//synthesis translate_off
	assign EX_packet_out.commit = 0;
	assign EX_packet_out.inst = inst;
	assign EX_packet_out.trap = trap;
	assign EX_packet_out.rs1_addr = EX_packet_in.rs1_addr;
	assign EX_packet_out.rs2_addr = EX_packet_in.rs2_addr;
	assign EX_packet_out.rs1_rdata = fwdmux1_out;
	assign EX_packet_out.rs2_rdata = fwdmux2_out;
	assign EX_packet_out.load_regfile = EX_packet_in.load_regfile;
	assign EX_packet_out.rd_addr = 0;
	assign EX_packet_out.rd_wdata = EX_packet_in.rd_wdata;
	assign EX_packet_out.pc_rdata = EX_packet_in.pc_rdata;
	assign EX_packet_out.pc_wdata = (true_branch) ? branch_pc : (EX_packet_out.pc_rdata + 4);
	assign EX_packet_out.mem_addr = 0;
	assign EX_packet_out.mem_rmask = rmask;
	assign EX_packet_out.mem_wmask = 0;
	assign EX_packet_out.mem_rdata = 0;
	assign EX_packet_out.mem_wdata = 0;
	assign EX_packet_out.errorcode = 0;
	//synthesis translate_on


cmp cmp(
    .input1(fwdmux1_out),
	 .input2((EX_ctrl_in.cmpmux_sel == cmpmux::i_imm) ? i_imm : fwdmux2_out),
	 .cmpop(EX_ctrl_in.cmpop),
	 .br_en(cmp_out)
);

alu alu(
    .aluop(EX_ctrl_in.aluop),
    .a(alu_mux1_out), 
    .b(alu_mux2_out),
    .f(alu_out_int)
);

assign alu_mod2 = {alu_out[31:1], 1'b0};
assign EX_alu_mod2 = alu_mod2;

always_comb begin: Muxes
	 unique case (forward1) //forwarding mux1
        2'b00 : fwdmux1_out = EX_rs1_in;
        2'b01 : fwdmux1_out = WB_regfile_in;
        2'b10 : fwdmux1_out = alu_out_EXMEM;
		  default : fwdmux1_out = EX_rs1_in;
    endcase
	 
    unique case (forward2) //forwarding mux1
		  2'b00: fwdmux2_out = EX_rs2_in;
		  2'b01: fwdmux2_out = WB_regfile_in;
		  2'b10: fwdmux2_out = alu_out_EXMEM;
		  default : fwdmux2_out = EX_rs2_in;
    endcase
	 
    unique case (EX_ctrl_in.alumux1_sel) // alumux1
        alumux::rs1_out: begin
				if (EX_ctrl_in.opcode == op_lui) begin
					alu_mux1_out = 32'b0;
				end
				else begin
					alu_mux1_out = fwdmux1_out;
				end
			end
        alumux::pc_out : alu_mux1_out = pc_in;
		  default: alu_mux1_out = fwdmux1_out;
    endcase

    unique case (EX_ctrl_in.alumux2_sel) // alumux2
        alumux::i_imm : alu_mux2_out = i_imm;
        alumux::u_imm : alu_mux2_out = u_imm;
        alumux::b_imm : alu_mux2_out = b_imm;
        alumux::s_imm : alu_mux2_out = s_imm;
        alumux::j_imm : alu_mux2_out = j_imm;
        alumux::rs2_out : alu_mux2_out = fwdmux2_out;
		  default: alu_mux2_out = fwdmux2_out;
    endcase
	 
	 unique case(EX_ctrl_in.opcode)
		op_jal: begin
			branch_pc_int = EX_pc_out + j_imm;
			pcmux_sel_int = EX_ctrl_in.pcmux_sel;
			true_branch_int = 1'b1;
		end
		
		op_jalr: begin
			branch_pc_int = (fwdmux1_out + i_imm) & 32'hFFFFFFFE;
			pcmux_sel_int = EX_ctrl_in.pcmux_sel;
			true_branch_int = 1'b1;
		end
		
		op_br: begin 
			branch_pc_int = EX_pc_out + b_imm;
			pcmux_sel_int = pcmux::pcmux_sel_t'(EX_ctrl_in.pcmux_sel && {1'b0, cmp_out});
			true_branch_int = cmp_out;
		end
		
		default: begin
			branch_pc_int = 32'b0;
			true_branch_int = 1'b0;
			pcmux_sel_int = EX_ctrl_in.pcmux_sel;
		end
	endcase
end
    

endmodule : EX