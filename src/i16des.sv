module Input16Serial (
	input clock_8,
	input clock,
	input reset,
	input in,
	output [15:0] data
);
	
	IDES16 #(
		.GSREN("false"),
		.LSREN("true")
	) input_deserializer (
		.FCLK(clock_8),
		.PCLK(clock),
		.RESET(reset),
		.CALIB('0),
		.D(in),
		.Q0(data[0]),
		.Q1(data[1]),
		.Q2(data[2]),
		.Q3(data[3]),
		.Q4(data[4]),
		.Q5(data[5]),
		.Q6(data[6]),
		.Q7(data[7]),
		.Q8(data[8]),
		.Q9(data[9]),
		.Q10(data[10]),
		.Q11(data[11]),
		.Q12(data[12]),
		.Q13(data[13]),
		.Q14(data[14]),
		.Q15(data[15])
	);
	
endmodule
