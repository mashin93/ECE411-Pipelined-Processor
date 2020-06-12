module hazard_detection
(
    input logic mem_read,
    input logic [4:0] rs1_hazard,
    input logic [4:0] rs2_hazard,
    input logic [4:0] rs2_out_IDEX,
    output logic hazard_stall
);

always_comb
begin
    if(mem_read == 1'b1 && ((rs1_hazard == rs2_out_IDEX) || (rs2_hazard == rs2_out_IDEX))) hazard_stall = 1;
    else hazard_stall = 0;
end

endmodule : hazard_detection