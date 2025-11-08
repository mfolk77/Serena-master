import Foundation

extension String {
    func appendToFile(atPath path: String) throws {
        let data = self.data(using: .utf8)!
        if FileManager.default.fileExists(atPath: path) {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
            defer { try? fileHandle.close() }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        }
    }
}
