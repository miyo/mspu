//
//  UART_TX
//  シリアル通信送信モジュール
//  スタートビット(0), 8bitデータ(LSBからMSBの順に), ストップビット(1)の順に送信
//

// おまじない(宣言されてない信号の型を none に)
`default_nettype none

module uart_tx
  #( // 定数宣言
     parameter sys_clk = 27000000, // クロック周波数
     parameter rate    = 19200     // 転送レート,単位はbps(ビット毎秒)
     )
   ( // 入出力ポート宣言
     input wire       clk, // クロック
     input wire       reset, // リセット
     input wire       wr, // 送信要求
     input wire [7:0] din, // 送信データ
     output reg       dout, // シリアル出力
     output wire      ready // 送信要求を受け付けることができるかどうか
     );

   // 内部変数定義
   reg [7:0] in_din;  // 送信データ一時保存用レジスタ
   reg [7:0] tmp_buf; // 一時的にしようするバッファ
   reg 	     load;    // 送信データを読み込んだかどうか
   reg [2:0] cbit;    // 何ビット目を送信しているか
   reg 	     run;     // 送信状態にあるかどうか

   wire      tx_en;   // 送信用クロック
   reg 	     tx_en_d; // 送信用クロックの立ち上がり検出用
  
   wire [31:0] tx_div; // クロック分周の倍率

   reg [1:0]  status; // 状態遷移用レジスタ

   // クロック分周モジュールの呼び出し
   // clk_divの入出力ポートにこのモジュールの内部変数を接続
   assign tx_div = (sys_clk / rate) - 1;
   clk_div clk_div_i(.clk(clk), .rst(reset), .div(tx_div), .clk_out(tx_en));
   // readyへの代入, 常時値を更新している
   assign ready = (wr == 0 && run == 0 && load == 0) ? 1'b1 : 1'b0;

   always @(posedge clk) begin // 動作を開始するトリガを指定．この場合クロックの立ち上がり．
      if(reset == 1) begin // リセット時の動作, 初期値の設定
         load <= 0;
      end else begin
         if(wr == 1 && run == 0) begin // 送信要求があり，かつ送信中でない場合
            load <= 1;                 // ユーザから送信リクエストがあったことを示すフラグを立てる
            in_din <= din;             // 一時保存用レジスタに値を格納
         end
         if(load == 1 && run == 1) begin // 送信中で，かつデータを取り込んだ
                                         // ことを示すフラグが立っている場合
            load <= 0;                   // データを取り込んだことを示すフラグを下げる
         end
      end
   end

   always @(posedge clk) begin // 動作を開始するトリガを指定．この場合クロックの立ち上がり．
      if(reset == 1) begin // リセット時の動作, 初期値の設定
         dout    <= 1;
         cbit    <= 0;
         status  <= 0;
         run     <= 0;
         tx_en_d <= 0;
      end else begin
         tx_en_d <= tx_en;
         if(tx_en == 1 && tx_en_d == 0) begin // tx_enの立ち上がりで動作
            case(status) // statusの値に応じて動作が異なる
              0: begin // 初期状態
		 cbit <= 0; // カウンタをクリア
		 if(load == 1) begin // データを取り込んでいる場合
                    dout <= 0; // スタートビット0を出力
                    status <= status + 1; // 次の状態へ
                    tmp_buf <= in_din;    // 送信データを一時バッファに退避
                    run <= 1; // 送信中の状態へ遷移
		 end else begin // なにもしない状態へ遷移
                    dout <= 1;
                    run <= 0; // 送信要求受付可能状態にセット
		 end
	      end // case: 0
	      
              1: begin // データをLSBから順番に送信
		 dout <= tmp_buf[0]; // 一時バッファの0番目を出力
		 tmp_buf <= {1'b0, tmp_buf[7:1]}; // 次の出力のためにデータをシフト
		 cbit <= cbit + 1; // カウンタをインクリメント
		 if(cbit == 7) begin // データの8ビット目を送信したら,
                                     // ストップビットを送る状態へ遷移
                    status <= status + 1;
		 end
	      end
	      
              2: begin // ストップビットを送信
		 dout <= 1; // ストップビット1
		 status <= 0; // 初期状態へ
	      end
	      
	      default: begin // その他の状態の場合
		 status <= 0; // 初期状態へ遷移
	      end
	      
            endcase // case (status)
         end // if (tx_en == 1 && tx_en_d == 0)
      end // else: !if(reset == 1)
   end // always @ (posedge clk)

endmodule // uart_tx

// おまじない(宣言されてない信号の型を wire に)
`default_nettype wire
