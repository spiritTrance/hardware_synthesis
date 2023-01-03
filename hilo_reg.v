`timescale 1ns / 1ps
module hilo_reg(
	input  	wire 			clk, rst, 
	input  	wire	[1:0]	we,
	input  	wire 	[31:0] 	hi_i,lo_i,
	output 	wire 	[31:0] 	hi_o,lo_o
    );
	wire hi_we, lo_we;
	assign {hi_we, lo_we} = we;

	reg [31:0] hi, lo;
	// hi_driver
	always @(posedge clk) begin
		if(rst) begin
			hi <= 0;
		end else if (hi_we) begin
			hi <= hi_i;
		end
	end
	// lo_driver
	always @(posedge clk) begin
		if(rst) begin
			lo <= 0;
		end else if (lo_we) begin
			lo <= lo_i;
		end
	end
	assign hi_o = hi;
	assign lo_o = lo;
endmodule
