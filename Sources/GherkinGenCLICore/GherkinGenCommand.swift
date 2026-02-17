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

/// Root command for the `gherkin-gen` CLI tool.
///
/// This type lives in the `GherkinGenCLICore` library so that tests can
/// `@testable import GherkinGenCLICore` and call `parseAsRoot`.
/// The thin `@main` entry point in the `GherkinGenCLI` executable
/// simply invokes ``GherkinGen/main()``.
public struct GherkinGen: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "gherkin-gen",
        abstract: "Compose, validate, and convert Gherkin .feature files.",
        subcommands: [
            GenerateCommand.self,
            ValidateCommand.self,
            ParseCommand.self,
            ExportCommand.self,
            BatchExportCommand.self,
            ConvertCommand.self,
            LanguagesCommand.self
        ]
    )

    public init() {}
}
