`timescale 1ns/1ps

module tb_traffic_mealy;

  // =========================
  // Clock & Reset
  // =========================
  reg clk;
  reg rst_n;

  // tombol pedestrian (asinkron)
  reg ped_btn;

  // outputs
  wire led_r, led_y, led_g, ped_walk;
  wire [6:0] seg;
  wire [3:0] an;

  // =========================
  // Parameter diperkecil untuk simulasi cepat
  // tick_1s terjadi setiap CLK_HZ cycle
  // =========================
  localparam integer CLK_HZ_TB     = 10; // 10 cycle = 1 detik (simulasi)
  localparam integer T_GREEN_TB    = 4;
  localparam integer T_RED_TB      = 4;
  localparam integer T_YELLOW_TB   = 2;
  localparam integer T_PED_WALK_TB = 3;

  // =========================
  // DUT
  // =========================
  traffic_mealy #(
    .CLK_HZ(CLK_HZ_TB),
    .T_GREEN(T_GREEN_TB),
    .T_RED(T_RED_TB),
    .T_YELLOW(T_YELLOW_TB),
    .T_PED_WALK(T_PED_WALK_TB)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .ped_btn(ped_btn),
    .led_r(led_r),
    .led_y(led_y),
    .led_g(led_g),
    .ped_walk(ped_walk),
    .seg(seg),
    .an(an)
  );

  // =========================
  // Clock generator: 100MHz (10ns period)
  // =========================
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // =========================
  // Helper: tunggu N "detik" versi DUT
  // 1 detik = CLK_HZ_TB clock cycles
  // =========================
  task wait_seconds(input integer n);
    integer i;
    begin
      for (i = 0; i < n; i = i + 1) begin
        repeat (CLK_HZ_TB) @(posedge clk);
      end
    end
  endtask

  // Helper: pulse tombol asinkron (tidak sejajar clock)
  task ped_pulse_async(input integer high_ns);
    begin
      // buat tidak align dengan posedge
      #7;
      ped_btn = 1'b1;
      #(high_ns);
      ped_btn = 1'b0;
    end
  endtask

  // =========================
  // Monitor & Debug
  // =========================
  // Decode state internal (optional, buat membaca log)
  function [127:0] st_name(input [2:0] st);
    begin
      case (st)
        3'd0: st_name = "S_GREEN";
        3'd1: st_name = "S_Y_G2R";
        3'd2: st_name = "S_RED";
        3'd3: st_name = "S_Y_R2G";
        3'd4: st_name = "S_PED";
        default: st_name = "S_???";
      endcase
    end
  endfunction

  // cek basic exclusivity lampu (minimal sanity)
  always @(posedge clk) begin
    if (rst_n) begin
      if ((led_r + led_y + led_g) == 0) begin
        $display("[%0t] WARNING: semua lampu mati (R/Y/G semuanya 0)", $time);
      end
      if ((led_r + led_y + led_g) > 1) begin
        $display("[%0t] WARNING: lebih dari 1 lampu nyala bersamaan! R=%0b Y=%0b G=%0b",
                 $time, led_r, led_y, led_g);
      end
      // ped_walk hanya boleh saat red nyala (sesuai desain output)
      if (ped_walk && !led_r) begin
        $display("[%0t] ERROR: ped_walk nyala tapi led_r tidak nyala!", $time);
        $stop;
      end
    end
  end

  // log perubahan state (pakai hierarchical reference)
  reg [2:0] st_prev;
  initial st_prev = 3'b111;

  always @(posedge clk) begin
    if (!rst_n) begin
      st_prev <= 3'b111;
    end else begin
      if (dut.state !== st_prev) begin
        $display("[%0t] STATE: %s -> %s | sec_left=%0d | ped_req=%0b | (R,Y,G,P)=(%0b,%0b,%0b,%0b)",
                 $time, st_name(st_prev), st_name(dut.state),
                 dut.seconds_left, dut.ped_req, led_r, led_y, led_g, ped_walk);
        st_prev <= dut.state;
      end
    end
  end

  // =========================
  // Test scenarios
  // =========================
  initial begin
    // init
    rst_n   = 1'b0;
    ped_btn = 1'b0;

    // waveform dump
    $dumpfile("tb_traffic_mealy.vcd");
    $dumpvars(0, tb_traffic_mealy);

    // tahan reset beberapa cycle
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    $display("[%0t] Release reset", $time);

    // === Skenario 1: Biarkan berjalan normal beberapa detik ===
    wait_seconds(2);

    // === Skenario 2: Tekan pedestrian saat kemungkinan GREEN (memotong green) ===
    // tunggu sampai benar-benar GREEN dulu (biar tidak tebak-tebakan)
    wait_until_state(3'd0); // S_GREEN
    $display("[%0t] ACTION: ped press during GREEN", $time);
    ped_pulse_async(30); // 30ns high (asinkron)

    // tunggu sampai sistem melayani (masuk S_PED sekali)
    wait_until_state(3'd4); // S_PED
    wait_seconds(1);

    // === Skenario 3: Tekan pedestrian saat RED (harus masuk S_PED tanpa nunggu red habis) ===
    wait_until_state(3'd2); // S_RED
    $display("[%0t] ACTION: ped press during RED", $time);
    ped_pulse_async(20);

    wait_until_state(3'd4); // S_PED
    wait_seconds(1);

    // === Skenario 4: Spam/bounce-ish: beberapa pulse cepat ===
    wait_until_state(3'd0); // GREEN
    $display("[%0t] ACTION: bounce-like presses", $time);
    ped_pulse_async(10);
    ped_pulse_async(10);
    ped_pulse_async(10);

    // jalanin beberapa siklus lagi
    wait_seconds(10);

    $display("[%0t] TEST DONE", $time);
    $finish;
  end

  // =========================
  // Utility: wait until DUT reaches a specific state
  // =========================
  task wait_until_state(input [2:0] target);
    begin
      while (dut.state !== target) begin
        @(posedge clk);
      end
    end
  endtask

endmodule
