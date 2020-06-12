import rv32i_types::*;

module cmp
(
    input rv32i_word input1,
	 input rv32i_word input2,
	 input branch_funct3_t cmpop,
	 output logic br_en
);

always_comb
begin	
    unique case (cmpop)
	     beq: begin
				if (input1 == input2) br_en = 1'b1;
				else br_en = 1'b0;
		  end
		  bne: begin 
				if (input1 != input2) br_en = 1'b1;
				else br_en = 1'b0;
		  end
		  blt: begin 
				if ($signed(input1) < $signed(input2)) br_en = 1'b1;
				else br_en = 1'b0;
		  end
		  bge: begin 
				if ($signed(input1) >= $signed(input2)) br_en = 1'b1;
				else br_en = 1'b0;
		  end
		  bltu: begin 
				if (input1 < input2) br_en = 1'b1;
				else br_en = 1'b0;
		  end	
		  bgeu: begin 
				if (input1 >= input2) br_en = 1'b1;
				else br_en = 1'b0;
		  end	
		  default: br_en = 1'b0;
	 endcase
end

endmodule : cmp 
