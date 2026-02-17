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

/// Parses a `.feature` file and displays information.
struct ParseCommand: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "parse",
        abstract: "Parse a .feature file and display its structure."
    )

    @Argument(help: "Path to a .feature file.")
    var path: String

    @Option(name: .long, help: "Output format: summary or json (default: summary).")
    var format: OutputFormat = .summary

    enum OutputFormat: String, ExpressibleByArgument, Sendable {
        case summary
        case json
    }

    func run() async throws {
        let parser = GherkinParser()
        let feature = try parser.parse(contentsOfFile: path)

        switch format {
        case .summary:
            printSummary(feature)
        case .json:
            let exporter = GherkinExporter()
            let jsonOutput = try exporter.render(feature, format: .json)
            print(jsonOutput)
        }
    }

    private func printSummary(_ feature: Feature) {
        print(ANSIColor.bold("Feature:") + " \(feature.title)")
        print(
            ANSIColor.bold("Language:")
                + " \(feature.language.name) (\(feature.language.code))"
        )

        let scenarioCount = feature.scenarios.count
        let outlineCount = feature.outlines.count
        let ruleCount = feature.rules.count

        print(ANSIColor.bold("Scenarios:") + " \(scenarioCount)")
        print(ANSIColor.bold("Outlines:") + " \(outlineCount)")
        print(ANSIColor.bold("Rules:") + " \(ruleCount)")

        if !feature.tags.isEmpty {
            let tagNames = feature.tags.map(\.rawValue).joined(separator: ", ")
            print(ANSIColor.bold("Tags:") + " \(tagNames)")
        }

        if let description = feature.description {
            print(ANSIColor.bold("Description:") + " \(description)")
        }
    }
}
