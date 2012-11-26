module monitor_module(
	output logic valid_and_not_stall,
	output logic or_valids 
);

    assign valid_and_not_stall = (t15.rp.prg_to_shader_valid & ~t15.rp.prg_to_shader_stall) |
                                 (t15.rp.shader_to_sint_valid & ~t15.rp.shader_to_sint_stall) |
                                 (t15.rp.sint_to_shader_valid & ~t15.rp.sint_to_shader_stall) |
                                 (t15.rp.sint_to_ss_valid & ~t15.rp.sint_to_ss_stall) |
                                 (t15.rp.sint_to_tarb_valid & ~t15.rp.sint_to_tarb_stall) |
                                 (t15.rp.tarb_to_tcache0_valid & ~t15.rp.tarb_to_tcache0_stall) |
                                 (t15.rp.tcache_to_trav0_valid & ~t15.rp.tcache_to_trav0_stall) |
                                 (t15.rp.trav0_to_rs_valid & ~t15.rp.trav0_to_rs_stall) |
                                 (t15.rp.rs_to_trav0_valid & ~t15.rp.rs_to_trav0_stall) |
                                 (t15.rp.trav0_to_tarb_valid & ~t15.rp.trav0_to_tarb_stall) |
                                 (t15.rp.trav0_to_ss_valid & ~t15.rp.trav0_to_ss_stall) |
                                 (t15.rp.trav0_to_list_valid & ~t15.rp.trav0_to_list_stall) |
                                 (t15.rp.trav0_to_larb_valid & ~t15.rp.trav0_to_larb_stall) |
                                 (t15.rp.larb_to_lcache_valid & ~t15.rp.larb_to_lcache_stall) |
                                 (t15.rp.lcache_to_icache_valid & ~t15.rp.lcache_to_icache_stall) |
                                 (t15.rp.icache_to_rs_valid & ~t15.rp.icache_to_rs_stall) |
                                 (t15.rp.rs_to_int_valid & ~t15.rp.rs_to_int_stall) |
                                 (t15.rp.int_to_larb_valid & ~t15.rp.int_to_larb_stall) |
                                 (t15.rp.int_to_list_valid & ~t15.rp.int_to_list_stall) |
                                 (t15.rp.list_to_rs_valid & ~t15.rp.list_to_rs_stall) |
                                 (t15.rp.list_to_ss_valid & ~t15.rp.list_to_ss_stall) |
                                 (t15.rp.ss_to_tarb_valid0 & ~t15.rp.ss_to_tarb_stall0) |
                                 (t15.rp.ss_to_tarb_valid1 & ~t15.rp.ss_to_tarb_stall1) |
                                 (t15.rp.ss_to_shader_valid & ~t15.rp.ss_to_shader_stall) |
                                 (t15.rp.rs_to_pcalc_valid & ~t15.rp.rs_to_pcalc_stall) |
                                 (t15.rp.pcalc_to_shader_valid & ~t15.rp.pcalc_to_shader_stall);
  
    assign or_valids = t15.rp.prg_to_shader_valid |
                     t15.rp.shader_to_sint_valid |
                     t15.rp.sint_to_shader_valid |
                     t15.rp.sint_to_ss_valid |
                     t15.rp.sint_to_tarb_valid |
                     t15.rp.tarb_to_tcache0_valid |
                     t15.rp.tcache_to_trav0_valid |
                     t15.rp.trav0_to_rs_valid |
                     t15.rp.rs_to_trav0_valid |
                     t15.rp.trav0_to_tarb_valid |
                     t15.rp.trav0_to_ss_valid |
                     t15.rp.trav0_to_list_valid |
                     t15.rp.trav0_to_larb_valid |
                     t15.rp.larb_to_lcache_valid |
                     t15.rp.lcache_to_icache_valid |
                     t15.rp.icache_to_rs_valid |
                     t15.rp.rs_to_int_valid |
                     t15.rp.int_to_larb_valid |
                     t15.rp.int_to_list_valid |
                     t15.rp.list_to_rs_valid |
                     t15.rp.list_to_ss_valid |
                     t15.rp.ss_to_tarb_valid0 |
                     t15.rp.ss_to_tarb_valid1 |
                     t15.rp.ss_to_shader_valid |
                     t15.rp.rs_to_pcalc_valid |
                     t15.rp.pcalc_to_shader_valid;

endmodule
