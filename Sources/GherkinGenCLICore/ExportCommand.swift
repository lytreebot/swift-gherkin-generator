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

import ArgumentParser
import Foundation
import GherkinGenerator

/// Exports a `.feature` file to another format.
struct ExportCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export a .feature file to another format."
    )

    @Argument(help: "Path to a .feature file.")
    var path: String

    @Option(name: .long, help: "Export format: feature, json, or markdown.")
    var format: ExportFormatOption

    @Option(name: .long, help: "Output file path. Prints to stdout if omitted.")
    var output: String?

    enum ExportFormatOption: String, ExpressibleByArgument, Sendable {
        case feature
        case json
        case markdown
    }

    func run() async throws {
        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: path)

        let exportFormat: ExportFormat
        switch format {
        case .feature:
            exportFormat = .feature
        case .json:
            exportFormat = .json
        case .markdown:
            exportFormat = .markdown
        }

        let exporter = GherkinExporter()
        let rendered = try exporter.render(feature, format: exportFormat)

        if let outputPath = output {
            try rendered.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print(ANSIColor.green("Exported to \(outputPath)"))
        } else {
            print(rendered, terminator: "")
        }
    }
}
