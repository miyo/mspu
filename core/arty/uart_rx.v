//
//  UART_RX
//  シリアル通信 受信モジュール
//  スタートビット(0), 8bitデータ(LSBからMSBの順に), ストップビット(1)の順に受信
//

// おまじない(宣言されてない信号の型を none に)
`default_nettype none

module uart_rx
  #( // 定数宣言
     parameter sys_clk = 27000000, // クロック周波数
     parameter rate    = 19200     // 転送レート,単位はbps(ビット毎秒)
     )
   ( // 入出力ポート宣言
     input wire      clk, // クロック
     input wire      reset, // リセット
     input wire      din, // シリアル入力
     output reg      rd, // 受信完了を示す
     output reg [7:0] dout // 受信データ
     );

   // 内部変数宣言
   reg [7:0] tmp_buf;   // 受信データ系列の一時保存用レジスタ
   reg 	     receiving; // 受信しているかどうか
   reg [7:0] cbit;      // カウンタ,データを取り込むタイミングを決定するのに使用
   wire	     rx_en;     // 受信用クロック
   reg 	     rx_en_d;   // 受信用クロック立ち上がり判定用レジスタ
   
   wire [31:0] rx_div;   // クロック分周の倍率

   // クロック分周モジュールのインスタンス生成
   // 受信側は送信側の16倍の速度で値を取り込み処理を行う
   assign rx_div = ((sys_clk / rate) / 16) - 1;
   clk_div clk_div_i(.clk(clk), .rst(reset), .div(rx_div), .clk_out(rx_en));

   always @(posedge clk) begin // 動作を開始するトリガを指定．この場合クロックの立ち上がり．
      if(reset == 1) begin // リセット時の動作, 初期値の設定
         receiving <= 0;
         cbit      <= 0;
         tmp_buf   <= 0;
         dout      <= 0;
         rd        <= 0;
         rx_en_d   <= 0;
      end else begin
         rx_en_d <= rx_en;
         if(rx_en == 1 && rx_en_d == 0) begin // 受信用クロック立ち上がり時の動作
            if(receiving == 0) begin // 受信中でない場合
               if(din == 0) begin // スタートビット0を受信したら
		  rd <= 0; // 受信完了のフラグをさげる
		  receiving <= 1; // 受信中のフラグをたてる
               end
            end else begin // 受信中の場合
              case(cbit) // カウンタに合わせてデータをラッチ
		6: begin // スタートビットのチェック
                   if(din == 1) begin // スタートビットが中途半端．入力をキャンセル
                      receiving <= 0;
                      cbit      <= 0;
                   end else begin
                      cbit <= cbit + 1;
                   end
		end
		
		22, 38, 54, 70, 86, 102, 118, 134: begin // data
                   cbit <= cbit + 1;
                   tmp_buf <= {din, tmp_buf[7:1]}; // シリアル入力と既に受信したデータを連結
		end
		
		150: begin // stop
                   rd <= 1;
                   dout <= tmp_buf;
                   receiving <= 0; // 受信完了
                   cbit <= 0;
		end

		default: begin
                   cbit <= cbit + 1;
		end
		
              endcase // case (cbit)
            end // else: !if(receiving == 0)
         end // if (rx_en == 1 && rx_en_d == 0)
      end // else: !if(reset == 1)
   end // always @ (posedge clk)
   
endmodule // uart_rx

// おまじない(宣言されてない信号の型を wire に)
`default_nettype wire

