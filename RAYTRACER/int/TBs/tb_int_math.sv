/*
  This is the main fully pipelined intersection unit.  All intersection computations are done here except triangle fetching from cache and routing hits/misses to the other units.

*/


/*
class ray_class;
  rand ray_t ray;

endclass
*/
typedef struct {
  shortreal x;
  shortreal y;
  shortreal z;
} vectorf_t;


module tb_int_math();
  logic clk;
  logic rst;

  logic v0, v1, v2;

   logic valid_in;
   int_cacheline_t tri0_cacheline;
   int_cacheline_t tri1_cacheline;
   int_pipe1_t int_pipe1_in;

   logic valid_out;
   logic hit_out;  // 1 if hit
   ray_t ray_out;
   intersection_t intersection_out;
  // float_t tMax;

  // Early Miss s
   ray_t EM_ray_out;   // Early Miss Ray
   logic EM_miss ;     // 1 if miss; 0 if hit
 

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
  rayID_t rayID;
  vectorf_t A0,B0,C0,A1,B1,C1;
  initial begin
    valid_in = 0;
    rayID = 0;
    A0 = create_vecf(0.5, 3, 4);
    B0 = create_vecf(3.5, 6, 4);
    C0 = create_vecf(3, 1.5, 4);

    A1 = create_vecf(1.5, 1, 2);
    B1 = create_vecf(4.5, 3.5, 2);
    C1 = create_vecf(5, 0.5, 2);
    tri0_cacheline = create_int_cacheline(A0,B0,C0);
    tri1_cacheline = create_int_cacheline(A1,B1,C1);
    int_pipe1_in.tri1_valid = 1'b1;
    int_pipe1_in.t_max = $shortrealtobits(14);
    int_pipe1_in.tri0_ID = 0;
    int_pipe1_in.tri1_ID = 1;
    int_pipe1_in.ray = 'h0;
    @(posedge clk);
    
    for(shortreal r=0; r<=6; r +=1 ) begin
      for(shortreal c=0; c<=6; c+=1) begin
        ray_t ray;
        ray.dir = create_vec(0,0,1);
        ray.origin = create_vec(c,r,0);
        ray.rayID = rayID;
        rayID += 1;
        @(posedge v0);
        send_ray(ray);
      end
    end
    repeat(50) @(posedge clk);
    $finish;
  end

  // assumes it is called during v0
  task automatic send_ray(ray_t ray);
    ray_t tmp_ray = ray;
    int_pipe1_in.ray <= ray;
    valid_in <= 1'b1;
    @(posedge clk);
    int_pipe1_in.ray <= 'h0;
    valid_in <= 1'b0;
  endtask

  always @(posedge valid_out) begin
    #1;
    $display("\nRAY %d was a %s",ray_out.rayID, hit_out ? "HIT!!" : "MISS");
    $display("\t hit tri%1b at t=%f",intersection_out.triID, t_int_f);
    $display("\t bary = (%f,%f)",bary_u_f,bary_v_f);
  end


  shortreal t_int_f;
  shortreal bary_u_f;
  shortreal bary_v_f;
  always_comb begin
    t_int_f = $bitstoshortreal(intersection_out.t_int);
    bary_u_f = $bitstoshortreal(intersection_out.uv.u);
    bary_v_f = $bitstoshortreal(intersection_out.uv.v);
  end


  function vectorf_t create_vecf(shortreal x, shortreal y, shortreal z);
    vectorf_t vec;
    vec.x = x;
    vec.y = y;
    vec.z = z;
    return vec;
  endfunction


  function vector_t create_vec(shortreal x, shortreal y, shortreal z);
    vector_t vec;
    vec.x = $shortrealtobits(x);
    vec.y = $shortrealtobits(y);
    vec.z = $shortrealtobits(z);
    return vec;
  endfunction


  // Creates the cacheline based off of 3 triangle coordinates
  function int_cacheline_t create_int_cacheline(input vectorf_t A, input vectorf_t B, input vectorf_t C);
    shortreal a11, a12, a13, a14;
    shortreal a21, a22, a23, a24;
    shortreal a31, a32, a33, a34;
    shortreal a41, a42, a43, a44;
    shortreal b11, b12, b13, b14;
    shortreal b21, b22, b23, b24;
    shortreal b31, b32, b33, b34;
    shortreal b41, b42, b43, b44;
    shortreal det, inv_det;
    int_cacheline_t c;
    vector_t N;
    shortreal N_norm;
    
    N.x = (C.y - A.y)*(B.z - A.z) - (C.z - A.z)*(B.y - A.y);
    N.y = (C.z - A.z)*(B.x - A.x) - (C.x - A.x)*(B.z - A.z);
    N.z = (C.x - A.x)*(B.y - A.y) - (C.y - A.y)*(B.x - A.x);
    

    

    N_norm = sqrt(N.x*N.x + N.y*N.y + N.z*N.z);
    N.x = N.x / N_norm;
    N.y = N.y / N_norm;
    N.z = N.z / N_norm;

    /*
    $display("Triangle A,B,C");
    $display("\tA = (%f,%f,%f)",A.x,A.y,A.z);
    $display("\tB = (%f,%f,%f)",B.x,B.y,B.z);
    $display("\tC = (%f,%f,%f)",C.x,C.y,C.z);
    $display("\tN = (%f,%f,%f)",N.x,N.y,N.z);
    */

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
/*
    $display("%f %f %f %f\n",b11,b12,b13,b14);
    $display("%f %f %f %f\n",b21,b22,b23,b24);
    $display("%f %f %f %f\n",b31,b32,b33,b34);
    $display("%f %f %f %f\n",b41,b42,b43,b44);
  */

    c.matrix.m11 = $shortrealtobits(b11);
    c.matrix.m12 = $shortrealtobits(b12);
    c.matrix.m13 = $shortrealtobits(b13);
    c.matrix.m21 = $shortrealtobits(b21);
    c.matrix.m22 = $shortrealtobits(b22);
    c.matrix.m23 = $shortrealtobits(b23);
    c.matrix.m31 = $shortrealtobits(b31);
    c.matrix.m32 = $shortrealtobits(b32);
    c.matrix.m33 = $shortrealtobits(b33);
    c.translate.x = $shortrealtobits(b14);
    c.translate.y = $shortrealtobits(b24);
    c.translate.z = $shortrealtobits(b34);
    

    return c;
  endfunction

  // HOLY SHIT COOL 
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


endmodule
