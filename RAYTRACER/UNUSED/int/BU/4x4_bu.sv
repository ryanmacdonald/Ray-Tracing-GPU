/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/


/*
class ray_class;
  rand ray_t ray;

endclass
*/

module tb_int_math();

  shortreal b11, b12, b13, b14;
  shortreal b21, b22, b23, b24;
  shortreal b31, b32, b33, b34;
  shortreal b41, b42, b43, b44;
 
  initial begin
    create_int_cacheline();
    #20;
    sqrt(25.0);
    sqrt(36.0);
    sqrt(0.05);
    $finish;
  end


  function shortreal sqrt(shortreal arg);
    shortreal error, result_new;
    shortreal result = 1.0;
    error = 1.0;
    while(error > 0.0001) begin
      result_new = arg/2.0/result + result/2.0;
      error = (result_new - result)/result;
      if(error < 0.0) error = -error;
      result = result_new;
    end
    $display("sqrt(%f) = %f",arg, result);
    return result;
  endfunction


  function void create_int_cacheline();
    shortreal a11, a12, a13, a14;
    shortreal a21, a22, a23, a24;
    shortreal a31, a32, a33, a34;
    shortreal a41, a42, a43, a44;
    shortreal det, inv_det;

    a11 = 13.5; a12 = 12; a13 = 13; a14 = 14;
    a21 = 21; a22 = 22; a23 = 23; a24 = 24;
    a31 = 30; a32 = 32; a33 = 33; a34 = 34;
    a41 = 0; a42 = 0; a43 = 0; a44 = 1;

    det = a11*a22*a33*a44 + a11*a23*a34*a42 + a11*a24*a32*a43 + 
          a12*a21*a34*a43 + a12*a23*a31*a44 + a12*a24*a33*a41 + 
          a13*a21*a32*a44 + a13*a22*a34*a41 + a13*a24*a31*a42 + 
          a14*a21*a33*a42 + a14*a22*a31*a43 + a14*a23*a32*a41 - 
          a11*a22*a34*a43 - a11*a23*a32*a44 - a11*a24*a33*a42 - 
          a12*a21*a33*a44 - a12*a23*a34*a41 - a12*a24*a31*a43 - 
          a13*a21*a34*a42 - a13*a22*a31*a44 - a13*a24*a32*a41 - 
          a14*a21*a32*a43 - a14*a22*a33*a41 - a14*a23*a31*a42 ;
    inv_det = 1.0/det;

		b11 = inv_det * (a22*a33*a44 + a23*a34*a42 + a24*a32*a43 - a22*a34*a43 - a23*a32*a44 - a24*a33*a42) ;
		b12 = inv_det * (a12*a34*a43 + a13*a32*a44 + a14*a33*a42 - a12*a33*a44 - a13*a34*a42 - a14*a32*a43) ;
		b13 = inv_det * (a12*a23*a44 + a13*a24*a42 + a14*a22*a43 - a12*a24*a43 - a13*a22*a44 - a14*a23*a42) ;
		b14 = inv_det * (a12*a24*a33 + a13*a22*a34 + a14*a23*a32 - a12*a23*a34 - a13*a24*a32 - a14*a22*a33) ;
		b21 = inv_det * (a21*a34*a43 + a23*a31*a44 + a24*a33*a41 - a21*a33*a44 - a23*a34*a41 - a24*a31*a43) ;
		b22 = inv_det * (a11*a33*a44 + a13*a34*a41 + a14*a31*a43 - a11*a34*a43 - a13*a31*a44 - a14*a33*a41) ;
		b23 = inv_det * (a11*a24*a43 + a13*a21*a44 + a14*a23*a41 - a11*a23*a44 - a13*a24*a41 - a14*a21*a43) ;
		b24 = inv_det * (a11*a23*a34 + a13*a24*a31 + a14*a21*a33 - a11*a24*a33 - a13*a21*a34 - a14*a23*a31) ;
		b31 = inv_det * (a21*a32*a44 + a22*a34*a41 + a24*a31*a42 - a21*a34*a42 - a22*a31*a44 - a24*a32*a41) ;
		b32 = inv_det * (a11*a34*a42 + a12*a31*a44 + a14*a32*a41 - a11*a32*a44 - a12*a34*a41 - a14*a31*a42) ;
		b33 = inv_det * (a11*a22*a44 + a12*a24*a41 + a14*a21*a42 - a11*a24*a42 - a12*a21*a44 - a14*a22*a41) ;
		b34 = inv_det * (a11*a24*a32 + a12*a21*a34 + a14*a22*a31 - a11*a22*a34 - a12*a24*a31 - a14*a21*a32) ;
    b41 = 0;
    b42 = 0;
    b43 = 0;
    b44 = 1;

    $display("Inverse Matrix =");
    $display("%f %f %f %f\n",b11,b12,b13,b14);
    $display("%f %f %f %f\n",b21,b22,b23,b24);
    $display("%f %f %f %f\n",b31,b32,b33,b34);
    $display("%f %f %f %f\n",b41,b42,b43,b44);

    return ;
  endfunction



endmodule
