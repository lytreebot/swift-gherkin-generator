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

@Suite("ExcelParser")
struct ExcelParserTests {

    // MARK: - Basic Parsing

    @Test("Parse basic Excel with default columns")
    func basicExcel() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Login", "valid credentials", "user logs in", "dashboard shown"],
            ["Logout", "a logged-in user", "user logs out", "login page shown"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)
        let feature = try parser.parse(xlsx, featureTitle: "Auth")

        #expect(feature.title == "Auth")
        #expect(feature.children.count == 2)

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.title == "Login")
        #expect(first.steps.count == 3)
        #expect(first.steps[0].keyword == .given)
        #expect(first.steps[0].text == "valid credentials")
        #expect(first.steps[1].keyword == .when)
        #expect(first.steps[1].text == "user logs in")
        #expect(first.steps[2].keyword == .then)
        #expect(first.steps[2].text == "dashboard shown")
    }

    // MARK: - Tags Column

    @Test("Parse Excel with tags column")
    func tagsColumn() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then", "Tags"],
            ["Login", "valid creds", "user logs in", "dashboard", "@smoke @critical"],
            ["Logout", "logged-in user", "user logs out", "login page", "@regression"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then",
            tagColumn: "Tags"
        )
        let parser = ExcelParser(configuration: config)
        let feature = try parser.parse(xlsx, featureTitle: "Auth")

        guard case .scenario(let first) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(first.tags.count == 2)
        #expect(first.tags[0].name == "smoke")
        #expect(first.tags[1].name == "critical")
    }

    // MARK: - Error Handling

    @Test("Missing required column throws error")
    func missingColumn() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "Then"],
            ["Login", "valid credentials", "dashboard shown"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(xlsx, featureTitle: "Auth")
        }
    }

    @Test("Invalid xlsx data throws error")
    func invalidData() {
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(Data([0, 1, 2, 3]), featureTitle: "Bad")
        }
    }

    @Test("Empty worksheet throws error")
    func emptyWorksheet() throws {
        let xlsx = TestXLSXBuilder.build(rows: [])

        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)

        #expect(throws: GherkinError.self) {
            try parser.parse(xlsx, featureTitle: "Empty")
        }
    }

    // MARK: - Empty Rows

    @Test("Rows with empty scenario title are skipped")
    func emptyRowsSkipped() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Login", "valid credentials", "user logs in", "dashboard shown"],
            ["", "", "", ""],
            ["Logout", "a logged-in user", "user logs out", "login page shown"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)
        let feature = try parser.parse(xlsx, featureTitle: "Auth")

        #expect(feature.children.count == 2)
    }

    // MARK: - Single Scenario

    @Test("Parse Excel with a single scenario")
    func singleScenario() throws {
        let xlsx = TestXLSXBuilder.build(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Add product", "an empty cart", "I add a product", "the cart has 1 item"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)
        let feature = try parser.parse(xlsx, featureTitle: "Shopping")

        #expect(feature.children.count == 1)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Add product")
    }

    // MARK: - No Shared Strings

    @Test("Parse Excel without shared strings file")
    func noSharedStrings() throws {
        let xlsx = TestXLSXBuilder.buildWithInlineStrings(rows: [
            ["Scenario", "Given", "When", "Then"],
            ["Login", "valid credentials", "user logs in", "dashboard shown"]
        ])
        let config = ExcelImportConfiguration(
            scenarioColumn: "Scenario",
            givenColumn: "Given",
            whenColumn: "When",
            thenColumn: "Then"
        )
        let parser = ExcelParser(configuration: config)
        let feature = try parser.parse(xlsx, featureTitle: "Auth")

        #expect(feature.children.count == 1)
        guard case .scenario(let scenario) = feature.children[0] else {
            Issue.record("Expected scenario")
            return
        }
        #expect(scenario.title == "Login")
        #expect(scenario.steps[0].text == "valid credentials")
    }
}

// MARK: - Test XLSX Builder

/// Builds minimal `.xlsx` (OOXML ZIP) archives for testing.
enum TestXLSXBuilder {

    /// Builds an `.xlsx` file using shared strings.
    static func build(rows: [[String]]) -> Data {
        var stringTable: [String] = []
        var stringIndex: [String: Int] = [:]

        for row in rows {
            for cell in row where stringIndex[cell] == nil {
                stringIndex[cell] = stringTable.count
                stringTable.append(cell)
            }
        }

        let ssXML = buildSharedStringsXML(strings: stringTable)
        let sheetXML = buildSheetXML(rows: rows, stringIndex: stringIndex)

        return buildXLSXArchive(
            sharedStrings: ssXML,
            sheet: sheetXML
        )
    }

