
module crc(crc_if.dp m);
bit rst;
logic [31:0] data1;
logic [31:0] gpoly;
logic [31:0] ctrl;

logic [31:0] CRC_DATAf;
logic [31:0] CRC_GPOLYf;
logic [31:0] CRC_CTRLf;

logic [31:0]  tdata,cdata,edata,edata_r,caldata,fdata,d1data,seed, dat,sd1,s,sd2,sd3, dd1, edataf, fdataf;
bit [1:0] t;
bit WAS, R;
logic [1:0] TOT, TOTR;
bit TCRC;
bit FXOR;
logic [31:0 ]cal;
int i;

always@(*)
  begin
        TOT = ctrl [31 : 30];
        TOTR = ctrl[29 : 28];
	R = ctrl [27];
	FXOR	= ctrl [26];
	WAS = ctrl[25];
	TCRC = ctrl[24];
  end
always @(posedge m.clk or posedge m.rst)				// this block need to be corrected for latch condition.
    begin
    if (m.rst == 1)
        begin
       ctrl = 32'h0000_0000;
       if (TCRC == 1)
        seed = 32'hFFFF_FFFF;
        else	
        seed = 32'h0000_FFFF;
	
        gpoly = 32'h0000_1021;
        sd3 = 32'hffff_ffff;
        sd2 = 32'h0000_FFFF;
        sd1 = 32'hFFFF_FFFF;
        edata = 32'hFFFF_FFFF;
        caldata = 32'hFFFF_FFFF;
        fdata = 32'hFFFF_FFFF;
        end

