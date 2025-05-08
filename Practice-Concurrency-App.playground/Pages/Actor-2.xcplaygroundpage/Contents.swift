import Foundation

final class Box {
    var value: Int = 0
}

// コンパイルエラー（Stored property 'value' of 'Sendable'-conforming class 'Box' is mutable）
// 可変状態な var value のようなデータを持つ class は同時にアクセスされたらデータ競合の可能性ありとコンパイラーが判断！
/*
final class Box: Sendable {
    var value: Int = 0
}
 */

// let の場合は、そもそも読み取り"のみ"可能
// よって、安全のため、コンパイルが通る
/*
final class Box: Sendable {
    let value: Int = 0
}
 */

/*
// @unchecked Sendable → 開発者自身がこのクラスはSendableであることを決めれる
// これはあまり好ましくない いわば、本当に必要な時に限る最後の手段
final class Box1: @unchecked Sendable {
    var value: Int = 0
}
 */

// 実行時、MainActorではない時はクラッシュさせる
MainActor.assertIsolated()


func run() {
    let box = Box()
    
    print(Thread.isMainThread) // true
    
    // 以下、それぞれのTaskが立ち上がる
    
    /*
     // コンパイルエラー（（Value of non-Sendable type '@isolated(any) @async @callee_guaranteed @substituted <τ_0_0> () -> @out τ_0_0 for <()>' accessed after being transferred; later accesses could race））
    Task { // バックグラウンドスレッドA
        // print(Thread.isMainThread) // false
        box.value = -1
    }

    Task { // バックグラウンドスレッドB
        // print(Thread.isMainThread) // false
        print(box.value)
    }
     */
}

run()

// それぞれのTask（スレッド）が立ち上がるため、同時（並行）に実行される可能性がある
// 書き込みと読み取りが同時に行われる可能性がある → データ競合起こるかも！
