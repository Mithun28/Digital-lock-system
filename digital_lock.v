// 4-to-2 Encoder
module encoder_4to2(input [3:0] data_in, output reg [1:0] encoded_out);
  always @(*) begin
    case (data_in)
      4'b0001: encoded_out = 2'b00;
      4'b0010: encoded_out = 2'b01;
      4'b0100: encoded_out = 2'b10;
      4'b1000: encoded_out = 2'b11;
      default: encoded_out = 2'b00;  // Default case
    endcase
  end
endmodule

// 4-Bit Shift Register
module shift_register(input clk, input reset, input [1:0] data_in, output reg [7:0] q);
  always @(posedge clk or posedge reset) begin
    if (reset)
      q <= 8'b00000000;
    else
      q <= {q[5:0], data_in};  // Shift in 2-bit input
  end
endmodule

// 2-to-1 Multiplexer
module mux_2to1(input [7:0] pin_stored, input [7:0] pin_entered, input sel, output [7:0] mux_out);
  assign mux_out = (sel) ? pin_entered : pin_stored;
endmodule

// Comparator: Compare stored pin and entered pin
module comparator(input [7:0] pin_stored, input [7:0] mux_out, output reg lock_open);
  always @(*) begin
    if (pin_stored == mux_out)
      lock_open = 1;  // Lock opens if pins match
    else
      lock_open = 0;  // Lock remains closed if pins don't match
  end
endmodule

// Top Module - Digital Lock System
module digital_lock_system(input clk, input reset, input [3:0] user_input, input sel, output lock_open);
  wire [1:0] encoded_pin;
  wire [7:0] shifted_pin, stored_pin, mux_out;

  // Stored PIN for matching (preset stored PIN)
  assign stored_pin = 8'b00011011;  // Example stored PIN (00, 01, 10, 11)

  // Instantiate encoder, shift register, mux, and comparator
  encoder_4to2 enc (.data_in(user_input), .encoded_out(encoded_pin));
  shift_register shift (.clk(clk), .reset(reset), .data_in(encoded_pin), .q(shifted_pin));
  mux_2to1 mux (.pin_stored(stored_pin), .pin_entered(shifted_pin), .sel(sel), .mux_out(mux_out));
  comparator comp (.pin_stored(stored_pin), .mux_out(mux_out), .lock_open(lock_open));

endmodule

// Testbench
module tb_digital_lock_system;
  reg clk;
  reg reset;
  reg [3:0] user_input;
  reg sel;
  wire lock_open;

  // Instantiate the Digital Lock System
  digital_lock_system dut (.clk(clk), .reset(reset), .user_input(user_input), .sel(sel), .lock_open(lock_open));

  // Clock generation
  always #5 clk = ~clk;  // Clock with a period of 10 time units

  // Test Sequence
  initial begin
    // Initialize inputs
    clk = 0;
    reset = 1;
    sel = 0;
    user_input = 4'b0000;

    // Reset the system
    #10 reset = 0;
    #10 reset = 1;

    // Enter correct PIN step by step (PIN = 00, 01, 10, 11)
    #10 user_input = 4'b0001; // Enter first digit (00)
    #10 user_input = 4'b0010; // Enter second digit (01)
    #10 user_input = 4'b0100; // Enter third digit (10)
    #10 user_input = 4'b1000; // Enter fourth digit (11)

    // Set selector to compare entered PIN with stored PIN
    sel = 1;
    #10;

    // Display the result
    if (lock_open)
      $display("Lock Opened: Correct PIN Entered.");
    else
      $display("Lock Closed: Incorrect PIN Entered.");

    // Test for incorrect PIN
    reset = 0;
    sel = 0;
    #10 reset = 1;
    #10 user_input = 4'b1000; // Enter wrong digit
    #10 user_input = 4'b0001;
    #10 user_input = 4'b0100;
    #10 user_input = 4'b0010;

    // Set selector to compare again
    #10 sel = 1;
    #10;

    // Display the result
    if (lock_open)
      $display("Lock Opened: Correct PIN Entered.");
    else
      $display("Lock Closed: Incorrect PIN Entered.");

    // End simulation
    #10 $finish;
  end
endmodule

