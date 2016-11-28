struct packed{
		logic [  7 : 5 ] 	code;
		logic  			lend;
		logic  			onesd;
		logic  [  2 : 0 ]	addrlen;		
		}	data;
struct packed {  logic [  31 :  0 ]	wrdata;
                 logic [ 7 :  0 ]	rlen;
                 logic [  31 :  0 ]	address;
                logic [	 7 :  0 ]	sid;
                logic [  7 :  0 ]	ctl;                
            } pushdata;

module mem32x64(input bit clk,input logic [10:0] waddr, 
    input logic [99:0] wdata, input bit write,
    input logic [10:0] raddr, output logic [99:0] rdata);

logic [99:0] mem[0:2043];
logic  [99:0] rdatax;

logic [99:0] w0,w1,w2,w3,w4,w5,w6,w7;
assign rdata = rdatax;

always @(*) begin
  rdatax <= #2 mem[raddr];
end

always @(posedge(clk)) begin
  if(write) begin
    mem[waddr]<=#2 wdata;
  end
end
endmodule
	
module FIFO(clk, rst, push, data_in, flag, pop ,data_out , fifo_full, fifo_empty);

input bit clk, rst, push, pop ;        // push = write     // pop = read 
input  logic [99:0] data_in;
input logic [1:0] flag;
output logic [99:0] data_out;
output bit fifo_full, fifo_empty;

logic [10:0] write_address;
logic [10:0] read_address;
logic [10:0] fifo_count;
//assign push =1;

// generate internal write address
always@(posedge clk or posedge rst)

if (rst)
    begin 
    //if(flag==0)
    write_address <= #1 'b0;  // 256 locations
//    data_out <= 0;
    end 
