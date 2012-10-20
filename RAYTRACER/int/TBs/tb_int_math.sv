/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/


/*
class ray_class;
  rand ray_t ray;

endclass
*/

module tb_int_math();
  logic clk;
  logic rst;

  logic v0, v1, v2;

  int_cacheline_t tri0_cacheline;
  triID_t tri0_ID;
  int_cacheline_t tri1_cacheline;
  triID_t tri1_ID;
  ray_t ray_in;

  logic hit_out;  // 1 if hit (valid ray/intersection)
  ray_t ray_out;
  intersection_t intersection_out;
  float_t tMax;
  
  ray_t EM_ray_out;   // Early Miss Ray
  ray_t EM_miss;      // 1 if miss, (valid missed ray)

  

  int_math int_math_inst(.*);
  
  
  logic [1:0] cnt, cnt_n;
  
  assign cnt_n = (cnt == 2'b10) ? 2'b0 : cnt + 1'b1 ;
  ff_ar #(2,0) cnt3(.q(cnt), .d(cnt_n), .clk, .rst);
  
  assign v0 = (cnt == 2'b00);
  assign v1 = (cnt == 2'b01);
  assign v2 = (cnt == 2'b10);


  initial begin
    clk = 0;
    rst = 0;
    #1 rst = 1;
    #1 rst = 0;
    #3;
    forever #5 clk = ~clk;
  end

  
  // Create an arbitrary ray every v0 cycle.
  ray_t ray;
  shortreal pix_width;
  int row;
  int col;
  rayID_t rayID;
  vector_t A1,B1,C1,A2,B2,C2;
  vector_t dir;
  initial begin
    
    rayID = 0;
    row = 0;
    col = 0;
    pix_width = 10.0/480.0;
    dir = create_vec(0.0,0.0,1.0);
    A1 = create_vec(-2.0,3.0,5.0);
    B1 = create_vec(-2.0,-2.0, 5.0);
    C1 = create_vec(2.0,3.0,5.0);

    A2 = create_vec(2.0,-3.0,5.0);
    B2 = create_vec(2.0,2.0, 5.0);
    C2 = create_vec(-1.0,-3.0,5.0);
    tri0_cacheline = create_int_cacheline(A1,B1,C1);
    tri1_cacheline = create_int_cacheline(A2,B2,C2);
    @(posedge clk);
    
    for(int i=0; i<20; i++) begin
      @(posedge clk);
      // want to send out new rays on v0 (1/3 cycles)
      if(v0) begin
        ray.rayID = rayID;
        ray.dir = dir;
        ray.origin = create_vec(row*pix_width,col*pix_width,0.0);
        ray_in <= ray;
        rayID += 1'b1;
        row += 1;
      end
    end

  end

  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction


  // Creates the cacheline based off of 3 triangle coordinates
  function int_cacheline_t create_int_cacheline(input vector_t A, input vector_t B, input vector_t C);
    shortreal a11, a12, a13, a14;
    shortreal a21, a22, a23, a24;
    shortreal a31, a32, a33, a34;
    shortreal a41, a42, a43, a44;
    shortreal det;
    int_cacheline_t c;
    vector_t N;
    N.x = (C.y - A.y)*(B.z - A.z) - (C.z - A.z)*(B.y - A.y);
    N.y = (C.z - A.z)*(B.x - A.x) - (C.x - A.x)*(B.z - A.z);
    N.z = (C.x - A.x)*(B.y - A.y) - (C.y - A.y)*(B.x - A.x);
    shortreal N_norm = sqrt(N.x*N.x + N.y+N.y + N.z*N.z);
    N.x = N.x / N_norm;
    N.y = N.y / N_norm;
    N.z = N.z / N_norm;

    a11 = A.x-C.x; a12 = B.x-C.x; a13 = N.x-C.x; a14 = C.x;
    a21 = A.y-C.y; a22 = B.y-C.y; a23 = N.y-C.y; a24 = C.y;
    a31 = A.z-C.z; a32 = B.z-C.z; a33 = N.z-C.z; a34 = C.z;
    a41 = 0; a42 = 0; a43 = 0; a44 = 1;


    det = a11*a22*a33*a44 + a11*a23*a34*a42 + a11*a24*a32*a43 + 
          a12*a21*a34*a43 + a12*a23*a31*a44 + a12*a24*a33*a41 + 
          a13*a21*a32*a44 + a13*a22*a34*a41 + a13*a24*a31*a42 + 
          a14*a21*a33*a42 + a14*a22*a31*a43 + a14*a23*a32*a41 - 
          a11*a22*a34*a43 - a11*a23*a32*a44 - a11*a24*a33*a42 - 
          a12*a21*a33*a44 - a12*a23*a34*a41 - a12*a24*a31*a43 - 
          a13*a21*a34*a42 - a13*a22*a31*a44 - a13*a24*a32*a41 - 
          a14*a21*a32*a43 - a14*a22*a33*a41 - a14*a23*a31*a42 ;
    

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

/*
    $display("Inverse Matrix =");
    $display("%f %f %f %f\n",b11,b12,b13,b14);
    $display("%f %f %f %f\n",b21,b22,b23,b24);
    $display("%f %f %f %f\n",b31,b32,b33,b34);
    $display("%f %f %f %f\n",b41,b42,b43,b44);
  */

    c.matrix.m11 = b11;
    c.matrix.m12 = b12;
    c.matrix.m13 = b13;
    c.matrix.m21 = b21;
    c.matrix.m22 = b22;
    c.matrix.m23 = b23;
    c.matrix.m31 = b31;
    c.matrix.m32 = b32;
    c.matrix.m33 = b33;
    c.translate.x = b14;
    c.translate.y = b24;
    c.translate.z = b34;

    return c;
  endfunction

  function shortreal sqrt(shortreal arg);
    shortreal error, result_new;
    shortreal result = 1.0;
    error = 1.0;
    while(error > 0.0001) begin
      result_new = argument/2.0/result + result/2.0;
      error = (result_new - result)/result;
      if(error < 0.0) error = -error;
      result = result_new;
    end
    $display("sqrt(%f) = %f",arg, result);
    return result;
  endfunction


endmodule
