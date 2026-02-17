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

/// Progress information for a batch export operation.
///
/// Each value represents the completion of one feature file.
public struct BatchExportProgress: Sendable {
    /// The title of the feature that was exported.
    public let featureTitle: String

    /// The zero-based index of the feature in the batch.
    public let index: Int

    /// The total number of features being exported.
    public let total: Int

    /// A value between 0.0 and 1.0 indicating overall progress.
    public var fractionCompleted: Double {
        guard total > 0 else { return 1.0 }
        return Double(index + 1) / Double(total)
    }

    /// The path where the feature was written.
    public let outputPath: String
}

/// An actor for batch-exporting features to a directory.
///
/// `BatchExporter` takes an array of features and writes each one
/// as a `.feature` file in a target directory, using structured
/// concurrency for parallel I/O. Errors on individual files do not
/// stop the rest of the batch.
///
/// ```swift
/// let exporter = BatchExporter()
/// try await exporter.exportAll(features, to: "output/")
/// ```
public actor BatchExporter {
    private let formatter: GherkinFormatter
    private let exporter: GherkinExporter

    /// Creates a batch exporter.
    ///
    /// - Parameter formatter: The formatter to use. Defaults to a default-configured formatter.
    public init(formatter: GherkinFormatter = GherkinFormatter()) {
        self.formatter = formatter
        self.exporter = GherkinExporter(formatter: formatter)
    }

    /// Exports all features to individual `.feature` files in the target directory.
    ///
    /// Files are written in parallel using `TaskGroup`. A failure in one
    /// file does not prevent other files from being exported.
    /// The directory is created if it does not exist.
    ///
    /// - Parameters:
    ///   - features: The features to export.
    ///   - directory: The target directory path.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Returns: An array of results, one per feature, preserving input order.
    /// - Throws: ``GherkinError/exportFailed(path:reason:)`` if the directory cannot be created.
    public func exportAll(
        _ features: [Feature],
        to directory: String,
        format: ExportFormat = .feature
    ) async throws -> [Result<String, GherkinError>] {
        try ensureDirectory(at: directory)

        let existingFiles = listFiles(in: directory)
        let paths = resolveOutputPaths(
            for: features,
            in: directory,
            format: format,
            existingFiles: existingFiles
        )
        let exporter = self.exporter

        return await withTaskGroup(
            of: (Int, Result<String, GherkinError>).self,
            returning: [Result<String, GherkinError>].self
        ) { group in
            for (index, feature) in features.enumerated() {
                let outputPath = paths[index]
                group.addTask {
                    let result = Self.exportFile(
                        feature: feature,
                        to: outputPath,
                        format: format,
                        exporter: exporter
                    )
                    return (index, result)
                }
            }

            var indexed: [(Int, Result<String, GherkinError>)] = []
            indexed.reserveCapacity(features.count)
            for await pair in group {
                indexed.append(pair)
            }

            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    /// Exports all features and yields progress updates as each file completes.
    ///
    /// The directory is created if it does not exist.
    /// Each progress update includes the feature title, index, and output path.
    ///
    /// - Parameters:
    ///   - features: The features to export.
    ///   - directory: The target directory path.
    ///   - format: The export format. Defaults to ``ExportFormat/feature``.
    /// - Returns: An async stream of progress updates.
    public func exportAllWithProgress(
        _ features: [Feature],
        to directory: String,
        format: ExportFormat = .feature
    ) -> AsyncStream<BatchExportProgress> {
        let exporter = self.exporter
        return AsyncStream { continuation in
            Task { [self] in
                do {
                    try self.ensureDirectory(at: directory)
                } catch {
                    continuation.finish()
                    return
                }

                let existingFiles = self.listFiles(in: directory)
                let paths = self.resolveOutputPaths(
                    for: features,
                    in: directory,
                    format: format,
                    existingFiles: existingFiles
                )
                let total = features.count

                await withTaskGroup(
                    of: (Int, String, Result<String, GherkinError>).self
                ) { group in
                    for (index, feature) in features.enumerated() {
                        let outputPath = paths[index]
                        let title = feature.title
                        group.addTask {
                            let result = Self.exportFile(
                                feature: feature,
                                to: outputPath,
                                format: format,
                                exporter: exporter
                            )
                            return (index, title, result)
                        }
                    }

                    for await (index, title, result) in group {
                        let outputPath: String
                        switch result {
                        case .success(let path):
                            outputPath = path
                        case .failure:
                            outputPath = paths[index]
                        }
                        continuation.yield(
                            BatchExportProgress(
                                featureTitle: title,
                                index: index,
                                total: total,
                                outputPath: outputPath
                            )
                        )
                    }
                }

                continuation.finish()
            }
        }
    }

    // MARK: - Private Helpers

    /// Creates the directory if it does not exist.
    private func ensureDirectory(at path: String) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else {
                throw GherkinError.exportFailed(
                    path: path,
                    reason: "Path exists but is not a directory"
                )
            }
            return
        }
        do {
            try fileManager.createDirectory(
                atPath: path,
                withIntermediateDirectories: true
            )
        } catch {
            throw GherkinError.exportFailed(
                path: path,
                reason: "Cannot create directory: \(error.localizedDescription)"
            )
        }
    }

    /// Lists existing file names in a directory.
    private func listFiles(in directory: String) -> Set<String> {
        let fileManager = FileManager.default
        let contents = (try? fileManager.contentsOfDirectory(atPath: directory)) ?? []
        return Set(contents)
    }

    /// Computes unique output paths for all features, handling duplicates.
    private func resolveOutputPaths(
        for features: [Feature],
        in directory: String,
        format: ExportFormat,
        existingFiles: Set<String>
    ) -> [String] {
        var usedNames = existingFiles
        var paths: [String] = []
        paths.reserveCapacity(features.count)

        let fileExtension: String
        switch format {
        case .feature:
            fileExtension = "feature"
        case .json:
            fileExtension = "json"
        case .markdown:
            fileExtension = "md"
        }

        for feature in features {
            let base = Self.slugify(feature.title)
            var candidate = "\(base).\(fileExtension)"
            var counter = 1
            while usedNames.contains(candidate) {
                candidate = "\(base)-\(counter).\(fileExtension)"
                counter += 1
            }
            usedNames.insert(candidate)
            paths.append((directory as NSString).appendingPathComponent(candidate))
        }

        return paths
    }

    /// Exports a single feature to a file, returning the path on success.
    private static func exportFile(
        feature: Feature,
        to path: String,
        format: ExportFormat,
        exporter: GherkinExporter
    ) -> Result<String, GherkinError> {
        do {
            let content = try exporter.render(feature, format: format)
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            return .success(path)
        } catch let error as GherkinError {
            return .failure(error)
        } catch {
            return .failure(
                .exportFailed(path: path, reason: error.localizedDescription)
            )
        }
    }

    /// Converts a feature title to a filename-safe slug.
    ///
    /// Rules: lowercase, spaces and underscores become hyphens,
    /// non-alphanumeric/non-hyphen characters are removed,
    /// consecutive hyphens are collapsed, leading/trailing hyphens trimmed.
    static func slugify(_ title: String) -> String {
        let lowered = title.lowercased()
        var slug = ""
        for character in lowered {
            if character.isLetter || character.isNumber {
                slug.append(character)
            } else if character == " " || character == "_" || character == "-" {
                slug.append("-")
            }
        }
        // Collapse consecutive hyphens
        while slug.contains("--") {
            slug = slug.replacingOccurrences(of: "--", with: "-")
        }
        // Trim leading/trailing hyphens
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        if slug.isEmpty {
            slug = "feature"
        }
        return slug
    }
}