    /// Builds an `.xlsx` file using inline strings (no sharedStrings.xml).
    static func buildWithInlineStrings(rows: [[String]]) -> Data {
        let sheetXML = buildInlineSheetXML(rows: rows)
        return buildXLSXArchive(sharedStrings: nil, sheet: sheetXML)
    }

    // MARK: - XML Generation

    private static func buildSharedStringsXML(strings: [String]) -> Data {
        var xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" \
            count="\(strings.count)" uniqueCount="\(strings.count)">

            """
        for string in strings {
            xml += "  <si><t>\(escapeXML(string))</t></si>\n"
        }
        xml += "</sst>"
        return Data(xml.utf8)
    }

    private static func buildSheetXML(
        rows: [[String]],
        stringIndex: [String: Int]
    ) -> Data {
        var xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <sheetData>

            """
        for (rowIdx, row) in rows.enumerated() {
            xml += "  <row r=\"\(rowIdx + 1)\">"
            for (colIdx, cell) in row.enumerated() {
                let ref = columnLetter(colIdx) + "\(rowIdx + 1)"
                if let idx = stringIndex[cell] {
                    xml += "<c r=\"\(ref)\" t=\"s\"><v>\(idx)</v></c>"
                }
            }
            xml += "</row>\n"
        }
        xml += "</sheetData>\n</worksheet>"
        return Data(xml.utf8)
    }

    private static func buildInlineSheetXML(rows: [[String]]) -> Data {
        var xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
            <sheetData>

            """
        for (rowIdx, row) in rows.enumerated() {
            xml += "  <row r=\"\(rowIdx + 1)\">"
            for (colIdx, cell) in row.enumerated() {
                let ref = columnLetter(colIdx) + "\(rowIdx + 1)"
                xml += "<c r=\"\(ref)\" t=\"inlineStr\"><is><t>"
                xml += "\(escapeXML(cell))</t></is></c>"
            }
            xml += "</row>\n"
        }
        xml += "</sheetData>\n</worksheet>"
        return Data(xml.utf8)
    }

    private static func buildContentTypesXML(includeSharedStrings: Bool) -> Data {
        var xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="rels" \
            ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Default Extension="xml" ContentType="application/xml"/>
            <Override PartName="/xl/workbook.xml" \
            ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
            <Override PartName="/xl/worksheets/sheet1.xml" \
            ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>

            """
        if includeSharedStrings {
            xml += """
                <Override PartName="/xl/sharedStrings.xml" \
                ContentType="application/vnd.openxmlformats-officedocument.\
                spreadsheetml.sharedStrings+xml"/>

                """
        }
        xml += "</Types>"
        return Data(xml.utf8)
    }

    private static func buildRelsXML() -> Data {
        let xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" \
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" \
            Target="xl/workbook.xml"/>
            </Relationships>
            """
        return Data(xml.utf8)
    }

    private static func buildWorkbookXML() -> Data {
        let xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" \
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
            <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
            </workbook>
            """
        return Data(xml.utf8)
    }

    private static func buildWorkbookRelsXML(includeSharedStrings: Bool) -> Data {
        var xml = """
            <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <Relationship Id="rId1" \
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" \
            Target="worksheets/sheet1.xml"/>

            """
        if includeSharedStrings {
            xml += """
                <Relationship Id="rId2" \
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/\
                sharedStrings" Target="sharedStrings.xml"/>

                """
        }
        xml += "</Relationships>"
        return Data(xml.utf8)
    }

    // MARK: - Archive Assembly

    private static func buildXLSXArchive(
        sharedStrings: Data?,
        sheet: Data
    ) -> Data {
        let hasSharedStrings = sharedStrings != nil
        var entries: [(String, Data)] = [
            ("[Content_Types].xml", buildContentTypesXML(includeSharedStrings: hasSharedStrings)),
            ("_rels/.rels", buildRelsXML()),
            ("xl/workbook.xml", buildWorkbookXML()),
            (
                "xl/_rels/workbook.xml.rels",
                buildWorkbookRelsXML(includeSharedStrings: hasSharedStrings)
            ),
            ("xl/worksheets/sheet1.xml", sheet)
        ]
        if let ssData = sharedStrings {
            entries.append(("xl/sharedStrings.xml", ssData))
        }
        return TestZIPBuilder.createZIP(entries: entries)
    }

    // MARK: - Helpers

    private static func columnLetter(_ index: Int) -> String {
        var result = ""
        var remaining = index
        repeat {
            guard let scalar = UnicodeScalar(65 + remaining % 26) else { break }
            result = String(Character(scalar)) + result
            remaining = remaining / 26 - 1
        } while remaining >= 0
        return result
    }

    private static func escapeXML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
