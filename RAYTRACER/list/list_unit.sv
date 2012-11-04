
/*

  This is another Memory structure that is surounded by different ports with perform different operations
  the list structure is indexed by rayID.
  list_row = [hit, triID, bary_uv, t_int_cur, t_max_leaf] // TODO maybe seperate out these into different brams


  Incoming ports
    trav_to_list (2 ports) // New Leaf node
      write(t_max_leaf);

    int_to_list (Tells of a hit or a miss of last triangle in leaf) // FUCKING COMPLICATED AS FUCK
        if(hit_in & shadow_ray) {
            if(t_int_hit < 1.0) { // This is actually a shadow!
                list_to_ss <= shadow hit!
            }
        }
        else if(hit_in) {
            list_row.hit <= 1;
            if(t_int_cur > t_int_hit) {
                update(triID,bary_uv, t_int_cur)
      
            }
        }
        if(last_of_leaf) {
            if(hit & (t_int_cur <= t_max_leaf) ) { // Note this is the hit status after the hit_in
                list_to_shade <= Hit!!
                list_to_ss <= non shadow hit!
                Clear list_row // set hit to 0
            }
            else { // report miss (even in the case where it was a hit outside of leaf node
                list_to_ss <= miss!
            }
        }

  Outgoing ports

    list_to_shade

    list_to_ss


*/


module list_unit(


  );


endmodule
