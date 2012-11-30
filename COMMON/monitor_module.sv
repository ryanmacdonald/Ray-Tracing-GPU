module monitor_module(
	output logic valid_and_not_stall,
	output logic or_valids 
);

    assign valid_and_not_stall = (t9.rp.prg_to_shader_valid & ~t9.rp.prg_to_shader_stall) |
                                 (t9.rp.shader_to_sint_valid & ~t9.rp.shader_to_sint_stall) |
                                 (t9.rp.sint_to_shader_valid & ~t9.rp.sint_to_shader_stall) |
                                 (t9.rp.sint_to_ss_valid & ~t9.rp.sint_to_ss_stall) |
                                 (t9.rp.sint_to_tarb_valid & ~t9.rp.sint_to_tarb_stall) |
                                 (t9.rp.tarb_to_tcache0_valid & ~t9.rp.tarb_to_tcache0_stall) |
                                 (t9.rp.tcache_to_trav0_valid & ~t9.rp.tcache_to_trav0_stall) |
                                 (t9.rp.trav0_to_rs_valid & ~t9.rp.trav0_to_rs_stall) |
                                 (t9.rp.rs_to_trav0_valid & ~t9.rp.rs_to_trav0_stall) |
                                 (t9.rp.trav0_to_tarb_valid & ~t9.rp.trav0_to_tarb_stall) |
                                 (t9.rp.trav0_to_ss_valid & ~t9.rp.trav0_to_ss_stall) |
                                 (t9.rp.trav0_to_list_valid & ~t9.rp.trav0_to_list_stall) |
                                 (t9.rp.trav0_to_larb_valid & ~t9.rp.trav0_to_larb_stall) |
                                 (t9.rp.larb_to_lcache_valid & ~t9.rp.larb_to_lcache_stall) |
                                 (t9.rp.lcache_to_icache_valid & ~t9.rp.lcache_to_icache_stall) |
                                 (t9.rp.icache_to_rs_valid & ~t9.rp.icache_to_rs_stall) |
                                 (t9.rp.rs_to_int_valid & ~t9.rp.rs_to_int_stall) |
                                 (t9.rp.int_to_larb_valid & ~t9.rp.int_to_larb_stall) |
                                 (t9.rp.int_to_list_valid & ~t9.rp.int_to_list_stall) |
                                 (t9.rp.list_to_rs_valid & ~t9.rp.list_to_rs_stall) |
                                 (t9.rp.list_to_ss_valid & ~t9.rp.list_to_ss_stall) |
                                 (t9.rp.ss_to_tarb_valid0 & ~t9.rp.ss_to_tarb_stall0) |
                                 (t9.rp.ss_to_tarb_valid1 & ~t9.rp.ss_to_tarb_stall1) |
                                 (t9.rp.ss_to_shader_valid & ~t9.rp.ss_to_shader_stall) |
                                 (t9.rp.rs_to_pcalc_valid & ~t9.rp.rs_to_pcalc_stall) |
                                 (t9.rp.pcalc_to_shader_valid & ~t9.rp.pcalc_to_shader_stall);
  
    assign or_valids = t9.rp.prg_to_shader_valid |
                     t9.rp.shader_to_sint_valid |
                     t9.rp.sint_to_shader_valid |
                     t9.rp.sint_to_ss_valid |
                     t9.rp.sint_to_tarb_valid |
                     t9.rp.tarb_to_tcache0_valid |
                     t9.rp.tcache_to_trav0_valid |
                     t9.rp.trav0_to_rs_valid |
                     t9.rp.rs_to_trav0_valid |
                     t9.rp.trav0_to_tarb_valid |
                     t9.rp.trav0_to_ss_valid |
                     t9.rp.trav0_to_list_valid |
                     t9.rp.trav0_to_larb_valid |
                     t9.rp.larb_to_lcache_valid |
                     t9.rp.lcache_to_icache_valid |
                     t9.rp.icache_to_rs_valid |
                     t9.rp.rs_to_int_valid |
                     t9.rp.int_to_larb_valid |
                     t9.rp.int_to_list_valid |
                     t9.rp.list_to_rs_valid |
                     t9.rp.list_to_ss_valid |
                     t9.rp.ss_to_tarb_valid0 |
                     t9.rp.ss_to_tarb_valid1 |
                     t9.rp.ss_to_shader_valid |
                     t9.rp.rs_to_pcalc_valid |
                     t9.rp.pcalc_to_shader_valid;

endmodule
