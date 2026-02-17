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
import Testing

@testable import GherkinGenerator

@Suite("Fixture Roundtrip")
struct FixtureRoundtripTests {

    private let parser = GherkinParser()
    private let exporter = GherkinExporter()
    private let jsonParser = JSONFeatureParser()

    // MARK: - Helpers

    private func parseFixture(_ name: String) throws -> Feature {
        guard let url = Bundle.module.url(forResource: name, withExtension: nil) else {
            throw GherkinError.importFailed(path: name, reason: "Fixture not found")
        }
        let source = try String(contentsOf: url, encoding: .utf8)
        return try parser.parse(source)
    }

    // MARK: - JSON Roundtrip

    @Test("JSON roundtrip — simple.feature")
    func jsonRoundtripSimple() throws {
        let original = try parseFixture("simple.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — complex.feature")
    func jsonRoundtripComplex() throws {
        let original = try parseFixture("complex.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — outline.feature")
    func jsonRoundtripOutline() throws {
        let original = try parseFixture("outline.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — rules.feature")
    func jsonRoundtripRules() throws {
        let original = try parseFixture("rules.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — french.feature")
    func jsonRoundtripFrench() throws {
        let original = try parseFixture("french.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — german.feature")
    func jsonRoundtripGerman() throws {
        let original = try parseFixture("german.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — edge-cases.feature")
    func jsonRoundtripEdgeCases() throws {
        let original = try parseFixture("edge-cases.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    @Test("JSON roundtrip — large.feature")
    func jsonRoundtripLarge() throws {
        let original = try parseFixture("large.feature")
        let json = try exporter.render(original, format: .json)
        let decoded = try jsonParser.parse(json)

        #expect(original == decoded)
    }

    // MARK: - JSON Fixture File Roundtrip

    @Test("JSON fixture file roundtrip — simple-feature.json")
    func jsonFixtureSimple() throws {
        guard
            let url = Bundle.module.url(
                forResource: "simple-feature", withExtension: "json"
            )
        else {
            Issue.record("Fixture not found: simple-feature.json")
            return
        }
        let data = try Data(contentsOf: url)
        let decoded = try jsonParser.parse(data: data)

        // Re-encode and decode again
        let json2 = try exporter.render(decoded, format: .json)
        let decoded2 = try jsonParser.parse(json2)

        #expect(decoded == decoded2)
    }

    @Test("JSON fixture file roundtrip — complex-feature.json")
    func jsonFixtureComplex() throws {
        guard
            let url = Bundle.module.url(
                forResource: "complex-feature", withExtension: "json"
            )
        else {
            Issue.record("Fixture not found: complex-feature.json")
            return
        }
        let data = try Data(contentsOf: url)
        let decoded = try jsonParser.parse(data: data)

        let json2 = try exporter.render(decoded, format: .json)
        let decoded2 = try jsonParser.parse(json2)

        #expect(decoded == decoded2)
    }

    // MARK: - Feature Format Roundtrip

    @Test("Feature format roundtrip — simple.feature")
    func featureRoundtripSimple() throws {
        let original = try parseFixture("simple.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — complex.feature")
    func featureRoundtripComplex() throws {
        let original = try parseFixture("complex.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — outline.feature")
    func featureRoundtripOutline() throws {
        let original = try parseFixture("outline.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — rules.feature")
    func featureRoundtripRules() throws {
        let original = try parseFixture("rules.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — french.feature")
    func featureRoundtripFrench() throws {
        let original = try parseFixture("french.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — german.feature")
    func featureRoundtripGerman() throws {
        let original = try parseFixture("german.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    @Test("Feature format roundtrip — large.feature")
    func featureRoundtripLarge() throws {
        let original = try parseFixture("large.feature")
        let formatted = exporter.formatter.format(original)
        let reparsed = try parser.parse(formatted)
        let reformatted = exporter.formatter.format(reparsed)

        #expect(formatted == reformatted)
    }

    // MARK: - Cross-Format Roundtrip

    @Test("Cross-format roundtrip: .feature → JSON → Feature → .feature")
    func crossFormatRoundtrip() throws {
        let original = try parseFixture("complex.feature")

        // .feature → JSON
        let json = try exporter.render(original, format: .json)

        // JSON → Feature
        let decoded = try jsonParser.parse(json)

        // Feature → .feature (format twice to normalize)
        let featureOutput1 = exporter.formatter.format(original)
        let featureOutput2 = exporter.formatter.format(decoded)

        #expect(featureOutput1 == featureOutput2)
    }
}
