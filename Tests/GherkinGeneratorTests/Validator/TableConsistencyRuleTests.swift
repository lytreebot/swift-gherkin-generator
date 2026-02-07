import Testing

@testable import GherkinGenerator

@Suite("TableConsistencyRule")
struct TableConsistencyRuleTests {

    private let rule = TableConsistencyRule()

    @Test("Consistent table passes")
    func consistentTable() {
        let feature = Feature(
            title: "Pricing",
            children: [
                .scenario(
                    Scenario(
                        title: "Prices",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "the following prices",
                                dataTable: DataTable(rows: [
                                    ["Quantity", "Price"],
                                    ["1-10", "10"],
                                    ["11-50", "8"]
                                ])
                            ),
                            Step(keyword: .then, text: "ok")
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Inconsistent column count reports error")
    func inconsistentColumns() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Bad table",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "data",
                                dataTable: DataTable(rows: [
                                    ["a", "b", "c"],
                                    ["1", "2"]
                                ])
                            )
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 3, found: 2, row: 1)))
    }

    @Test("Empty cell reports error")
    func emptyCell() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Empty cell",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "data",
                                dataTable: DataTable(rows: [
                                    ["name", "value"],
                                    ["key", ""]
                                ])
                            )
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
    }

    @Test("Empty table passes (no rows to validate)")
    func emptyTable() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Empty",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "data",
                                dataTable: DataTable(rows: [])
                            )
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.isEmpty)
    }

    @Test("Examples tables are validated")
    func examplesTableValidated() {
        let feature = Feature(
            title: "Test",
            children: [
                .outline(
                    ScenarioOutline(
                        title: "Outline",
                        steps: [
                            Step(keyword: .given, text: "<a>"),
                            Step(keyword: .then, text: "<b>")
                        ],
                        examples: [
                            Examples(
                                table: DataTable(rows: [
                                    ["a", "b"],
                                    ["1"]
                                ]))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 2, found: 1, row: 1)))
    }

    @Test("Tables in background are validated")
    func backgroundTableValidated() {
        let feature = Feature(
            title: "Test",
            background: Background(steps: [
                Step(
                    keyword: .given,
                    text: "setup data",
                    dataTable: DataTable(rows: [
                        ["x", "y"],
                        ["1", ""]
                    ])
                )
            ]),
            children: []
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
    }

    @Test("Tables inside rules are validated")
    func tablesInRuleValidated() {
        let feature = Feature(
            title: "Test",
            children: [
                .rule(
                    Rule(
                        title: "My rule",
                        children: [
                            .scenario(
                                Scenario(
                                    title: "In rule",
                                    steps: [
                                        Step(
                                            keyword: .given,
                                            text: "data",
                                            dataTable: DataTable(rows: [
                                                ["a"],
                                                ["b", "c"]
                                            ])
                                        )
                                    ]
                                ))
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.inconsistentTableColumns(expected: 1, found: 2, row: 1)))
    }

    @Test("Multiple errors in one table are all reported")
    func multipleErrors() {
        let feature = Feature(
            title: "Test",
            children: [
                .scenario(
                    Scenario(
                        title: "Many issues",
                        steps: [
                            Step(
                                keyword: .given,
                                text: "data",
                                dataTable: DataTable(rows: [
                                    ["a", "b"],
                                    ["", ""],
                                    ["x"]
                                ])
                            )
                        ]
                    ))
            ]
        )
        let errors = rule.validate(feature)
        #expect(errors.contains(.emptyTableCell(row: 1, column: 0)))
        #expect(errors.contains(.emptyTableCell(row: 1, column: 1)))
        #expect(errors.contains(.inconsistentTableColumns(expected: 2, found: 1, row: 2)))
    }
}
