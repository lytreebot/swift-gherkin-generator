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

// MARK: - Batch Importer

/// An actor for batch-importing features from a directory.
///
/// `BatchImporter` scans a directory for `.feature` files and parses
/// them in parallel using structured concurrency.
///
/// ```swift
/// let importer = BatchImporter()
/// let results = try await importer.importDirectory(at: "features/")
/// for result in results {
///     switch result {
///     case .success(let feature):
///         print("Imported: \(feature.title)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
public actor BatchImporter {
    private let parser: GherkinParser

    /// Creates a batch importer.
    ///
    /// - Parameter parser: The parser to use. Defaults to a default parser.
    public init(parser: GherkinParser = GherkinParser()) {
        self.parser = parser
    }

    /// Imports all `.feature` files from a directory.
    ///
    /// Files are parsed in parallel using `TaskGroup`. A failure in one
    /// file does not prevent other files from being parsed.
    ///
    /// - Parameters:
    ///   - path: The directory path.
    ///   - recursive: Whether to scan subdirectories. Defaults to `false`.
    /// - Returns: An array of results, one per file found.
    /// - Throws: ``GherkinError/importFailed(path:reason:)`` if the directory cannot be read.
    public func importDirectory(
        at path: String,
        recursive: Bool = false
    ) async throws -> [Result<Feature, GherkinError>] {
        let files = try listFeatureFiles(at: path, recursive: recursive)
        let parser = self.parser

        return await withTaskGroup(
            of: (Int, Result<Feature, GherkinError>).self,
            returning: [Result<Feature, GherkinError>].self
        ) { group in
            for (index, filePath) in files.enumerated() {
                group.addTask {
                    let result = Self.parseFile(at: filePath, parser: parser)
                    return (index, result)
                }
            }

            var indexed: [(Int, Result<Feature, GherkinError>)] = []
            indexed.reserveCapacity(files.count)
            for await pair in group {
                indexed.append(pair)
            }

            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Returns an `AsyncStream` of features parsed from a directory.
    ///
    /// Features are yielded as they are parsed, enabling progressive
    /// processing of large directories.
    ///
    /// - Parameters:
    ///   - path: The directory path.
    ///   - recursive: Whether to scan subdirectories. Defaults to `false`.
    /// - Returns: An async stream of parse results.
    public func streamDirectory(
        at path: String,
        recursive: Bool = false
    ) -> AsyncStream<Result<Feature, GherkinError>> {
        let files: [String]
        do {
            files = try listFeatureFiles(at: path, recursive: recursive)
        } catch {
            return AsyncStream { continuation in
                if let gherkinError = error as? GherkinError {
                    continuation.yield(.failure(gherkinError))
                } else {
                    continuation.yield(
                        .failure(.importFailed(path: path, reason: error.localizedDescription))
                    )
                }
                continuation.finish()
            }
        }

        let parser = self.parser
        return AsyncStream { continuation in
            let filesCopy = files
            Task {
                await withTaskGroup(of: Result<Feature, GherkinError>.self) { group in
                    for filePath in filesCopy {
                        group.addTask {
                            Self.parseFile(at: filePath, parser: parser)
                        }
                    }

                    for await result in group {
                        continuation.yield(result)
                    }
                }
                continuation.finish()
            }
        }
    }

    // MARK: - Private Helpers

    /// Lists `.feature` files in a directory.
    private func listFeatureFiles(
        at path: String,
        recursive: Bool
    ) throws -> [String] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            throw GherkinError.importFailed(
                path: path, reason: "Path is not a directory"
            )
        }

        let contents: [String]
        if recursive {
            guard let enumerator = fileManager.enumerator(atPath: path) else {
                throw GherkinError.importFailed(
                    path: path, reason: "Cannot enumerate directory"
                )
            }
            contents = enumerator.compactMap { $0 as? String }
        } else {
            do {
                contents = try fileManager.contentsOfDirectory(atPath: path)
            } catch {
                throw GherkinError.importFailed(
                    path: path, reason: error.localizedDescription
                )
            }
        }

        return
            contents
            .filter { $0.hasSuffix(".feature") }
            .sorted()
            .map { (path as NSString).appendingPathComponent($0) }
    }

    /// Parses a single file, capturing any error as a `Result`.
    private static func parseFile(
        at filePath: String,
        parser: GherkinParser
    ) -> Result<Feature, GherkinError> {
        do {
            let feature = try parser.parse(contentsOfFile: filePath)
            return .success(feature)
        } catch let error as GherkinError {
            return .failure(error)
        } catch {
            return .failure(
                .importFailed(path: filePath, reason: error.localizedDescription)
            )
        }
    }
}
