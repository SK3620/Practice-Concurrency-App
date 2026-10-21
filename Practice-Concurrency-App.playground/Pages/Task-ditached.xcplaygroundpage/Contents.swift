//: [Previous](@previous)

import Foundation

var greeting = "Hello, playground"

//: [Next](@next)

/**
 Task.detachedはTask.initと異なり、TaskやActorの実行コンテキスト (Actor isolationや@TaskLocal、TaskPriority) を継承しない。
 Task.detachedの使い所としては、@MainActorからバックグラウンドスレッドに処理をディスパッチしたい場合など、あえてActor isolationを断ち切りたいケースが代表的である。
 */
