`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/27 09:13:17
// Design Name: 
// Module Name: Conv2_0
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Conv2_0#(
    parameter kernel_size = 3'd3,
    parameter weight_width = 4'd8,
    parameter data_width = 4'd8,
    parameter bias_width = 4'd8
)(
    input clk,
    input rst_n,
    input signed [data_width-1:0] data_in,
    input valid,
    input c2_w_en,
    input [weight_width*16-1:0] c2_w,
    input c2_b_en,
    input [bias_width-1:0] c2_b,

    output [30*16-1:0] dataout,
    output [10:0] conv_time,
    output          conv_end2,//代表每次卷积结束
    output          conv2_end//代表第一层卷积结束，42个数据全部卷�?

    );

    //wire conv_end2;

    reg valid_conv2_r;
    reg [2:0] cnt_mul_data;
    wire cnt3_flag;
    reg [10:0] conv_time_r;//30x42


    wire signed [14:0] data_r_n;
    //wire [bias_width-1:0] data_bias[0:15];
    wire [weight_width-1:0] Multiply_weight[0:15];

    wire        Multiply_adder_en;
    wire [29:0] out_conv20 [0:15];

    // wire out_start_r[0:15];
    // wire out_end_r[0:15];
    // wire out_valid_r [0:15];
    wire valid_conv2;

    wire    conv_end2_n [0:15];

    assign valid_conv2 = (conv_time==0)?(((cnt_mul_data<kernel_size)&&(cnt3_flag==0)&&(c2_w_en))?valid:1'b0):valid;
    assign conv_time = conv_time_r;
    assign data_r_n = data_in *512;
    
    always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			valid_conv2_r  <= 1'b0;
		end
		else begin
			valid_conv2_r  <= valid_conv2;
		end
	end

    assign cnt3_flag = (cnt_mul_data==kernel_size)?1'b1:1'b0;

    //计数3�?
    always@(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin 
            cnt_mul_data <= 3'd0;
            
        end
        else if(cnt_mul_data==kernel_size)begin 
            cnt_mul_data <= 3'd0;
          
        end
        else if((Multiply_adder_en)&&(cnt_mul_data<kernel_size))begin 
            cnt_mul_data <= cnt_mul_data + 1'b1;
        end
        else begin 
            cnt_mul_data <= 3'd0;
        end
    end

    //计算卷积的计算次�?
    always@(negedge clk or negedge rst_n )begin 
        if(!rst_n)begin 
            conv_time_r <= 11'd0;
        end
        else if(conv_end2&&(conv_time<11'd1260))begin 
            conv_time_r <= conv_time_r + 1'b1;
        end
        else begin 
            conv_time_r <= conv_time_r;
        end
    end

    // //读偏�?
    // always@(posedge clk or negedge rst_n)begin 
    //     if(!rst_n)begin 
    //         bias_count<=5'd0; 
    //     end
    //     else if((c2_b_en)&&(bias_count<5'd17))begin 
    //         bias_count<=bias_count +1'd1;
    //     end
    //     else begin 
    //         bias_count <= bias_count;
    //     end
    // end

    // genvar n;
    // generate 
	// 	for(n=0;n<16;n=n+1)
	// 	begin:datab
	// 		assign data_bias[n] = ((c2_b_en)&&(n==bias_count-1))?c2_b:data_bias[n];
	// 	end
	// endgenerate

    //读取权�??

    genvar cw;
    generate 
        for(cw=0;cw<16;cw=cw+1)
        begin:Multi_weight 
            assign Multiply_weight[cw] = c2_w[weight_width*(cw+1)-1:weight_width*cw];
        end
    endgenerate

    assign Multiply_adder_en = valid_conv2_r;

    genvar ma_n;
	generate 
		for(ma_n=0; ma_n< 16; ma_n=ma_n+1)
		begin:Multiply_adder
			Multiply_conv2 n(
				.clk			(clk),
				.rst_n		(rst_n),
				.weight_en	(c2_w_en),
				.Multiply_en	(Multiply_adder_en),
				.weight 		(Multiply_weight[ma_n]),
				//.bias 		(data_bias[ma_n]),
				.data_in		(data_r_n),
				.data_out		(out_conv20[ma_n]),
                .conv_end2    (conv_end2_n[ma_n])

			);
		end
	endgenerate
    
    assign conv_end2 = (conv_time<11'd1261)?conv_end2_n[3]:1'b0;
    assign conv2_end = (conv_time==11'd1260)?1'b1:1'b0;

    assign dataout = {out_conv20[15],out_conv20[14],out_conv20[13],out_conv20[12],out_conv20[11],out_conv20[10],out_conv20[9],out_conv20[8],
    out_conv20[7],out_conv20[6],out_conv20[5],out_conv20[4],out_conv20[3],out_conv20[2],out_conv20[1],out_conv20[0]};


endmodule
