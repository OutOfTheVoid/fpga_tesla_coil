module Output16Serial (
	input clock_8,
	input clock,
	input reset,
	input [15:0] data,
	output out
);
	
	OSER16 #(
		.GSREN("false"),
		.LSREN("true")
	) serializer (
		.Q(out),
		.D0(data[0]),
		.D1(data[1]),
		.D2(data[2]),
		.D3(data[3]),
		.D4(data[4]),
		.D5(data[5]),
		.D6(data[6]),
		.D7(data[7]),
		.D8(data[8]),
		.D9(data[9]),
		.D10(data[10]),
		.D11(data[11]),
		.D12(data[12]),
		.D13(data[13]),
		.D14(data[14]),
		.D15(data[15]),
		.FCLK(clock_8),
		.PCLK(clock),
		.RESET(reset)
	);
	
endmodule
