//-----------------------------------------------------------------------------
//  
//  Copyright (c) 2009 Xilinx Inc.
//
//  Project  : Programmable Wave Generator
//  Module   : tb_wave_gen.v
//  Parent   : Testcase
//  Children : Lots
//
//  Description: 
//    This is the top level module for the testbench for the wave_gen module.
//
//  Parameters: 
//
//  Tasks:
//
//  Internal variables:
//
//  Notes       : 
//    
//
//  Multicycle and False Paths
//    None - this is a testbench file only, and is not intended for synthesis
//

// All times in this testbench are expressed in units of nanoseconds, with a 
// precision of 1ps increments
`timescale 1ns/1ps


module tb_wave_gen (); 

//***************************************************************************
// Parameter definitions
//***************************************************************************
  parameter FIFO_DEPTH=256;
  
  parameter CLOCK_RATE = 27_000_000;

  parameter PERIOD = 1_000_000_000.0 / CLOCK_RATE; // Clock period

  parameter BAUD_RATE = 115_200;



//***************************************************************************
// Register declarations
//***************************************************************************
  
  reg               clk_pin = 1'b0;
  wire              rst_pin;

  wire              rxd_pin;
  wire              txd_pin;

  wire [7:0]        char;
  wire              char_val;
  wire              frm_err;

//***************************************************************************
// Tasks
//***************************************************************************

  task init ();
    reg ret_code;
  begin
    // Initialize the sample and variable RAMs
    tb_samp_ram_i0.init();
    tb_var_ram_i0.init();

    // Set the min and max in the variable RAM
    tb_var_ram_i0.set_min_max(0,1,1024);    // NSAMP
    tb_var_ram_i0.set_min_max(1,32,65535);  // PRESCALE
    tb_var_ram_i0.set_min_max(2,1,65535);   // SPEED
    
    // Set the reset values in the variable RAM
    ret_code = tb_var_ram_i0.write(0,1);    // NSAMP
    ret_code = tb_var_ram_i0.write(1,32);   // PRESCALE
    ret_code = tb_var_ram_i0.write(2,1);    // SPEED

    // Assert the reset for 20 clocks
    tb_resetgen_i0.assert_reset(20);

    // Enable the uart monitor
    tb_uart_monitor_i0.start;

    // Enable the data checker
    tb_resp_checker_i0.enable(1'b1);
  end
  endtask


//***************************************************************************
// Code
//***************************************************************************

  // Generate the clock
  initial
  begin
    clk_pin = 0;
    forever
    begin
      #(PERIOD/2.0) clk_pin = ~clk_pin;
    end // forever
  end // initial

  // Instantiate the reset generator
  
  tb_resetgen tb_resetgen_i0 (
    .clk      (clk_pin),
    .reset    (rst_pin)
  );

  // Instantiate the character fifo

  tb_fifo #(
    .WIDTH(8),
    .DEPTH(FIFO_DEPTH)
  ) tb_char_fifo_i0 ();

  // Instantiate the sample RAM
  tb_ram #(
    .WIDTH (16),
    .DEPTH (1024)
  ) tb_samp_ram_i0 ();

  // Instantiate the variable RAM
  tb_ram #(
    .WIDTH (16),
    .DEPTH (3)
  ) tb_var_ram_i0 ();


  // Instantiate the UART driver
  tb_uart_driver #(
    .BAUD_RATE (BAUD_RATE)   // This is only the DEFAULT baud rate
  ) tb_uart_driver_i0 (
    .data_out (rxd_pin)
  );

  // Instantiate the UART monitor
  tb_uart_monitor #(
    .BAUD_RATE (BAUD_RATE)
  ) tb_uart_monitor_i0 (
    .data_in    (txd_pin),
    .char       (char),
    .char_val   (char_val)
  );

  // Instantiate the command generator
  tb_cmd_gen tb_cmd_gen_i0 ();

  // Instantiate the data checker
  tb_resp_checker tb_resp_checker_i0 (
    .strobe      (char_val),
    .frm_err     (1'b0), // Unused in this testbench
    .data_in     (char)
  );


  wave_gen wave_gen_i0 (
    .clk_pin         (clk_pin),
    .rst_pin         (rst_pin),

    .rxd_pin         (rxd_pin),
    .txd_pin         (txd_pin),

    .lb_sel_pin      (1'b0),    // Don't enable loopback


    .spi_clk_pin     (),        // TBD
    .spi_mosi_pin    (),        // TBD
    .dac_cs_n_pin    ()         // TBD

  );
  


endmodule

