import Foundation

final class Box {
    var value: Int = 0
}

let box = Box()

// 実行時、MainActorではない時はクラッシュさせる
MainActor.assertIsolated()

// 以下は並行処理
// そして、Taskは actor Context を引き継ぐ
Task {
    // MainActor
    MainActor.assertIsolated()
    box.value = -1
}

Task {
    // MainActor
    MainActor.assertIsolated()
    print(box.value)
}

// 両者、MainActor（一つのスレッド）のため、box.value = -1 と print(box.value) が同時に実行されることはなく、一つ一つ順番に実行される
// よって、コンパイルが通る


let serialQueue = DispatchQueue(label: "com.example.serial", target: .global())

serialQueue.async {
    
    print(Thread.isMainThread)

    print("Task 1")

}

serialQueue.async {
    
    print(Thread.isMainThread)

    print("Task 2")

}
