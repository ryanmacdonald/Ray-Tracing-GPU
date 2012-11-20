



module temp_sint_fifo_arb(input logic clk, rst,
			  input logic tf_ds_valid, ssf_ds_valid, ssh_ds_valid,
			  input sint_to_ss_t ssf_ray_out,
			  input sint_to_shader_t ssh_ray_out,
			  input tarb_t tf_ray_out,
			  input pb_full,
			  output tf_ds_stall, ssf_ds_stall, ssh_ds_stall,
			  output pixel_buffer_entry_t pb_data,	
			  output logic pb_we);

		logic[1:0] sr, sr_n;
		assign pb_data.pixelID = (~sr[1] && ssh_ds_valid) ? ssh_ray_out.rayID :
					 ( (~sr[0] && ssf_ds_valid) ? ssf_ray_out.rayID : 'h0);
		assign pb_data.color   = (~sr[1] && ssh_ds_valid) ? 24'h00_00_00 : 
					 ( (~sr[0] && ssf_ds_valid) ? 24'hFF_FF_FF : 'h0);	
		assign pb_we = ~pb_full && ((~sr[0] && ssf_ds_valid) || (~sr[1] && ssh_ds_valid));	

	
		assign sr_n = (sr == 2'b10) ? 2'b01 : 2'b10;
		ff_ar #(2,2'b10) r(.q(sr),.d(sr_n),.clk,.rst);
		
		assign tf_ds_stall = pb_full;

		assign ssf_ds_stall = sr[0] || pb_full;
		assign ssh_ds_stall = sr[1] || pb_full;	


endmodule: temp_sint_fifo_arb
