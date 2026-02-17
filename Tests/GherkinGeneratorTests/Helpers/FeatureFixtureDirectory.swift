// SPDX-License-Identifier: Apache-2.0
//
// Copyright 2026 Atelier Socle SAS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
