module forwarding_unit
(
    input logic [4:0] rs1_in,
    input logic [4:0] rs2_in,
    input logic [4:0] EXMEM_rd,
    input logic [4:0] MEMWB_rd,
	 input logic regwrite_exmem,
	 input logic regwrite_memwb,
    output logic [1:0] forward1,
    output logic [1:0] forward2
);

always_comb
begin
    if((regwrite_exmem) && (rs1_in == EXMEM_rd) && (EXMEM_rd != 0)) forward1 = 2'b10;
    else if((regwrite_memwb) && (MEMWB_rd != 0) && !((regwrite_exmem) && (EXMEM_rd != 0) && (EXMEM_rd == rs1_in)) && (rs1_in == MEMWB_rd)) forward1 = 2'b01;
    else forward1 = 2'b00;
    
    if((regwrite_exmem) && (rs2_in == EXMEM_rd) && (EXMEM_rd != 0)) forward2 = 2'b10;
    else if((regwrite_memwb) && (MEMWB_rd != 0) && !((regwrite_exmem) && (EXMEM_rd != 0) && (EXMEM_rd == rs2_in)) && (rs2_in == MEMWB_rd)) forward2 = 2'b01;
    else forward2 = 2'b00;
end

endmodule : forwarding_unit