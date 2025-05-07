/*
 Isolation Domain

 ・MainActor 領域
 ・actor class 領域（生成されたクラスのインスタインごとに actor 領域を持つ）
 
 それぞれの actor は、一つの Isolation Domain の中では、同時に一つの処理しか実行されない
 */

/*
 Isolation boundry （境界線）
 
 それぞれのactor領域の間には、境界線がある

 ・MainActor 領域
 ・actor a
 ・actor b
 
 それぞれの Actor の中で管理されているSendableに準拠したデータのみが、境界線を超えて、actorから別のactorへ移動できる
 複数の Isolation Domain から並行にアクセスされても大丈夫！
 
 逆に non-sendable なデータは境界線を越えられない
 複数の Isolation Domain から並行にアクセスは危険！ → Swift6がコンパイルエラーで知らせてくれる！
 また、non-sendable なデータはその actor 領域内にとどまっているため、他の Actor 領域から並行にアクセスされることはない
 */

/*
 Sendable
 
 並行にアクセスされても安全な型だけが準拠できるプロトコル
 */
