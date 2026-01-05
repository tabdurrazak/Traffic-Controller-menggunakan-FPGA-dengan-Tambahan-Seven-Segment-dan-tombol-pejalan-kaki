module traffic_mealy #(
    parameter integer CLK_HZ      = 50_000_000,
    parameter integer T_GREEN     = 9,   // detik green
    parameter integer T_RED       = 9,   // detik red
    parameter integer T_YELLOW    = 2,   // detik yellow
    parameter integer T_PED_WALK  = 6    // durasi WALK saat kendaraan red
)(
    input  wire       clk,
    input  wire       rst_n,

    input  wire       ped_btn,     // tombol pedestrian (asinkron)

    output reg        led_r,
    output reg        led_y,
    output reg        led_g,
    output reg        ped_walk,    // indikator WALK

    output wire [6:0] seg,         // abcdefg (aktif-low)
    output wire [3:0] an
);

    // ==========================================================
    // 1) Tick 1 detik
    // ==========================================================
    reg  [31:0] div_cnt;
    reg         tick_1s;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 32'd0;
            tick_1s <= 1'b0;
        end else begin
            if (div_cnt == (CLK_HZ - 1)) begin
                div_cnt <= 32'd0;
                tick_1s <= 1'b1;
            end else begin
                div_cnt <= div_cnt + 32'd1;
                tick_1s <= 1'b0;
            end
        end
    end

    // ==========================================================
    // 2) Sinkronisasi tombol + edge detect (rising edge)
    // ==========================================================
    reg  ped_ff1, ped_ff2, ped_ff2_d;
    wire ped_rise;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_ff1   <= 1'b0;
            ped_ff2   <= 1'b0;
            ped_ff2_d <= 1'b0;
        end else begin
            ped_ff1   <= ped_btn;
            ped_ff2   <= ped_ff1;
            ped_ff2_d <= ped_ff2;
        end
    end

    assign ped_rise = ped_ff2 & ~ped_ff2_d;

    // ==========================================================
    // 3) Latch request pedestrian
    // ==========================================================
    reg ped_req;

    // ==========================================================
    // 4) FSM State
    // ==========================================================
    localparam [2:0] S_GREEN = 3'd0;
    localparam [2:0] S_Y_G2R = 3'd1;
    localparam [2:0] S_RED   = 3'd2;
    localparam [2:0] S_Y_R2G = 3'd3;
    localparam [2:0] S_PED   = 3'd4;

    reg  [2:0] state, next_state;

    // Countdown detik
    reg  [7:0] seconds_left;
    wire       timer_done = (seconds_left == 8'd0);

    function [7:0] duration_for_state;
        input [2:0] st;
        input       ped_req_i;
        begin
            case (st)
                S_GREEN: duration_for_state = T_GREEN[7:0];
                S_Y_G2R: duration_for_state = T_YELLOW[7:0];
                S_RED:   duration_for_state = T_RED[7:0];
                S_Y_R2G: duration_for_state = T_YELLOW[7:0];
                S_PED:   duration_for_state = (ped_req_i) ? T_PED_WALK[7:0] : 8'd0;
                default: duration_for_state = T_RED[7:0];
            endcase
        end
    endfunction

    // ==========================================================
    // 5) Next-state logic (Mealy)
    // ==========================================================
    always @(*) begin
        next_state = state;

        case (state)
            S_GREEN: begin
                if (timer_done || ped_req)
                    next_state = S_Y_G2R;
            end

            S_Y_G2R: begin
                if (timer_done)
                    next_state = S_RED;
            end

            S_RED: begin
                if (ped_req)
                    next_state = S_PED;
                else if (timer_done)
                    next_state = S_Y_R2G;
            end

            S_PED: begin
                if (timer_done)
                    next_state = S_Y_R2G;
            end

            S_Y_R2G: begin
                if (timer_done)
                    next_state = S_GREEN;
            end

            default: begin
                next_state = S_RED;
            end
        endcase
    end

    // ==========================================================
    // 6) State register + timer handling
    // ==========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_RED;
            seconds_left <= duration_for_state(S_RED, 1'b0);
            ped_req      <= 1'b0;
        end else begin
            // latch request
            if (ped_rise)
                ped_req <= 1'b1;

            // state transition
            if (state != next_state) begin
                // clear ped_req setelah selesai fase pedestrian
                if ((state == S_PED) && (next_state == S_Y_R2G))
                    ped_req <= 1'b0;

                state        <= next_state;
                seconds_left <= duration_for_state(next_state, ped_req);
            end else begin
                // countdown
                if (tick_1s) begin
                    if (seconds_left != 8'd0)
                        seconds_left <= seconds_left - 8'd1;
                end
            end
        end
    end

    // ==========================================================
    // 7) Output LED (Moore)
    // ==========================================================
    always @(*) begin
        led_r    = 1'b0;
        led_y    = 1'b0;
        led_g    = 1'b0;
        ped_walk = 1'b0;

        case (state)
            S_GREEN: begin
                led_g = 1'b1;
            end

            S_Y_G2R,
            S_Y_R2G: begin
                led_y = 1'b1;
            end

            S_RED: begin
                led_r = 1'b1;
            end

            S_PED: begin
                led_r    = 1'b1;
                ped_walk = 1'b1;
            end

            default: begin
                led_r = 1'b1;
            end
        endcase
    end

    // ==========================================================
    // 8) 7-seg countdown (ONLY saat GREEN dan RED)
    //    - saat YELLOW/PED: BLANK
    //    - seg output aktif-low
    // ==========================================================
    wire       show_timer = (state == S_GREEN) || (state == S_RED);
    wire [3:0] digit      = seconds_left % 10;

    wire [6:0] seg_active_low;

    sevenseg_1digit_active_low u7 (
        .bin   (digit),
        .blank (~show_timer),
        .seg   (seg_active_low)
    );

    assign seg = seg_active_low;
    assign an  = 4'b1110;

endmodule
