`timescale 1ns/100ps 

// user preferences:
`define N 				10000000 	// clk frequency, Hz
`define DUMPFILENAME 	"test.vcd" 	// name of VCD file for GTKWave

// testbench module:
module testbench;
	
	// parameters (don't edit):
	localparam CLK_PERIOD_HALF 	= (10**9)/`N;
	localparam CLK_PERIOD 		= CLK_PERIOD_HALF * 2;
	
	// for waveforms:
	initial begin
		$dumpfile(`DUMPFILENAME);
		$dumpvars(0,data_acquire_0);
	end
	
	// clk signal:
	reg clk = 0;
	always #(CLK_PERIOD_HALF) clk <= ~clk;
	
	// testing procedure:
	reg 					reset_n = 0;
	reg 					syncro 	= 0;
	wire 					data_rdy_o;
	wire signed [11:0] 		data_o;
	reg 		[12*8-1:0] 	adc_data_8;
	reg 		[11:0] 		data_right_answer;
	
	initial begin 
		
		// on:
		#(CLK_PERIOD*10) reset_n <= 1'b1;
		
		// Tests:
		#(CLK_PERIOD*10 + 15) test({12'd8, 12'd7, 12'd6, 12'd5, 12'd4, 12'd3, 12'd2, 12'd1});
		#(CLK_PERIOD*10 + 25) test(-1);
		#(CLK_PERIOD*10 + 25) test({12'd3, 12'd12, -12'sd77, 12'd0, 12'd222, 12'd4, 12'd65, 12'd92});
		#(CLK_PERIOD*10 + 25) test({12'd35, 12'd350, -12'sd911, 12'd28, 12'd287, -12'd1478, -12'd979, -12'd584});
		#(CLK_PERIOD*10 + 25) test({-12'sd914, -12'sd1859, -12'sd1650, 12'd1325, 12'd798, -12'sd749, 12'd1844, -12'd1907});
		
		
		// finish:
		#(CLK_PERIOD*50) $finish;

		
	end
	

	// test's tasks:
	task test;
		input [12*8-1:0] adc_data_in;
		reg signed [14:0] dt_right_ans;
		integer i;
		begin
			dt_right_ans = 0;
			for (i=0; i < 8; i=i+1) begin
				$display("adc_data_in[%d] = %d", i[2:0], $signed(adc_data_in[i*12 +: 12]));
				dt_right_ans = dt_right_ans + $signed(adc_data_in[i*12 +: 12]);
			end
			dt_right_ans = dt_right_ans >>> 3;
			
			adc_data_8 <= adc_data_in;

			syncro 		<= 1'b1;
			#(CLK_PERIOD*5) syncro <= 1'b0;
			
			@ (posedge data_rdy_o);
			if (data_o == dt_right_ans[11:0]) begin
				$display("passed (dt_right_ans == data_o == %d)\n", data_o);
			end else begin
				$display("not passed, dt_right_ans = %d, data_o = %d\n", dt_right_ans, data_o);
			end
			
		end
	endtask


	// ADC model:
	wire 		adc_data_req;
	reg 		adc_data_rdy = 1'b0;
	reg [11:0] 	adc_data;
	
	
	always begin
		@(posedge adc_data_req) #(CLK_PERIOD*(5-1));
		@(posedge clk) adc_data_rdy <= 1'b0;
		@(posedge clk) #(CLK_PERIOD*(15-1));
		@(posedge clk);
		adc_data_rdy 	<= 1'b1;
		adc_data 		<= adc_data_8[11:0];
		adc_data_8 		<= {12'dx, adc_data_8[12*8-1:12]};
	end
				
	
	
	// DUT:
	data_acquire data_acquire_0 (
	
		.clk_i		(clk),
		.reset_n_i 	(reset_n),
		
		//ADC interface
		.adc_data_req_o(adc_data_req),
		.adc_data_rdy_i(adc_data_rdy),
		.adc_data_i(adc_data),
		
		//Module output interface
		.syncro_i(syncro),
		.data_o(data_o),
		.data_rdy_o(data_rdy_o)
	
	);

endmodule