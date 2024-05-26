`timescale 1ns / 1ps


module top(
    input button0,
    input button1,
    output led0,
    output led1
    );
    
    or ( led0, button0, button1 );
    and ( led1, button0, button1 );
    
endmodule
