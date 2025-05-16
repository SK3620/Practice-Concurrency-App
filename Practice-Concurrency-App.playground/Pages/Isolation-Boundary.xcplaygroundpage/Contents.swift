import Foundation

/* コンパイルエラーを回避できる
final class Box: @unchecked Sendable {
    var value: Int = 0
}
 */

final class Box {
    var value: Int = 0
}

actor A {
    var box: Box?
    func setBox(_ box: Box) {
        self.box = box
    }
}

func run1() async {
    let box = Box()
    let a: A = .init() // A の Isolation Domain
    
    //  A の Isolation Domain に Box を渡そうしている
    // すなわち、Box は A の Isolation Boundary を越えようとしている
    // しかし、Box は Sendable でないため、コンパイルエラー発生！
    // そもそも Box は class で class は Sendable に準拠していない（しない方が良い？）
    
    /* // コンパイルエラー
    await a.setBox(box) // Non-Sendable なデータが Isolation Boundary を越えようとしているよ！
     */
    
    // 値を読み込む
    print(box.value)
    
    /*
     仮に、actor A の isolation Domain の setBox(){} の中で box の値を書き換えるような処理をしている場合、且つ、外側から print(box.value) のように、値を読み込んでいる場合、それらは並行に行われ、データ競合が起きる可能性があるとして、コンパイルエラーを出してくれる
     */
}

func run2() {
    let box = Box()
    
    /*
    Task { // バックグラウンドスレッドA
        box.value = -1
    }

    Task { // バックグラウンドスレッドB
        print(box.value)
    }
     */
}

await run1()
run2()
