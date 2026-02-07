import Foundation

/// Creates a temporary directory with `.feature` files for testing.
///
/// Automatically cleans up on `deinit`.
final class FeatureFixtureDirectory: @unchecked Sendable {
    let path: String

    /// Creates a temp directory with the given feature file contents.
    ///
    /// - Parameter files: A dictionary of filename to Gherkin content.
    init(files: [String: String]) throws {
        let tempDir = NSTemporaryDirectory()
        let dirName = "gherkin-test-\(UUID().uuidString)"
        let dirPath = (tempDir as NSString).appendingPathComponent(dirName)
        try FileManager.default.createDirectory(
            atPath: dirPath, withIntermediateDirectories: true
        )
        self.path = dirPath

        for (name, content) in files {
            let filePath = (dirPath as NSString).appendingPathComponent(name)
            let parentDir = (filePath as NSString).deletingLastPathComponent
            if parentDir != dirPath {
                try FileManager.default.createDirectory(
                    atPath: parentDir, withIntermediateDirectories: true
                )
            }
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        }
    }

    /// Returns the full path for a file within this directory.
    func filePath(_ name: String) -> String {
        (path as NSString).appendingPathComponent(name)
    }

    deinit {
        try? FileManager.default.removeItem(atPath: path)
    }
}
