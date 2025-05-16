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

/*
 ※ 注意
 以下、「let f: () -> Void = {}」のクロージャの具体的な処理の中身は {} で、
 何もしていないので、事実上安全ではあるので、関数が Isolation Boundary を超えても問題はない
 */

func run1() async {
    let box = Box()
    let a: A = .init()
    
    // 関数やクロージャに Sendable プロトコルを準拠はできないため、 @Sendable を使用する
    // let f: @Sendable () -> Void = {}
    
    let f: () -> Void = {}
    
    // await a.useF(f) // Sending 'f' risks causing data races
    f() // さらにここでも f を呼び出すことができてしまう
}

await run1()

func run2() async {
    let box = Box()
    let a: A = .init()
    
    // 関数やクロージャに Sendable プロトコルを準拠はできないため、 @Sendable を使用する
    // let f: @Sendable () -> Void = {}
    
    let f: @Sendable () -> Void = {} // コンパイルエラーを回避
    
    await a.useF(f)
    f() // さらにここでも f を呼び出すことができてしまう
}

await run2()


func run3() async {
    let box = Box()
    let a: A = .init()
    
    /*
    box をキャプチャする
    今、f は Sendable ではないので、f を外の Isolation Domain へ持ち出すことはできない
    なので、Sendable でない box をキャプチャしても安全
     */
    let f: () -> Void = {
        box.value = -1
    }
    
    /*
     Sendable にしてみる
     すると、f2 は 外の actor に渡せてしまうが、
     その渡されてしまう f2 の クロージャ中身には、Sendable でない box をキャプチャしてしまっている
     よって 外の actor 内で実行されて、同時にアクセスされてしまう可能性がある
     なので、コンパイルエラー
     */
    let f2: @Sendable () -> Void = {
        // box.value = -1 // コンパイルエラー
    }
    
    f()
}

await run3()



/*
 まとめ：
 Task は Task のインスタンスごとに Isolation Domain を持っている
 Task.init の
 
 init(
     priority: TaskPriority? = nil,
     operation: @Sendable @escaping @isolated(any) () async -> Success
 )
 
 の operation は run3() の　let f2: @Sendable () -> Void = {} の例と同じ
 
 @Sendable なクロージャの中身では、non-Sendable な値はキャプチャできない！！！
 */
func run4() async {
    let box = Box()
    let a: A = .init()

    Task(operation: { () async throws -> Sendable in
        // box.value = -1 // コンパイルエラー
        return "あああ"
    })
   
    Task {
        print(box.value)
    }
}

await run4()
