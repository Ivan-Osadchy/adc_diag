//На вход модуля поступают тактовые импульсы clk_i c частотой N, асинхронный сигнал сброса reset_n_i (сброс по уровню 0).
//В произвольный момент времени могут приходить асинхронные импульсы syncro_i длительностью не менее одного такта сигнала clk_i.
//От переднего фронта этого импульса необходимо отсчитать 11 тактов clk_i и провести 8 измерений с помощью АЦП.
//Для выборки данных на АЦП необходимо подать сигнал запроса adc_data_req_o длительностью не менее 2 тактов clk_i. По переднему фронту
//этого сигнала запроса АЦП начинает выборку и оцифровку данных. АЦП работает по фронту запроса, а не по уровню. Необходимо снять сигнал запроса и дождаться готовности данных АЦП по сигналу data_rdy_o.
//На это потребуется несколько тактов clk_i. Данные с АЦП будут готовы по переднему фронту data_rdy_o и будут актуальны до следующиго запроса.
//Сигнал data_rdy_o при этом будет в состоянии логической 1. Значения с АЦП двуполярные в дополнительном коде.
//Их необходимо усреднить по полученным 8-ми измерениям и в таком же формате, как выдаёт АЦП выдать на выход с флагом готовности data_rdy_o. 
//
//Код оформить на языке Verilog HDL без использования конструкций SystemVerilog
//Проверяться проект будет в среде  в Icarus Verilog версии 11



`define PAUSE_AFTER_SYNCRO 	11 		// in clk period
`define NUM_OF_ADC_DATA 	8 		// number of ADC data for accumulate (don't edit without code editing)

module data_acquire(
	input clk_i,
	input reset_n_i,
	
//ADC interface
	output	adc_data_req_o,
	input	adc_data_rdy_i,
	input [11:0] adc_data_i,
	
//Module output interface
	input			syncro_i,
	output [11:0]	data_o,
	output 			data_rdy_o
);
	
	wire signed [11:0] 	adc_data_i;
	wire signed	[11:0] 	data_o;
	

	// detecting posedge of syncro_i:
	reg r_syncro_i;
	always @ (posedge clk_i or negedge reset_n_i) begin
		if (~reset_n_i) r_syncro_i <= 1'b0;
		else r_syncro_i <= syncro_i;
	end
	wire syncro_i_posedge = ({r_syncro_i, syncro_i} == 2'b01);

	`define 	STATE_IDLE 				2'd0
	`define 	STATE_PAUSE 			2'd1
	`define 	STATE_WAIT_ADC_START 	2'd2
	`define 	STATE_WAIT_ADC_READY 	2'd3
	
	reg 		[1:0] 	state;
	reg 		[3:0] 	syscnt;
	reg 				adc_data_req_o;
	reg signed [14:0] 	adc_data_acc;
	reg 				data_rdy_o;
	
	always @ (posedge clk_i or negedge reset_n_i) begin
		if (~reset_n_i) begin
			state 			<= `STATE_IDLE;
			adc_data_req_o 	<= 0;
			data_rdy_o 		<= 0;
		end else begin
			
			case (state)
				
				`STATE_IDLE: begin
					if (syncro_i_posedge) begin
						syscnt 	<= 4'd0;
						state 	<= `STATE_PAUSE;
					end
				end
				
				`STATE_PAUSE: begin
					if (syscnt != (`PAUSE_AFTER_SYNCRO-1)) begin
						syscnt 	<= syscnt + 4'd1;
					end else begin
						adc_data_req_o 	<= 1'b1;
						data_rdy_o 		<= 1'b0;
						adc_data_acc 	<= 0;
						if (adc_data_req_o) begin 
							syscnt 			<= 4'd0;
							state 			<= `STATE_WAIT_ADC_START;
						end
					end
				end
				
				`STATE_WAIT_ADC_START: begin
					if (~adc_data_rdy_i) begin
						adc_data_req_o 	<= 1'b0;
						state 			<= `STATE_WAIT_ADC_READY;
					end
				end
				
				`STATE_WAIT_ADC_READY: begin
					if (adc_data_rdy_i) begin
						adc_data_acc 	<= adc_data_acc + adc_data_i;
						syscnt 			<= syscnt + 4'd1;
						if (syscnt != (`NUM_OF_ADC_DATA-1)) begin
							adc_data_req_o 	<= 1'b1;
							state 			<= `STATE_WAIT_ADC_START;
						end else begin
							data_rdy_o 		<= 1'b1;
							state 			<= `STATE_IDLE;
						end
					end
				end
				
			endcase
			
		end
			
	end
	
	assign data_o = adc_data_acc[14:3];

endmodule

