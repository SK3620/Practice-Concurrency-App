import Foundation

/*
 どうやって、Task Isolation Domain は、別の Isolation Domain から来たデータが、並行に同時アクセスされても安全性があるかどうかを判断しているのか？
 
 @discardableResult
 init(
     priority: TaskPriority? = nil,
     operation: sending @escaping @isolated(any) () async -> Success
 )
 
 sending は例外的な話
 
 sending 以前の話では、クロージャに @Sendable が付与されていた
 @discardableResult
 init(
     priority: TaskPriority? = nil,
     operation: @Sendable @escaping @isolated(any) () async -> Success
 )
 */

final class Box {
    var value: Int = 0
}

actor A {
    var box: Box?
    func setBox(_ box: Box) {
        self.box = box
    }
    
    func useF(_ f: @escaping () -> Void) {
        // ここで、渡されてきた f: () -> Void の { ... } が実行されてしまう
    }
}

func run1() async {
    let box = Box()
    let a: A = .init()
    
    // 関数やクロージャに Sendable プロトコルを準拠はできないため、 @Sendable を使用する
    // let f: @Sendable () -> Void = {}
    
    let f: () -> Void = { // コンパイルエラー
    }
    
    // await a.useF(f)
    f() // さらにここでも f を呼び出すことができてしまう
    
    
//    Task {
//        box.value = -1
//    }
//
//    Task {
//        print(box.value)
//    }
}

await run1()

func run2() async {
    let box = Box()
    let a: A = .init()
    
    // 関数やクロージャに Sendable プロトコルを準拠はできないため、 @Sendable を使用する
    // let f: @Sendable () -> Void = {}
    
    let f: @Sendable () -> Void = { // コンパイルエラーを回避
    }
    
    await a.useF(f)
    f() // さらにここでも f を呼び出すことができてしまう
    
    
//    Task {
//        box.value = -1
//    }
//
//    Task {
//        print(box.value)
//    }
}

await run2()

