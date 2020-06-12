module cache_datapath #(
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
	
	//CPU
	input logic [31:0] mem_address,
	
	//<--> Memory
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata,
	
	//<--> Bus Adapter
	input logic [255:0] mem_wdata256,
	output logic [255:0] mem_rdata256,
	input logic [31:0] mem_byte_enable256,
	
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
logic [255:0] data0, data1, data, datain_mux_out;
logic [31:0] data_write_en0, data_write_en1;
logic write_en_mux0, write_en_mux1, dataout_mux0, dataout_mux1;

//Tag Arrays
logic [23:0] tag0, tag1;
logic tag_load0, tag_load1;

//Valid Arrays
logic valid0, valid1, valid_load0, valid_load1;

//Dirty Arrays
logic dirty0, dirty1, dirty_mux_out0, dirty_mux_out1, dirty_load0, dirty_load1;

//LRU Array
logic lru, lru_load_internal;

//Hit
logic hit0, hit1;

//Address Splitting
logic [23:0] tag_address;
logic [2:0] index;

/*********************** Various Assignments *****************************/

//Address Splitting
assign tag_address = mem_address[31:8];
assign index = mem_address[7:5];

//Data
assign mem_rdata256 = data;
assign pmem_wdata = data;
assign write_en_mux0 = data_write && hit0 || !lru && datain_mux;
assign write_en_mux1 = data_write && hit1 || lru && datain_mux;
assign dataout_mux0 = hit0 || (m_data_read && !lru); 
assign dataout_mux1 = hit1 || (m_data_read && lru);

//Tag/Hit
assign tag_load0 = tag_load && !lru;
assign tag_load1 = tag_load && lru;
assign hit0 = valid0 && (tag0 == tag_address);
assign hit1 = valid1 && (tag1 == tag_address);
assign hit = hit0 || hit1;

//Valid
assign valid_load0 = valid_load && !lru;
assign valid_load1 = valid_load && lru;

//Dirty
assign dirty_load0 = dirty_load && dirty_mux_out0;
assign dirty_load1 = dirty_load && dirty_mux_out1;

//LRU
assign lru_load_internal = lru_load && hit;

/********************************** Arrays *************************************/

//Two Data Arrays
data_array line [2](
		.clk (clk),
		.rst (rst),
		.read (data_read || m_data_read),
		.write_en ({data_write_en0, data_write_en1}),
		.rindex (index),
		.windex (index),
		.datain (datain_mux_out),
		.dataout ({data0, data1})
);

//Two Tag Arrays
array #(.width(24)) tag [2](
		.clk (clk),
		.rst (rst),
		.read (tag_read),
		.load ({tag_load0, tag_load1}),
		.rindex (index),
		.windex (index),
		.datain (tag_address),
		.dataout ({tag0, tag1})
);

//Two Valid Arrays
array #(.width(1)) valid [2](
		.clk (clk),
		.rst (rst),
		.read (valid_read),
		.load({valid_load0, valid_load1}),
		.rindex (index),
		.windex (index),
		.datain (1'b1),
		.dataout ({valid0, valid1})
);

//Two Dirty Arrays
array #(.width(1)) dirty_array [2](
		.clk (clk),
		.rst (rst),
		.read (dirty_read),
		.load ({dirty_load0, dirty_load1}),
		.rindex (index),
		.windex (index),
		.datain (dirty_in),
		.dataout ({dirty0, dirty1})
);

//One LRU Array
array #(.width(1)) LRU(
		.clk (clk),
		.rst (rst),
		.read (lru_read),
		.load (lru_load_internal),
		.rindex (index),
		.windex (index),
		.datain (hit0),
		.dataout (lru)
);

/******************************** Muxes **************************************/

always_comb begin : MUXES

	//write_en mux
	unique case ({write_en_mux0, write_en_mux1})
			2'b00: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
			end
			
			2'b01: begin
				if (lru && datain_mux) begin
					data_write_en0 = 32'b0;
					data_write_en1 = 32'hFFFFFFFF;
				end
				else begin
					data_write_en0 = 32'b0;
					data_write_en1 = mem_byte_enable256;
				end
			end
			
			2'b10: begin
				if (!lru && datain_mux) begin
					data_write_en0 = 32'hFFFFFFFF;
					data_write_en1 = 32'b0;
				end
				else begin
					data_write_en0 = mem_byte_enable256;
					data_write_en1 = 32'b0;
				end
			end
			
			default: begin
				data_write_en0 = 32'b0;
				data_write_en1 = 32'b0;
			end
	endcase
	
	//datain mux
   unique case (datain_mux)
			1'b0: datain_mux_out = mem_wdata256;
			
			1'b1: datain_mux_out = pmem_rdata;
			default: datain_mux_out = mem_wdata256;
	endcase
	
	//dataout mux
	unique case ({dataout_mux0, dataout_mux1})
			2'b00: data = 256'b0;
			
			2'b01: data = data1;
			
			2'b10: data = data0;
			
			default: data = 256'b0;
	endcase
	
	//tagout mux
	unique case (lru)
			1'b0: tag_out = tag0;
			
			1'b1: tag_out = tag1;

			default: tag_out = tag0;
	endcase
	
	//dirty load mux
	unique case (dirty_mux)
			1'b0: begin
				dirty_mux_out0 = hit0;
				dirty_mux_out1 = hit1;
			end
			
			1'b1: begin
				dirty_mux_out0 = !lru;
				dirty_mux_out1 = lru;
			end

			default: begin
				dirty_mux_out0 = hit0;
				dirty_mux_out1 = hit1;
			end
	endcase
	
	//dirty out mux
	unique case (lru)
			1'b0: dirty = dirty0;
			1'b1: dirty = dirty1;
			default: dirty = dirty0;
	endcase
end

endmodule : cache_datapath