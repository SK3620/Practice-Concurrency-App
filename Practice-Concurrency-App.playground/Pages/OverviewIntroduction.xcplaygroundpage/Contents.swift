import Foundation
import SwiftUI
import UIKit

// MARK: - Task
/*
 Task
 
 Taskの特徴
 ・全てのasync関数はTask上で実行される
 ・一つのTask上で複数の処理が並行に実行されることはない
 ・一つのTask上で行われる処理が常に同じスレッドで実行されるとは限らない（Taskはスレッドではない）
 
 Task Tree
 ・async let を（並行処理）すると、その非同期処理の数分の child task が作られる
 ・一つのTask上で、状況に応じて、n個の非同期処理を行うようなケースは、with(Thowing)TaskGroupを使う
 ・親タスク（ルートのTask）をキャンセルすれば、その子タスクたちもcancelも簡単にできる
 */



// MARK: - Actor, nonisolated
/*
 データ競合
 
 最終的な期待値は、順不同で「100, 110」

// 以下はデータ競合の例
class Score {
    var logs: [Int] = []
    private(set) var highScore: Int = 0

    func update(with score: Int) {
        logs.append(score)
        if score > highScore { // ①
            highScore = score // ②
        }
    }
}

let score = Score()
 
// 複数のスレッドからupdateメソッドを実行
// ③と④はそれぞれ別スレッドで同じscoreインスタンスに対してメソッドを実行します。
// 複数のスレッドからデータを"同時に"アクセスしている！
DispatchQueue.global(qos: .default).async {
    score.update(with: 100) // ③
    // 期待値: 100
    print(score.highScore)  // ④
}
DispatchQueue.global(qos: .default).async {
    score.update(with: 110) // ⑤
    // 期待値: 110
    print(score.highScore)　// ⑥
}
 
 どちらも100 or 110になることがある
 ③が①を通過
 ⑤が①と②を通過し、highScoreが110になる
 ③が②を通過し、highScoreが100になる
 ④が通過し、100を出力
 ⑥が通過し、100を出力
 */

// データ競合を防ぐ
actor Score2 {
    var logs: [Int] = []
    private(set) var highScore: Int = 0 // 書き込み不可

    func update(with score: Int) {
        print(Thread.isMainThread) // false
        logs.append(score)
        if score > highScore { // ①
            highScore = score // ②
        }
    }
    
    // update2もcallした時点で、update2もキューに詰め込まれる
    func update2() {
        update(with: 120) // そのためawaitは不要
    }
}
let score2 = Score2()

// .detachedにより、バックグラウンドスレッドで実行
Task.detached(operation: { () -> Void in
    await score2.update(with: 100)
    print(await score2.highScore) // awaitをつけるルール
})
Task.detached(operation: { () -> Void in
    await score2.update(with: 110)
    print(await score2.highScore)
})
// どちらも100になる場合や、110になる場合がなくなり
// 必ず、100, 110が順不同で出力される（データ競合がなくなる）

// update()もudpate2()もasyncキーワードがないが、外からアクセスする場合は必ずawaitをつける！（asyncのように扱う）


// MARK: - actorがインスタンスごとにserial executorを持つ

actor Counter {
    private var value = 0
    func increment() { value += 1 }
    func getValue() -> Int { value }
}
let counter1 = Counter() // counter1 内の処理は counter1 専用の serial executor が守る
let counter2 = Counter() // counter2 内の処理は counter2 専用の serial executor が守る



// MARK: - nonisolated
// serial executor で保護（actorにisolate）したくないプロパティやメソッドにはnonisolatedを付与
actor Foo {
    var value1: Int = 1
    nonisolated let value2: Int = 0
}
let foo = Foo()
Task {
    print(await foo.value1) // actorにisolate（隔離）される
}
print(foo.value2) // actorにisolate（隔離）されない



// MARK: - Global Actor

/*
 UIの各部品（UILabel、UIButton、UIViewControllerなど）はそれぞれ別のインスタンスですが、UI更新は必ずメインスレッド（main queue）で行う必要がある
 しかし、通常のactorはインスタンスごとに別々のexecutorを持つため、UI全体を一括してメインスレッドで保護することはできない
 そのため、UIのように「複数のインスタンスに共通する1つのメインスレッド」で守りたい場合には、アプリ全体共通のexecutorを持つglobal actor（代表的な例として@MainActor） を使う
 @MainActorを付けると、どのインスタンスの処理でも必ずメインスレッドで実行されることが保証されます。
 */

/*
@MainActor func fooFoo() { /*この中身はメインスレッドで実行*/ }

struct FooFoo {
    @MainActor var value: Int = 1 // メインスレッドでアクセス時
    @MainActor func bar() {} // メインスレッドで実行
}

Task { @MainActor in }
 */

@MainActor
class MyViewModel: ObservableObject {
    @Published var text: String = "初期値"
    
    func loadData() async { // MainActorにisolateされる
        let result = await APIClient().fetchFromNetwork()
        text = result // ここも自動で main thread
    }
}
class APIClient {
    func fetchFromNetwork() async -> String {
        // ネットワーク通信の処理（ここはバックグラウンドスレッド）
        return "取得したデータ"
    }
}



// MARK: - UI と MainActor　　actor contextn の引き継ぎ

/*
 ・UIView, UIViewController, SwiftUIのViewにはすでに @MainActor が付与されている
 ・そのため、それらに準拠するカスタムViewなどもMainActorにisolateされていて、安心
 */

/*
// 自動的にMainActor-isolated
class FooViewController: UIViewController {
    
    // このメソッドもMainActor-isolated
    func buttonTapped() {
        Task { // Task Context を引き継ぎ、このTaskの中身の処理はMainActor-isolated
            // ...
        }
    }
    
    // このメソッドもMainActor-isolated
    func buttonTapped2() {
        Task.detached { // Task Context を引き継がないため、nonisolated
            // ... メインスレッドから切り離す
        }
    }
}

// let fooVC = FooViewController()
// fooVC.buttonTapped()
// fooVC.buttonTapped2()
*/
