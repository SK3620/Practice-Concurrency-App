import Foundation

final class Box {
    var value: Int = 0
}

actor A {
    var box: Box?
    func setBox(_ box: Box) {
        self.box = box
    }
}

func run() {
    let box = Box()
    let a: A = .init()
    
    // Task も Task 独自の Isolation Domain を持つ
    // Taskクロージャの中身は、Taskインスタンスの中の世界（Task 独自の Isolation Domain の中）であるため、
    // Box は Isolation Boundary を越えて、Task 独自の Isolation Domain に入ろうとしている
    // しかし、Box は non-Sendable のため、コンパイルエラー
    
    /*
    Task { // コンパイルエラー
        box.value = -1
    }

    Task {
        print(box.value)
    }
     */
}

run()

/*
 Task インスタンスごとに Isolation Domain が存在するのか？（不明っぽい）
 
 Isolation Domain は3つのカテゴリに分類される
 ・Non-isolated（Taskもインスタンスごとに Task 独自の Isolation Domain を持っている？）それって「Isolated to an actor value」？
 ・Isolated to an actor value（クラスのインスタンスごとに作られるActor）
 ・Isolated to a global actor（MainActorが代表的）
 */

