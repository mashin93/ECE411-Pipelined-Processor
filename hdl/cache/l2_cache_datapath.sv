module l2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input rst,
	
	//Arbiter
	input logic [31:0] mem_address,
	output logic [255:0] mem_rdata,
	input logic [255:0] mem_wdata,
	
	//<--> Cacheline Adaptor/Memory
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	
	//<--> Cache Control
	input logic data_read,
	input logic m_data_read,
	input logic data_write,
	input logic datain_mux,
	input logic tag_load,
	input logic tag_read,
	input logic valid_load,
	input logic valid_read,
	input logic dirty_in,
	input logic dirty_mux,
	input logic dirty_read,
	input logic dirty_load,
	input logic lru_load,
	input logic lru_read,
	output logic hit,
	output logic dirty,
	output logic [23:0] tag_out
);

/**************************** Internal Signals ****************************/

//Data Arrays
logic [255:0] data0, data1, data2, data3, data, datain_mux_out;
logic [31:0] data_write_en0, data_write_en1, data_write_en2, data_write_en3;
logic write_en_mux0, write_en_mux1, write_en_mux2, write_en_mux3;
logic dataout_mux0, dataout_mux1, dataout_mux2, dataout_mux3;

//Tag Arrays
logic [23:0] tag0, tag1, tag2, tag3;
logic tag_load0, tag_load1, tag_load2, tag_load3;

//Valid Arrays
logic valid0, valid1, valid2, valid3, valid_load0, valid_load1, valid_load2, valid_load3;

//Dirty Arrays
logic dirty0, dirty1, dirty2, dirty3, dirty_mux_out0, dirty_mux_out1, dirty_mux_out2, dirty_mux_out3;
logic dirty_load0, dirty_load1, dirty_load2, dirty_load3;

//pLRU
logic [2:0] plru_in, plru_out, plru_temp_in, plru_temp_out;
logic lru_load_internal, lru0, lru1, lru2, lru3, lru0_temp, lru1_temp, lru2_temp, lru3_temp;

//Hit
logic hit0, hit1, hit2, hit3;

//Address Splitting
logic [23:0] tag_address;
logic [2:0] index;

/*********************** Various Assignments *****************************/

//Address Splitting
assign tag_address = mem_address[31:8];
assign index = mem_address[7:5];

//Data
assign mem_rdata = data;
assign pmem_wdata = data;
assign write_en_mux0 = data_write && hit0 || lru0 && datain_mux;
assign write_en_mux1 = data_write && hit1 || lru1 && datain_mux;
assign write_en_mux2 = data_write && hit2 || lru2 && datain_mux;
assign write_en_mux3 = data_write && hit3 || lru3 && datain_mux;
assign dataout_mux0 = hit0 || (m_data_read && lru0); 
assign dataout_mux1 = hit1 || (m_data_read && lru1); 
assign dataout_mux2 = hit2 || (m_data_read && lru2); 
assign dataout_mux3 = hit3 || (m_data_read && lru3); 

//Tag/Hit
assign tag_load0 = tag_load && lru0;
assign tag_load1 = tag_load && lru1;
assign tag_load2 = tag_load && lru2;
assign tag_load3 = tag_load && lru3;
assign hit0 = valid0 && (tag0 == tag_address);
assign hit1 = valid1 && (tag1 == tag_address);
assign hit2 = valid2 && (tag2 == tag_address);
assign hit3 = valid3 && (tag3 == tag_address);
assign hit = hit0 || hit1 || hit2 || hit3;

//Valid
assign valid_load0 = valid_load && lru0;
assign valid_load1 = valid_load && lru1;
assign valid_load2 = valid_load && lru2;
assign valid_load3 = valid_load && lru3;

//Dirty
assign dirty_load0 = dirty_load && dirty_mux_out0;
assign dirty_load1 = dirty_load && dirty_mux_out1;
assign dirty_load2 = dirty_load && dirty_mux_out2;
assign dirty_load3 = dirty_load && dirty_mux_out3;

//LRU
assign lru_load_internal = lru_load || hit;
assign plru_temp_out = plru_out;
assign plru_in = plru_temp_in;
assign lru0 = lru0_temp;
assign lru1 = lru1_temp;
assign lru2 = lru2_temp;
assign lru3 = lru3_temp;

/********************************** Arrays *************************************/

//Four Data Arrays
data_array line [4](
		.clk (clk),
		.rst (rst),
		.read (data_read || m_data_read),
		.write_en ({data_write_en0, data_write_en1, data_write_en2, data_write_en3}),
		.rindex (index),
		.windex (index),
		.datain (datain_mux_out),
		.dataout ({data0, data1, data2, data3})
);

//Four Tag Arrays
array #(.width(24)) tag [4](
		.clk (clk),
		.rst (rst),
		.read (tag_read),
		.load ({tag_load0, tag_load1, tag_load2, tag_load3}),
		.rindex (index),
		.windex (index),
		.datain (tag_address),
		.dataout ({tag0, tag1, tag2, tag3})
);

//Four Valid Arrays
array #(.width(1)) valid [4](
		.clk (clk),
		.rst (rst),
		.read (valid_read),
		.load({valid_load0, valid_load1, valid_load2, valid_load3}),
		.rindex (index),
		.windex (index),
		.datain (1'b1),
		.dataout ({valid0, valid1, valid2, valid3})
);

//Four Dirty Arrays
array #(.width(1)) dirty_array [4](
		.clk (clk),
		.rst (rst),
		.read (dirty_read),
		.load ({dirty_load0, dirty_load1, dirty_load2, dirty_load3}),
		.rindex (index),
		.windex (index),
		.datain (dirty_in),
		.dataout ({dirty0, dirty1, dirty2, dirty3})
);

