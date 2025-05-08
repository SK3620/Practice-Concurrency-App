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

func run1() {
    let box = Box()
    let a: A = .init() // A の Isolation Domain
    
    //  A の Isolation Domain に Box を渡そうしている
    // すなわち、Box は A の Isolation Boundary を越えようとしている
    // しかし、Box は Sendable でないため、コンパイルエラー発生！
    a.setBox(box) // Non-Sendable なデータが Isolation Boundary を越えようとしているよ！
}

func run2() {
    let box = Box()
    
    Task {
        box.value = -1
    }

    Task {
        print(box.value)
    }
}

run1()
run2()


