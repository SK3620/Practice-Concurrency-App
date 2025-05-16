//: [Previous](@previous)

import Foundation

final class Box: @unchecked Sendable {
    var value: Int = 0
}

struct Box2: @unchecked Sendable {
    var value: Int = 0
}

// 実行時、MainActorではない時はクラッシュさせる
MainActor.assertIsolated()


func run() {
    let box = Box()
    var box2 = Box2()
    
    print(Thread.isMainThread) // true
    
    // 以下、それぞれのTaskが立ち上がる
    
     // コンパイルエラー（（Value of non-Sendable type '@isolated(any) @async @callee_guaranteed @substituted <τ_0_0> () -> @out τ_0_0 for <()>' accessed after being transferred; later accesses could race））
    
    /* // コンパイルエラー
    Task { // バックグラウンドスレッドA
        // print(Thread.isMainThread) // false
        // box.value = -1
        
         box2.value = -1
    }
     */

    Task { // バックグラウンドスレッドB
        // print(Thread.isMainThread) // false
        print(box.value)
        
        print(box2.value)
    }
}

run()

// それぞれのTask（スレッド）が立ち上がるため、同時（並行）に実行される可能性がある
// 書き込みと読み取りが同時に行われる可能性がある → データ競合起こるかも！
