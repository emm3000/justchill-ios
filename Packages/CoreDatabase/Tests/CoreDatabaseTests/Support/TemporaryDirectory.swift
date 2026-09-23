import Foundation

final class TemporaryDirectory: Sendable {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    var databaseURL: URL {
        url.appending(path: "justchill.sqlite")
    }
}
