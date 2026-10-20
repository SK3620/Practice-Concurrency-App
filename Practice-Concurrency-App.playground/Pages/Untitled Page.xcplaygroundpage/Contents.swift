import SwiftUI
import Observation

struct User: Sendable, Identifiable {
    var id: String
    var name: String
}

struct UserListView: View {
    
    /*
     ViewState（ViewModel） に @MainActor はいらない
     View プロトコルは そもそも @MainActor で保護されている
     すなわち、 @State private var state = UserListViewState() の
     ViewState の生成が MainActor で行われているということは、
     ViewState は MainActor で保護されている
     → UserListViewState の @MainActor は外してよし
     → UserListViewState は class なので Sendable でない
     → さらに、View 側で MainActor で保護されている
     → ViewState が MainActor のドメインを跨ぐことはない
     → ViewState は 一生、MainActor 内にいないとだめ！
     → ViewState が持つ users などのプロパティやメソッドは MainActor からしかアクセスできないということ
     → メインスレッド外からアクセスはありえない！
     → UserListViewState の @MainActor は外してよし！
     */
    @State private var state = UserListViewState()
    
    var body: some View {
        List(state.users) { user in
            NavigationLink {
            } label: {
                Text(user.name)
            }
        }
        .task {
            await state.load()
        }
    }
}

// @MainActorがいらない？？
@MainActor @Observable
final class UserListViewState {
    
    /**
     元々、非同期処理の結果で（バックグラウンドスレッド メインスレッド以外のスレッド）のスレッドからusesプロパティを更新してしまうと、そのスレッドとメインスレッドの二つのスレッドから同時にアクセスが可能となってしまうことが問題となっていた
     */
    private(set) var users: [User] = []
    
    func load() async {
        do {
            users = try await UserRepository.fetchAllValues()
        } catch {
            //
        }
    }
}

enum UserRepository {
    static func fetchAllValues() async throws -> [User] {
        return []
    }
}

/*
 @MainActor をつける理由
 ViewState 内で非同期処理を行い、その結果を、メインスレッドに切り替えず、バックグラウンドスレッド内から、users = 結果 というような誤ったミス処理をしてしまっていても、＠MainActor を付与することで、users = 結果 という書き込み処理はメインスレッドに isolate させて行うように保証させ、安全にすることができる
 */







/*
=====================================================================
【学習メモ】Swift 6 並行処理：ViewState と Isolation Domain / Sendable
=====================================================================
 */
enum Practice {
    
    /*
     
     1. ViewState（ViewModel）と MainActor の関係
     ---------------------------------------------------------------------
     ・View プロトコル自体が @MainActor で保護されているため、
       View の中で生成される `@State private var state = UserListViewState()`
       も必然的に MainActor 上で生成・管理される。
     
     ・UserListViewState は class（参照型）であるため、Sendable に準拠できない。
     
     ・したがって、ViewState は「一生、MainActor のドメイン（境界線）の中に
       いなければならない」。
     
     ・ViewState が持つプロパティやメソッドは MainActor からしかアクセスできず、
       メインスレッド外からのアクセスはありえない。
     
     
     2. @MainActor をクラスに付与する理由
     ---------------------------------------------------------------------
     ・ViewState 内で非同期処理を行い、その結果をうっかりバックグラウンドスレッドのまま
       `users = results` のように書き換えてしまうミスを防ぐため。
     ・@MainActor を付与することで、書き込み処理は必ずメインスレッドで行うように
       コンパイラが保証（Isolate）してくれる。
     
     
     3. 【NG例①】ViewState を他の独立したタスク（バックグラウンド）へ持ち出そうとする例
     ---------------------------------------------------------------------
     ・ViewState（非 Sendable な class）は MainActor の外へ持ち出してはならない。
     ・もし別スレッド等に持ち出すと、UIスレッドとバックグラウンドスレッド双方が
       同じオブジェクトに同時アクセスする「データ競合（Data Race）」が起きるため、
       Swift 6 ではコンパイルエラーになる。
    */

    struct User: Sendable, Identifiable {
        var id: String
        var name: String
    }

    // 修正：ViewState 内での安全性を高めるため @MainActor を付与
    @MainActor @Observable
    final class UserListViewState {
        private(set) var users: [User] = []
        
        func load() async {
            do {
                users = try await UserRepository.fetchAllValues()
            } catch {
                // エラーハンドリング
            }
        }
    }

    enum UserRepository {
        static func fetchAllValues() async throws -> [User] {
            return []
        }
    }

    struct UserListView: View {
        @State private var state = UserListViewState()
        
        var body: some View {
            List(state.users) { user in
                Text(user.name)
            }
            .task {
                // 【NG例①の解説】
                // state は MainActor のもの。
                //これを Task.detached（完全に独立した別スレッド）へ持ち出そうとすると、
                // 非 Sendable な class を安全ではない形で別領域に渡そうとしたとしてエラーになる。
                //
                // let capturedState = state
                // Task.detached {
                //     // 🔴 もしこれが通ってしまうと、MainActor外から ViewState を触ることになり危険！
                //     // await capturedState.load()
                // }
                
                // 正しい書き方（MainActorのコンテキストを維持したまま実行）
                await state.load()
            }
        }
    }


    /*
     4. 【NG例②】ViewState を別のアクター（Isolation Domain）へ渡そうとする例
     ---------------------------------------------------------------------
     ・MainActor 以外の「別のアクター（actor）」に、非 Sendable な ViewState を
       メソッドの引数などで渡そうとするケース。
     ・これもドメインの境界線を越えようとするため、Swift 6 では厳しくコンパイルエラーになる。
    */

    actor BackgroundDownloadManager {
        // 🔴 危険（エラーになる例）：
        // 別のアクター領域へ、非 Sendable な ViewState を直接渡そうとしている
        func processViewState(state: UserListViewState) async {
            // 異なる Isolation Domain 間でオブジェクトの共有や並行アクセスが発生するため、
            // データ競合の危険があり、Swift 6 がコンパイルエラーで弾く。
        }
    }
    
}