//pLRU for 4 ways
array #(.width(3)) LRU(
		.clk (clk),
		.rst (rst),
		.read (1'b1),
		.load (lru_load_internal),
		.rindex (index),
		.windex (index),
		.datain (plru_in),
		.dataout (plru_out)
);

//Decision block for pLRU
always_comb begin
	//Update
	if (hit) begin
		if (hit0) begin
			plru_temp_in[0] = plru_temp_out[0];
			plru_temp_in[1] = 1'b1;
			plru_temp_in[2] = 1'b1;
		end
		else if (hit1) begin
			plru_temp_in[0] = plru_temp_out[0];
			plru_temp_in[1] = 1'b0;
			plru_temp_in[2] = 1'b1;
		end
		else if (hit2) begin
			plru_temp_in[0] = 1'b1;
			plru_temp_in[1] = plru_temp_out[1];
			plru_temp_in[2] = 1'b0;
		end
		else if (hit3) begin
			plru_temp_in[0] = 1'b0;
			plru_temp_in[1] = plru_temp_out[1];
			plru_temp_in[2] = 1'b0;
		end
		else begin
			plru_temp_in[0] = 1'b0;
			plru_temp_in[1] = 1'b0;
			plru_temp_in[2] = 1'b0;
		end
	end
	else begin
		plru_temp_in[0] = plru_temp_out[0];
		plru_temp_in[1] = plru_temp_out[1];
		plru_temp_in[2] = plru_temp_out[2];
	end
	
	//Replace
	if (plru_temp_out[1] == 1'b0 && plru_temp_out[2] == 1'b0) begin
		lru0_temp = 1'b1;
		lru1_temp = 1'b0;
		lru2_temp = 1'b0;
		lru3_temp = 1'b0;
	end
	else if (plru_temp_out[1] == 1'b1 && plru_temp_out[2] == 1'b0) begin
		lru0_temp = 1'b0;
		lru1_temp = 1'b1;
		lru2_temp = 1'b0;
		lru3_temp = 1'b0;
	end
	else if (plru_temp_out[0] == 1'b0 && plru_temp_out[2] == 1'b1) begin
		lru0_temp = 1'b0;
		lru1_temp = 1'b0;
		lru2_temp = 1'b1;
		lru3_temp = 1'b0;
	end
	else if (plru_temp_out[0] == 1'b1 && plru_temp_out[2] == 1'b1) begin
		lru0_temp = 1'b0;
		lru1_temp = 1'b0;
		lru2_temp = 1'b0;
		lru3_temp = 1'b1;
	end
	else begin
		lru0_temp = 1'b0;
		lru1_temp = 1'b0;
		lru2_temp = 1'b0;
		lru3_temp = 1'b0;
	end
end

/******************************** Muxes **************************************/

always_comb begin : MUXES

	//write_en mux
	unique case ({write_en_mux0, write_en_mux1, write_en_mux2, write_en_mux3})
			2'b0000: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
				data_write_en2 = 32'b0;
				data_write_en3 = 32'b0;
			end
			
			2'b0001: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
				data_write_en2 = 32'b0;
				data_write_en3 = 32'hFFFFFFFF;
			end
			
			2'b0010: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
				data_write_en2 = 32'hFFFFFFFF;
				data_write_en3 = 32'b0;
			end
			
			4'b0100: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'hFFFFFFFF;
				data_write_en2 = 32'b0;
				data_write_en3 = 32'b0;
			end
			
			4'b1000: begin
				data_write_en0 = 32'hFFFFFFFF;
				data_write_en1 = 32'b0;
				data_write_en2 = 32'b0;
				data_write_en3 = 32'b0;
			end
			
			default: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
				data_write_en2 = 32'b0;
				data_write_en3 = 32'b0;
			end
	endcase
	
	//datain mux
   unique case (datain_mux)
			1'b0: datain_mux_out = mem_wdata;
			
			1'b1: datain_mux_out = pmem_rdata;
			default: datain_mux_out = mem_wdata;
	endcase
	
	//dataout mux
	unique case ({dataout_mux0, dataout_mux1, dataout_mux2, dataout_mux3})
			4'b0000: data = 256'b0;
			
			4'b0001: data = data3;
			
			4'b0010: data = data2;
			
			4'b0100: data = data1;
			
			4'b1000: data = data0;
			
			default: data = 256'b0;
	endcase
	
	//tagout mux
	unique case ({lru0, lru1, lru2, lru3})
			4'b1000: tag_out = tag0;
			
			4'b0100: tag_out = tag1;
			
			4'b0010: tag_out = tag2;
			
			4'b0001: tag_out = tag3;

			default: tag_out = tag0;
	endcase
	
	//dirty load mux
	unique case (dirty_mux)
			1'b0: begin
				dirty_mux_out0 = hit0;
				dirty_mux_out1 = hit1;
				dirty_mux_out2 = hit2;
				dirty_mux_out3 = hit3;
			end
			
			1'b1: begin
				dirty_mux_out0 = lru0;
				dirty_mux_out1 = lru1;
				dirty_mux_out2 = lru2;
				dirty_mux_out3 = lru3;
			end

			default: begin
				dirty_mux_out0 = hit0;
				dirty_mux_out1 = hit1;
				dirty_mux_out2 = hit2;
				dirty_mux_out3 = hit3;
			end
	endcase
	
	//dirty out mux
	unique case ({lru0, lru1, lru2, lru3})
			4'b1000: dirty = dirty0;
			4'b0100: dirty = dirty1;
			4'b0010: dirty = dirty2;
			4'b0001: dirty = dirty3;
			default: dirty = dirty0;
	endcase
end

endmodule : l2_cache_datapath