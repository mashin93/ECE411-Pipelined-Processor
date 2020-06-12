import rv32i_types::*;

module control_rom(
    input rv32i_opcode opcode,
    input logic [6:0] funct7,
    input logic [2:0] funct3,

    output rv32i_control_word ctrl
);


always_comb
begin
    /* Default assignments */
    ctrl.opcode = opcode;
    ctrl.aluop = alu_add;
    ctrl.pcmux_sel = pcmux::pc_plus4;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.cmpop = branch_funct3_t'(3'b000);
    ctrl.mem_read = 1'b0;
    ctrl.mem_write = 1'b0;
    ctrl.regfile_load = 1'b0;
    ctrl.mem_resp = 1'b0;
    ctrl.mem_byte_enable = 4'b1111;


    /* Assign control signals based on opcode */
    case(opcode)
        op_lui: begin
				ctrl.aluop = alu_add;
            ctrl.regfilemux_sel = regfilemux::u_imm;
				ctrl.alumux1_sel = alumux::rs1_out;
				ctrl.alumux2_sel = alumux::u_imm;
            ctrl.regfile_load = 1'b1;
        end
        
        op_auipc: begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::u_imm;
            ctrl.aluop = alu_add;
            ctrl.regfile_load = 1'b1;
        end

        op_br: begin
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::b_imm;
            //ctrl.aluop = alu_add;
            ctrl.pcmux_sel = pcmux::alu_out;
            ctrl.cmpop = branch_funct3_t'(funct3);
        end

        op_load: begin
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.aluop = alu_add;
            ctrl.mem_write = 1'b0;
            ctrl.mem_read = 1'b1;
            ctrl.regfile_load = 1'b1;
            case (load_funct3_t'(funct3))
                lb: ctrl.regfilemux_sel = regfilemux::lb;
                lh: ctrl.regfilemux_sel = regfilemux::lh;
                lbu: ctrl.regfilemux_sel = regfilemux::lbu;
                lhu: ctrl.regfilemux_sel = regfilemux::lhu;
                lw: ctrl.regfilemux_sel = regfilemux::lw;
					 default: ctrl.regfilemux_sel = regfilemux::lw;
            endcase
        end

        op_store: begin
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::s_imm;
            ctrl.aluop = alu_add;
            ctrl.mem_write = 1'b1;
            ctrl.mem_read = 1'b0;
            case (store_funct3_t'(funct3))
                sb: ctrl.mem_byte_enable = 4'b0001;
                sh: ctrl.mem_byte_enable = 4'b0011;
                sw: ctrl.mem_byte_enable = 4'b1111;
                default: ctrl.mem_byte_enable = 4'b1111;
            endcase
        end

        op_imm: begin
            ctrl.regfile_load = 1;
            case (arith_funct3_t'(funct3))
                slt: begin
							ctrl.cmpop = blt;
							ctrl.regfilemux_sel = regfilemux::br_en;
							ctrl.cmpmux_sel = cmpmux::i_imm;
                end

                sltu: begin
                    ctrl.cmpop = bltu;
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                end

                sr: begin
                    ctrl.alumux1_sel = alumux::rs1_out;
                    ctrl.alumux2_sel = alumux::i_imm;
                    case (funct7)
                        7'b0000000: begin //srl
                            ctrl.aluop = alu_srl;
                        end

                        7'b0100000: begin //sra 
                            ctrl.aluop = alu_sra;
                        end
								
								default: ctrl.aluop = alu_srl;
                    endcase
                end

                add, sll, axor, aor, aand: begin
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.alumux1_sel = alumux::rs1_out;
                    ctrl.alumux2_sel = alumux::i_imm;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end
            endcase
        end

        op_reg: begin
            ctrl.regfile_load = 1'b1;
            case (arith_funct3_t'(funct3))
                slt: begin
                    ctrl.cmpop = blt;
							ctrl.regfilemux_sel = regfilemux::br_en;
							ctrl.cmpmux_sel = cmpmux::rs2_out;
                end

                sltu: begin
                     ctrl.cmpop = bltu;
							ctrl.regfilemux_sel = regfilemux::br_en;
							ctrl.cmpmux_sel = cmpmux::rs2_out;
                end

                sr: begin
							case (funct7)
                        7'b0000000: begin
                            ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.aluop = alu_srl;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
                        end

                        7'b0100000: begin
                            ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.aluop = alu_sra;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
                        end
								
								default: begin
									 ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.aluop = alu_srl;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
								end
                    endcase
                end

                sll, axor, aor, aand: begin
                    ctrl.aluop = alu_ops'(funct3);
                    ctrl.alumux1_sel = alumux::rs1_out;
                    ctrl.alumux2_sel = alumux::rs2_out;
                    ctrl.regfilemux_sel = regfilemux::alu_out;
                end


                add: begin
                    case (funct7)
                        7'b0000000: begin
                            ctrl.aluop = alu_add;
                            ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
                        end

                        7'b0100000: begin
                            ctrl.aluop = alu_sub;
                            ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
                        end
								
								default: begin
									 ctrl.aluop = alu_add;
                            ctrl.alumux1_sel = alumux::rs1_out;
                            ctrl.alumux2_sel = alumux::rs2_out;
                            ctrl.regfilemux_sel = regfilemux::alu_out;
								end
                    endcase
                end
            endcase
        end
        
        op_jal: begin
            ctrl.regfile_load = 1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::j_imm;
            ctrl.pcmux_sel = pcmux::alu_out;
        end
     
        op_jalr: begin
            ctrl.regfile_load = 1;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.pcmux_sel = pcmux::alu_out;
        end
        
        default: begin
            ctrl = 0;   /* Unknown opcode, set control word to zero */
        end
    endcase
end
endmodule : control_rom