else 
begin
if (m.addr == 32'h4003_2008 && m.RW == 1 && m.Sel ==1)
		begin 
		ctrl = m.data_wr;
        end
if	(m.addr == 32'h4003_2000 && m.RW == 1 && m.Sel ==1)
		seed = m.data_wr;
		
if (m.addr == 32'h4003_2004 && m.RW == 1 && m.Sel ==1)
		gpoly = m.data_wr;
  
if(m.RW   &&    m.addr == 32'h4003_2000    &&  m.Sel) begin
  
case ( TOT )



2'b00:	tdata = seed;
2'b01:
begin
   
	tdata	[ 31 : 24 ] 	=	{ seed[24],	seed[25],	seed[26],	seed[27],	seed[28],	seed[29],	seed[30],	seed[31] };
	tdata	[ 23 : 16 ] 	=	{ seed[16],	seed[17],	seed[18],	seed[19],	seed[20],	seed[21],	seed[22],	seed[23] }; 
	tdata	[ 15 :  8 ] 	=	{ seed[ 8],	seed[9],	seed[10],	seed[11],	seed[12],	seed[13],	seed[14],	seed[15] }; 
	tdata	[  7 :  0 ] 	=	{ seed[ 0],	seed[1],	seed[ 2],	seed[ 3],	seed[ 4],	seed[ 5],	seed[ 6],	seed[ 7] }; 

		
end
2'b10:
begin 
  

	tdata	=		{ seed[ 0],	seed[1],	seed[ 2],	seed[ 3],	seed[ 4],	seed[ 5],	seed[ 6],	seed[ 7] ,
                        	 seed[ 8],	seed[9],	seed[10],	seed[11],	seed[12],	seed[13],	seed[14],	seed[15] ,
                        	 seed[16],	seed[17],	seed[18],	seed[19],	seed[20],	seed[21],	seed[22],	seed[23] ,
                        	 seed[24],	seed[25],	seed[26],	seed[27],	seed[28],	seed[29],	seed[30],	seed[31] };

end 

2'b11:
begin
	tdata	[ 31 : 24 ] 	=	{ seed[ 7],	seed[6],	seed[ 5],	seed[ 4],	seed[ 3],	seed[ 2],	seed[ 1],	seed[ 0] }; 
	tdata	[ 23 : 16 ] 	=	{ seed[ 15],	seed[14],	seed[13],	seed[12],	seed[11],	seed[10],	seed[9],	seed[8] }; 
	tdata	[ 15 :  8 ] 	=	{ seed[23],	seed[22],	seed[21],	seed[20],	seed[19],	seed[18],	seed[17],	seed[16] }; 
	tdata	[  7 :  0 ] 	=	{ seed[31],	seed[30],	seed[29],	seed[28],	seed[27],	seed[26],	seed[25],	seed[24] };

	
end
endcase
  
if	( TCRC == 1'b1)
begin
	if (WAS == 1)
	begin
		sd1 = tdata;
		edata = tdata;
            //s = sd1;
	
    end
	if(WAS ==0)
	begin 
	    dd1 = tdata;
    end

    if(WAS == 0 && edata!= 32'hFFFF_FFFF)
    sd2 = edata;

end

if	( TCRC == 1'b0)
begin
    if(WAS ==0)
	begin
		dd1 = tdata;
	end
	if (WAS == 1)
	begin
		sd1 = tdata;
		edata = tdata;
		//sd3 = tdata;
		//sd2 = sd3;		
	end
    if (WAS==0 && (edata != 32'hffff_ffff || edata == 32'h0000E0FB)) 
            sd1 = edata;	
end
	

	if(TCRC==1)
        begin
            if(WAS == 0)
            begin 
                s = edata;
                //s= sd1;
                for (i = 0; i < 32; i++)
                begin
                    if( s [ 31 ] == 0    )
                    begin 
                            s = s << 1;
                            s[0] =  dd1[ 31-i ];
                        //$display ( "0shft s %h d= %h",s, dd1);   
                    end
                    else if( s[ 31 ] == 1)
                    begin
                            s = s << 1;
                            s[0] = dd1[ 31-i ];
                            s = s ^ gpoly;
                    end
                    if (i == 31)
                    edata = s;
                    
                    //$display("i = %d, s = %2h d= %2h", i, s, dd1);
                end
                //edata = s;
               // sd2 = edata;
            end 
        end 
        else if (TCRC == 0)
        begin
            if(WAS==0)
            begin
                sd2= edata[15:0];
                for (i = 0; i < 32; i++)
                begin
                //$display ( "prev s %h d= %h",sd2, dd1);
                    if( sd2 [ 15 ] == 0    )
                    begin 
                            sd2 = sd2 << 1;
                            sd2[0] =  dd1[ 31-i ];
                        //$display ( "0shft s %h d= %h",sd2, dd1);   
                    end
                    else if( sd2[ 15 ] == 1)
                    begin
                            sd2 = sd2 << 1;
                            sd2[0] = dd1[ 31-i ];
                            sd2 = sd2[15:0] ^ gpoly;
                    end
                    if (i == 31)
                    edata = {16'b0,sd2[15:0]};
                
                   // $display("i = %d, s = %2h d= %2h", i, sd2, dd1);
                end
                //edata = sd2;
            end
        
        end
       // sd2 = edata;
        //s = edata;
        //caldata = edata;
        //edataf= fdata;
  
       // $display("%0t",$time );
	
	
	
	
//end 
//edataf = fdata; //nt used
//for

  caldata = edata;

if (FXOR == 1)
	begin
		if (TCRC ==1)
		begin
		caldata = caldata ^32'hFFFF_FFFF;		
		end
		else 
		begin
			if (TOTR == 2'b11 )
				caldata= caldata^ 32'h0000_FFFF;
			else if ( TOTR == 2'b10 )
				caldata= caldata^ 32'h0000_FFFF;
			else
				caldata= caldata^ 32'h0000_FFFF;
		end
	end



case ( TOTR )

2'b00:	fdata = caldata;
2'b01:
begin

    //$display("i am  01");
	fdata	[ 31 : 24 ] 	=	{ caldata[24],	caldata[25],	caldata[26],	caldata[27],	caldata[28],	caldata[29],	caldata[30],	caldata[31] };
	fdata	[ 23 : 16 ] 	=	{ caldata[16],	caldata[17],	caldata[18],	caldata[19],	caldata[20],	caldata[21],	caldata[22],	caldata[23] }; 
	fdata	[ 15 :  8 ] 	=	{ caldata[ 8],	caldata[9],	caldata[10],	caldata[11],	caldata[12],	caldata[13],	caldata[14],	caldata[15] }; 
	fdata	[  7 :  0 ] 	=	{ caldata[ 0],	caldata[1],	caldata[ 2],	caldata[ 3],	caldata[ 4],	caldata[ 5],	caldata[ 6],	caldata[ 7] }; 

		
end
2'b10:

	fdata	=		{ caldata[ 0],	caldata[1],	caldata[ 2],	caldata[ 3],	caldata[ 4],	caldata[ 5],	caldata[ 6],	caldata[ 7] ,
                        	 caldata[ 8],	caldata[9],	caldata[10],	caldata[11],	caldata[12],	caldata[13],	caldata[14],	caldata[15] ,
                        	 caldata[16],	caldata[17],	caldata[18],	caldata[19],	caldata[20],	caldata[21],	caldata[22],	caldata[23] ,
                        	 caldata[24],	caldata[25],	caldata[26],	caldata[27],	caldata[28],	caldata[29],	caldata[30],	caldata[31] };


2'b11:
begin
	fdata	[ 31 : 24 ] 	=	{ caldata[ 7],	caldata[6],	caldata[ 5],	caldata[ 4],	caldata[ 3],	caldata[ 2],	caldata[ 1],	caldata[ 0] }; 
	fdata	[ 23 : 16 ] 	=	{ caldata[ 15],	caldata[14],	caldata[13],	caldata[12],	caldata[11],	caldata[10],	caldata[9],	caldata[8] }; 
	fdata	[ 15 :  8 ] 	=	{ caldata[23],	caldata[22],	caldata[21],	caldata[20],	caldata[19],	caldata[18],	caldata[17],	caldata[16] }; 
	fdata	[  7 :  0 ] 	=	{ caldata[31],	caldata[30],	caldata[29],	caldata[28],	caldata[27],	caldata[26],	caldata[25],	caldata[24] };


	
end
endcase


//edataf = fdata;




end 
end 
end









/*
always @(posedge m.clk)
begin 
if (m.rst == 0 )
begin

  
		
end


end
*/
/*
always @(posedge m.clk) begin
if(c1.WAS == 1 && c1.TCRC==0  && m.rst != 1 )
begin edata = tdata; 
end 
end */


//always @(tdata)
//    begin
        
        
 //   end  

    
    always @(*)
    begin
      if (m.addr == 32'h4003_2008 && m.RW == 0 && m.Sel ==1)
		m.data_rd = ctrl;

    if	(m.addr == 32'h4003_2000 && m.RW == 0 && m.Sel ==1 )
	begin 
        if(seed == 32'hffff_ffff)
            m.data_rd = seed;
        else
        m.data_rd = /*edataf*/ fdata;
	end
    if (m.addr == 32'h4003_2004 && m.RW == 0 && m.Sel ==1)
	m.data_rd = gpoly;
    
    
    end 
    
    

endmodule: crc

