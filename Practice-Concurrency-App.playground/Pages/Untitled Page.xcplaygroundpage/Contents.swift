import SwiftUI
import Observation

struct User: Sendable, Identifiable {
    var id: String
    var name: String
}

struct UserListView: View {
    
    /*
     ViewState に @MainActor はいらない
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

@MainActor @Observable
final class UserListViewState {
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