else 
    if (push == 1'b1 && (!fifo_full))                   // if write = 1 and if fifo is NOT full then perform write operation
        write_address <= #1 write_address + 1'b1;
     
// generate internal read address pointer
always@(posedge clk or posedge rst)
if (rst)
    read_address <= #1 'b0; // 256 locations
else
    if (pop == 1'b1 && (!fifo_empty))                   // if read = 1 and if fifo is NOT empty then perform read operation 
        read_address <= #1 read_address +1'b1;

// generate FIFO count
// increment on push, decrement on pop
always@(posedge clk or posedge rst)
 
if (rst)
    fifo_count <= #1 'b0;   // 256 locations
else
    if (push== 1'b1 && pop == 1'b0 && (!fifo_full))
        fifo_count <= #1 (fifo_count + 1);        // increment counter if write
else
    if (push== 1'b0 && pop == 1'b1 && (!fifo_empty))               // decrement counter if read
        fifo_count <= #1 (fifo_count - 1);

// generate FIFO signals

assign fifo_full  =  (read_address == write_address+1)? 1'b1:1'b0; //(fifo_count == 8'b11111111)?1'b1:1'b0;
assign fifo_empty =   (read_address == write_address) ? 1'b1:1'b0; //(fifo_count == 8'b00000000)?1'b1:1'b0;


// connect RAM


mem32x64 mem1 (clk,write_address,data_in,push,read_address,data_out);

//module mem32x64(input clk,  input [4:0] waddr, input [63:0] wdata, input write, input [4:0] raddr, output [63:0] rdata);


endmodule

module noc(nocif.md a, crc_if.dn b);
    logic  [99:0] data_in;
    logic  [99:0] data_out;
    logic  [31:0]datard,datard1,datard2,datar;
    bit fifo_full, fifo_empty;

	logic [ 31 :  0 ]	address,wrdata, raddress,rddata,retaddr,maddr,mdata,addressm,wrdatam,crc_data;
	logic [  7 :  0 ]	data;
	logic [  7 :  0 ]	datawt;
	logic [  7 :  0 ]	ctl,get_ctl,ctlm;
	logic [  4 :  0 ]  nextstate,nextstate2,nextstate3,nextstate5;
	logic		cmdw;
	logic		cmdr;
	logic [	 7 :  0 ]	sid, rid,retid,mrid,sidm;
	logic [  2 :  0 ]	rcnt,code;
	logic [	 7 :  0 ]	wlen, rlen,retwlen,mlen,rlenm;
    logic [1:0] count=0, countf, count2=0,countf2;
    logic[7:0]count_crc,count_crcf;
    logic[31:0]lenf,Dataf,crc_res;
////////////////////////fifo
  logic [99:0] popdata;

////Data going to CRC
		logic [	31 :  0 ]	ctrl, poly;
		logic [	31 :  0 ]	actrl, adata, apoly;
		logic RW,Sel;
////read parameters
	logic [7:0] getctl;
	logic len, ones;
	logic [  2 :  0 ]	adlen;
//////fifo
	bit		push;
	bit		pop;
	bit stopw,stopr,stopm;
	logic [1:0] flag=0;
	
	
	//bm logic
logic [31 : 0] chain, start_chain;
bit i,rdflag;
//chain block
logic   [31:0]  Link, Seed, Ctrl, Poly, Data, Len, Result, Message;
///////States
	enum {lazy ,sourceid, addr1, addr2, addr3, addr4, lenbyte, data1,data2,data3,data4}state;	
	enum{be_a_master,rid_m,add_to_m1,add_to_m2,add_to_m3,add_to_m4,len_m,data_to_m1,data_to_m2,data_to_m3,data_to_m4} state5;
    enum {lazy2,getreaddata,rddata2,rddata3,readresp,returnid,raddr1,raddr2,raddr3,raddr4,endst} state2;
   enum {lazy3,wrtocrc,wrresp,returnid_wr} state3; 
   enum{lazy4,check_address,set_reqm,set_sidm,Read_32_bytes1,Read_32_bytes2,Read_32_bytes3,Read_32_bytes4,Read_32_bytes_len,blankst,blankst2,Read_link1,Read_link2,Read_link3, Read_link4,Read_seed1,Read_seed2,Read_seed3,Read_seed4,Read_ctrl1,Read_ctrl2,Read_ctrl3,Read_ctrl4,Read_poly1,Read_poly2,Read_poly3,Read_poly4,Read_data1,Read_data2,Read_data3,Read_data4,Read_len1,Read_len2,Read_len3,Read_len4,Read_Result1,Read_Result2,Read_Result3,Read_Result4,Read_Msg1,Read_Msg2,Read_Msg3,Read_Msg4,crc,crc_blank,crc_blank2,crc_data1,crc_data2,crc_data3,crc_data4,send_add1,send_add2,send_add3,send_add4,send_add5,send_add6,send_add7,read_crc_res,send_res1,send_res2,send_res3,send_res4,send_res5,send_res6,send_res7,send_res8,send_res9,send_res10,send_res11,send_msg,send_msg1,send_msg2,send_msg3,send_msg4}state4,nextstate4;
   //module FIFO(clk, rst, push, data_in, pop ,data_out , fifo_full, fifo_empty);
FIFO F1 (a.clk, a.rst, push, data_in, flag, pop, data_out, fifo_full, fifo_empty);

always @ (posedge a.clk or posedge a.rst)
begin	
		if ( a.rst == 1)
		begin
			a.DataR	<=	0;	
			data	<=	0;
			cmdw	<=	0;	
			state	<=	0;	
			state2  <= lazy2;
			state3  <= lazy3;
			state4  <= lazy4;
			state5  <= be_a_master;
			countf  <= 0;
			countf2 <= 0;
			start_chain <=0;
			Ctrl <= 0;
			lenf <= 0;
			count_crcf <=0;
			Dataf <= 0;
			chain <=0;
			data_in <= 0;
			
		end
		else
		begin
			data	<=	 a.DataW;
			cmdw	<=	 a.CmdW;		
			state	<=	 nextstate;
			state2  <=   nextstate2;
			state3  <=   nextstate3;
			state4  <=   nextstate4;
			state5  <=   nextstate5;
			countf  <=   count;
			countf2 <=   count2;
			lenf <= Len;
			count_crcf <= count_crc;
			Dataf <= Data;
			//flag <= 1;
        end
end 
always @(*)
begin 
if (a.rst)
begin
    nextstate = 0;
    nextstate2 = 0;
    nextstate3 = 0;
end 
else begin

case (state)
	lazy	:begin
                        push = 0;
                        stopm=0;
                    if (cmdw ==1 && start_chain ==0) 
                    begin
                            code   = 	data[7:5];
                            len	   =	data[4];
                            ones   =	data[3];
                            adlen  =	data[2:0];	
                            ctl = data;
                            if (code == 000 /*|| ctlm == 8'h68*/)
                                begin
                                    nextstate = lazy;
                                end  
                        else if(/*stopr==0 && stopw==0 &&*/ ctl == 8'h68)
                                begin
                                    stopm=1;
                                    a.CmdR = 1;
                                    a.DataR= 8'h80;
                                    nextstate = sourceid;
                                end 
                           else 
                                begin
                                
                                    //ctl = data;
                                    nextstate = sourceid;
                                end
                    end 
			end
	sourceid:	begin	
                sid	=	data;
               if(ctl == 8'h68)
                    begin
                        a.CmdR = 0;
                        a.DataR= sid;
                        nextstate = addr1;
                    end 
                else
				nextstate =	addr1;
			end
	addr1 :		begin	
                    stopm=0;
                address[ 7 : 0 ]	=	data;
                if( ctl[2:0] == 3'b000)
                    begin
                    address[31:8] = 24'hffff_ff ;
                    nextstate = lenbyte;
                    end 
                else 
				nextstate =	addr2;
			end
	addr2 :		begin	address[ 15 : 8 ]	=	data;
				nextstate =	addr3;
			end
	addr3 : 	begin	address[ 23 :  16 ]	=	data;
				nextstate =	addr4;
			end
	addr4 : 	begin	address[  31 :  24 ]	=	data;
				nextstate =	lenbyte;
				end
	lenbyte : 	begin   
                    rlen	=	data;
                    
                    begin
                        if(code == 3'b011)
                        begin
                            nextstate = data1;
                        end 
                        else if (code == 3'b001 )
                        begin
                                push = 1;
                            	 pushdata = {rlen,address,sid,ctl};
                                data_in = pushdata;
                            nextstate = lazy;
                        end 
                    end
                end 
    data1 :	begin	wrdata[ 7 : 0 ]	 =	data;
				nextstate =	data2;
			end
	data2 :	begin	wrdata[ 15 : 8 ]  =	data;
				nextstate =	data3;
			end
	data3 : begin	wrdata[ 23 :  16 ] =	data;
				nextstate =	data4;
			end
	data4 : begin	wrdata[  31 :  24 ]	=	data;
                    if (ctl == 8'h68 && address == 32'hffff_fff0)
                        begin
                            //i=0;
                            chain = wrdata;
                            nextstate = lazy;
                            i=0;
                        end 
                    if (ctl == 8'h68 && address == 32'hffff_fff4)
                        begin 
                            
                            start_chain = wrdata;
                            nextstate = lazy;
                        end 
                    else if(ctl!=8'h68)
                    begin 
                        nextstate =	lazy;
                        push = 1;
                        pushdata = {wrdata,rlen,address,sid,ctl};
                        data_in = pushdata;
                    end 
            end 
   endcase
   //sourceidm,addrm,lenbytem,data1m,data2m,data3m,data4m

case (state2)
lazy2 : begin
            if (stopw==0 && stopm==0)//8'h63 && ctlm !=8'h68)
            begin 
            a.CmdR = 1;
            a.DataR = 0;
            end 
            b.Sel = 0;
            b.RW =0;
            stopr= 0;
            rdflag=0;
            //pop = 1;
           // get_ctl = data_out[ 7 :  0 ];   //getctl
             if(state3==0 && fifo_empty==0)//&& fifo_empty==0 )
             begin
                    pop =   1;
                    get_ctl = data_out[ 7 :  0 ];
                    rid = data_out[	15 :  8 ]; //rid
                    raddress = data_out[47:16];	//raddr;
                    wlen = data_out[55 :  48 ];
                    rddata = data_out[87:56]; //data 
             #0       if (get_ctl == 8'h23 && stopw==0 && fifo_empty==0)
                begin
                stopr = #1 1;
                //rdflag = 1;
                b.RW=0;
                nextstate2 = getreaddata;
                    end 
                end 
            else begin 
          //          pop = 0;
               // get_ctl = 0;
                nextstate2 = lazy2;
                end
               retaddr= raddress;
                retid = rid;
                retwlen=wlen;
                
                
                
           
        end 
getreaddata : begin
              //  stopr=1;
                pop=0;
                b.Sel =1;
                b.addr = retaddr;
                datard = b.data_rd;
             #1   if(retwlen == 8'h0c || retwlen == 8'h08)
                begin
                    b.RW=0;
                    nextstate2 = rddata2;
                end 
                else if(get_ctl==8'h23 && stopw ==0)
                begin
                   // stopr=1;
                    nextstate2 = readresp /*lazy2*/;
                end 
                else nextstate2 = lazy2;
                
                end 
rddata2 : begin
                b.Sel =1;
                b.RW = 0;
                b.addr = retaddr+32'h4;
                datard1 = b.data_rd;
               #1  if(retwlen == 8'h0c)
                    nextstate2 = rddata3;
                else if(stopw==0)
                    nextstate2 = readresp;
            end 
rddata3 : begin
            b.Sel = 1;
            b.addr = retaddr+32'h8;
            datard2 = b.data_rd;
         #1   if(stopw==0)
            nextstate2 = readresp;
            end 
            
readresp : begin
            stopr=  1;
             b.Sel = 0;
             a.CmdR = 1;
            a.DataR = 8'h40;
            nextstate2= returnid;
                end 
returnid : begin
             b.Sel = 0;
            a.CmdR = 0;
            a.DataR = retid;
            datar=datard;
            nextstate2 = raddr1;
           end
raddr1 : begin
            a.CmdR = 0;
            a.DataR = datar[7:0];
            nextstate2 = raddr2;
         end
raddr2 : begin
            a.CmdR = 0;
            b.Sel = 0;
            a.DataR = datar[15:8];
            nextstate2 = raddr3;
         end
raddr3 : begin
            a.CmdR = 0;
            a.DataR = datar[23:16];
            nextstate2 = raddr4;
         end

raddr4 : begin
            a.CmdR = 0;
            a.DataR = datar[31:24];
            count = countf +1;
            if (retwlen == 8'h0c || retwlen == 8'h08 )
                begin
                    if (count == 2'h1)
                    begin
                        datar= datard1;
                        nextstate2= raddr1;
                    end 
                    else if (count == 2'h2 && retwlen == 8'h0c)
                    begin
                        datar= datard2;
                        nextstate2= raddr1;
                    end                    
                    else 
                        nextstate2 = endst;//3;
                    end 
            else nextstate2 = endst;//3;
           end
endst : begin
            a.CmdR = 1;
            a.DataR = 8'hE0;
            nextstate2 = lazy2;
        end 
endcase

 case (state3)
lazy3 : begin
            if (stopr==0 && stopm==0)//8'h63 && ctlm !=8'h68)
            begin 
            a.CmdR = 1;
            a.DataR = 0;
            b.Sel = 0;
            b.RW =0;
            get_ctl = 0;
            end
           #0 if(state2==0 &&  fifo_empty ==0)
            begin
                        pop = 1;
                       // stopw=1;
                        get_ctl = data_out[ 7 :  0 ];   //getctl
                        rid = data_out[	15 :  8 ]; //rid
                        raddress = data_out[47:16];	//raddr;
                        wlen = data_out[55 :  48 ];
                        rddata = data_out[87:56]; //data
           #0 if (get_ctl== 8'h63 && stopr==0  && fifo_empty==0/*&& stopm==0*/)
            begin              
                stopw=1;
                nextstate3 = #1 wrtocrc;
            end
            end 
           // else //if(stopr==1)
            //pop=0;
            mrid=rid;
            maddr=raddress;
            mlen = wlen;
            mdata=rddata;
            stopw=0;
           
            
        end 
wrtocrc : begin
         //  stopw=1;
           
           pop=0;
           if(get_ctl == 8'h63)
           begin
           b.Sel =1;
            b.RW = 1;
            b.addr = raddress;
            b.data_wr = rddata;
             datard = b.data_rd;
           #1  if(stopr==0)
            nextstate3 =  wrresp;
            end 
            else 
            nextstate3 = lazy3;
          end 
wrresp : begin
            stopw=1;
            b.Sel = 0;
            a.CmdR = 1;
            a.DataR = 8'h80;
            nextstate3= returnid_wr;
            end 
returnid_wr : begin
             b.Sel = 0;
            a.CmdR = 0;
            a.DataR = retid;
            nextstate3 = lazy3;
            end                
endcase 

case(state4)
lazy4 : begin
               if(start_chain!=0)  // bus_master mode
               begin 
                    nextstate4 = check_address;
                end
                else if (start_chain==0)
                    nextstate4=lazy4;
        end
  
check_address : begin
                    
                    if((i==0)?chain:Link!=0)
                    begin
                       // a.CmdR=0;
                        //a.DataR= 8'h12;
                        nextstate4= set_reqm; //Read_32_bytes1;
                    end
                    else if((i==0)?chain:Link==0)
                    begin
                        start_chain=0;
                        //i=0;
                        nextstate4=lazy4;
                    end 
                end 
set_reqm : begin
                a.CmdR  = 1;
                a.DataR = 8'h23;
                nextstate4 = set_sidm;
            end 
set_sidm : begin
                a.CmdR  = 0;
                a.DataR = 8'h12;
                nextstate4 = Read_32_bytes1;
            end 

                
Read_32_bytes1 : begin
            a.CmdR = 0;
            a.DataR = (i==0)?chain[7:0]: Link[7:0];
            nextstate4 = Read_32_bytes2;
         end
Read_32_bytes2 : begin
            a.CmdR = 0;
            
            a.DataR = (i==0)?chain[15:8]: Link[15:8];
            nextstate4 = Read_32_bytes3;
         end
Read_32_bytes3 : begin
            a.CmdR = 0;
            a.DataR = (i==0)?chain[23:16]: Link[23:16];
            nextstate4 = Read_32_bytes4;
         end

Read_32_bytes4 : begin
            a.CmdR = 0;
            a.DataR = (i==0)?chain[31:24]:Link[31:24];
            nextstate4 = Read_32_bytes_len;
            end
Read_32_bytes_len : begin
                        a.CmdR=0;
                        a.DataR= 8'h20;
                        nextstate4= blankst;//lazy4;
                    end 
blankst : begin
                nextstate4 = Read_link1;
            end 
blankst2 : nextstate4= Read_link1;
Read_link1 :	begin	Link[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_link2;
			end
Read_link2 :	begin	Link[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_link3;
			end
Read_link3 : begin	Link[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_link4;
			end
Read_link4 : begin	Link[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_seed1;
				i=1;
			end
Read_seed1: begin 
                Seed[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_seed2;
            end
Read_seed2 :	begin	Seed[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_seed3;
			end
Read_seed3 : begin	Seed[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_seed4;
			end
Read_seed4 : begin	Seed[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_ctrl1;
				
			end
Read_ctrl1: begin 
                b.Sel=0;
                b.RW= 0;

                Ctrl[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_ctrl2;
            end
Read_ctrl2 :	begin	
               // b.Sel = 1;
				//b.RW = 1;
				//b.addr = 32'h4003_2000;
				//b.data_wr = Seed;//Ctrl;
                Ctrl[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_ctrl3;
			end
Read_ctrl3 : begin	
                //b.Sel=0;
                //b.RW= 0;
                Ctrl[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_ctrl4;
			end
Read_ctrl4 : begin	Ctrl[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_poly1;
				Ctrl[25]=1;
				b.Sel = 1;
				b.RW = 1;
				b.addr = 32'h4003_2008;
				b.data_wr = Ctrl;
				Ctrl [25]=0;
				
			end
Read_poly1: begin 
                //b.Sel=0;
                //b.RW=0;
                b.Sel = 1;
				b.RW = 1;
				b.addr = 32'h4003_2000;
				b.data_wr = Seed;
                Poly[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_poly2;
            end
Read_poly2 :	begin	
                b.Sel=1;
                b.RW=1;
                b.addr = 32'h4003_2008;
				b.data_wr = Ctrl;
                Poly[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_poly3;
			end
Read_poly3 : begin
                Poly[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_poly4;
			end
Read_poly4 : begin	
                b.Sel=0;
                b.RW=0;
               
                Poly[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_data1;
				b.Sel = 1;
				b.RW = 1;
				b.addr = 32'h4003_2004;
				b.data_wr = Poly;
			end
Read_data1  : begin 
                b.Sel=0;
                b.RW=0;
                Data[ 7 : 0 ]	 =	a.DataW;
                
				nextstate4 =	Read_data2;
            end
Read_data2 :	begin	
                 a.CmdR = 1;
                a.DataR=8'h23;
                Data[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_data3;
			end
Read_data3 : begin	
                a.CmdR = 0;
                a.DataR= 8'h2c;
                Data[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_data4;
			end
Read_data4 : begin	
                a.CmdR = 0;
                a.DataR= Data[7:0];
                Data[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_len1;
			end
Read_len1  : begin 
                a.CmdR = 0;
                a.DataR= Data[15:8];
                Len[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_len2;
            end
Read_len2 :	begin	
                a.CmdR = 0;
                a.DataR= Data[23:16];
                Len[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_len3;
			end
Read_len3 : begin
              a.CmdR = 0;
                a.DataR= Data[ 31 :  24 ] ;
                Len[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_len4;
			end
Read_len4 : begin	
                Len[ 31 :  24 ] =	a.DataW;
                a.CmdR = 0;
                if(Len >=32'h80)
                count_crc = 8'h80;
                else 
                count_crc = Len;
                a.DataR= count_crc;
				nextstate4 =	Read_Result1;
			end
Read_Result1  : begin 
                a.CmdR = 1;
                a.DataR= 0;
                Result[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_Result2;
            end
Read_Result2 :	begin	Result[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_Result3;
			end
Read_Result3 : begin	Result[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_Result4;
			end
Read_Result4 : begin	Result[ 31 :  24 ] =	a.DataW;
				nextstate4 =	Read_Msg1;
			end 
Read_Msg1  : begin 
                Message[ 7 : 0 ]	 =	a.DataW;
				nextstate4 =	Read_Msg2;
            end
Read_Msg2 :	begin	Message[ 15 : 8 ]  =	a.DataW;
				nextstate4 =	Read_Msg3;
			end
Read_Msg3 : begin Message[ 23 :  16 ] =	a.DataW;
				nextstate4 =	Read_Msg4;
			end
Read_Msg4 : begin	Message[ 31 :  24 ] =	a.DataW;
				nextstate4 =	crc;
			end 
crc :       begin
                if(a.CmdW==1)// Read response started then proceed
                    if(a.DataW==8'h40)
                    nextstate4 = crc_blank;
            end 
crc_blank : begin
            nextstate4 = crc_blank2;
            end 
crc_blank2 : begin
                nextstate4 = crc_data1;
                end 
crc_data1 :	begin	crc_data[ 7 : 0 ]	 =	data;
				nextstate4 =	crc_data2;
			end
crc_data2 :	begin	crc_data[ 15 : 8 ]  =	data;
				nextstate4 =	crc_data3;
			end
crc_data3 : begin	crc_data[ 23 :  16 ] =	data;
				nextstate4 =	crc_data4;
			end
crc_data4 : begin	crc_data[  31 :  24 ]	=	data;
                    //nextstate4=lazy4;
                    b.Sel= 1;
                    b.RW=1;
                    b.addr=32'h4003_2000;
                    b.data_wr= crc_data;
                    Len = lenf- 4;
                    count_crc = count_crcf-32'h4;
                    if(Len !=0)
                    begin
                        if(count_crc != 0)
                            begin
                                //b.Sel=1;
                                //b.RW=0;
                                nextstate4 =  crc_data1;
                            end
                        else if (count_crc==0)
                            nextstate4 = send_add1; //send data pointer again 
                    end 
                    else if(Len==0)
                    //  else
                      begin
                        //b.Sel=1;
                        //b.RW=0;
                        //crc_res = b.data_rd;
                        nextstate4 = read_crc_res;  //send result 
                        end 
                    //end
            end 
send_add1 : begin
                a.CmdR=1;
                a.DataR=8'h23;
                nextstate4= send_add2;
            end 
send_add2 : begin
                a.CmdR = 0;
                a.DataR=8'hcd;
                Data = Dataf+8'h80;
                nextstate4= send_add3;
            end 
send_add3 : begin
                a.CmdR = 0;
                a.DataR= Data[7:0];
                nextstate4 = send_add4;
            end 
send_add4 : begin
                a.CmdR = 0;
                a.DataR= Data[15:8];
                nextstate4 = send_add5;
            end 
send_add5 : begin
                a.CmdR = 0;
                a.DataR= Data[23:16];
                nextstate4 = send_add6;
            end 
send_add6 : begin
                a.CmdR = 0;
                a.DataR= Data[31:24];
                nextstate4 = send_add7;
            end 
send_add7 : begin
                if(Len >= 8'h80)
                count_crc= 8'h80;
                else 
                count_crc= Len;
                a.CmdR = 0;
                a.DataR= count_crc;
                nextstate4 = crc_blank;
            end 
read_crc_res : begin
                b.Sel=1;
                b.RW=0;
                crc_res = b.data_rd;
                nextstate4 = send_res1;
                end 
send_res1 : begin
                a.CmdR = 1;
                a.DataR= 8'h63;
                nextstate4 = send_res2;
            end 
send_res2 : begin
                a.CmdR = 0;
                a.DataR= 8'hfc;
                nextstate4 = send_res3;
            end 
            
send_res3 : begin
                a.CmdR = 0;
                a.DataR= Result[7:0];//8'h17;
                nextstate4 = send_res4;
            end 

send_res4 : begin
                a.CmdR = 0;
                a.DataR= Result[15:8];
                nextstate4 = send_res5;
            end 
send_res5 : begin
                a.CmdR = 0;
                a.DataR= Result[23:16];                   //set the result address
                nextstate4 = send_res6;
            end 

send_res6 : begin
                a.CmdR=0;
                a.DataR=Result[31:24];
                nextstate4 = send_res11;
            end 
send_res11 : begin
                a.CmdR = 0;
                a.DataR=8'h04;
                nextstate4 = send_res7;
            end
send_res7 : begin
                a.CmdR = 0;
                a.DataR=crc_res[7:0];
                nextstate4 = send_res8;
            end            
send_res8 : begin
                a.CmdR = 0;
                a.DataR=crc_res[15:8];
                nextstate4 = send_res9;
            end 
send_res9 : begin
                a.CmdR = 0;
                a.DataR=crc_res[23:16];
                nextstate4 = send_res10;
            end 
send_res10 : begin
                a.CmdR = 0;
                a.DataR=crc_res[31:24];
                //chain = Link;
                nextstate4 = send_msg;
            end 
send_msg : begin 
            a.CmdR = 1;
                a.DataR= 8'hc4;
                nextstate4 = send_msg1;
            end 
 send_msg1 : begin
                a.CmdR = 0;
                a.DataR=Message[7:0];
                nextstate4 = send_msg2;
            end            
send_msg2 : begin
                a.CmdR = 0;
                a.DataR=Message[15:8];
                nextstate4 = send_msg3;
            end 
send_msg3 : begin
                a.CmdR = 0;
                a.DataR=Message[23:16];
                nextstate4 = send_msg4;
            end 
send_msg4 : begin
                a.CmdR = 0;
                a.DataR=Message[31:24];
                //chain = Link;
                nextstate4 = lazy4;
            end 



endcase


end
end
endmodule		
