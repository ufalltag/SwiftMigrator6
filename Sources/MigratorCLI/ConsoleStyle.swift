import Foundation

/// Раскраска вывода ANSI-кодами
enum ConsoleStyle {

    private static let colorsAllowed: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["NO_COLOR"] == nil && environment["TERM"] != "dumb"
    }()

    static let stdoutColored = colorsAllowed && isatty(STDOUT_FILENO) == 1
    static let stderrColored = colorsAllowed && isatty(STDERR_FILENO) == 1

    static func green(_ text: String, colored: Bool = stdoutColored) -> String {
        wrap(text, code: "32", colored: colored)
    }

    static func red(_ text: String, colored: Bool = stdoutColored) -> String {
        wrap(text, code: "31", colored: colored)
    }

    static func cyan(_ text: String, colored: Bool = stdoutColored) -> String {
        wrap(text, code: "36", colored: colored)
    }

    static func bold(_ text: String, colored: Bool = stdoutColored) -> String {
        wrap(text, code: "1", colored: colored)
    }

    static func dim(_ text: String, colored: Bool = stdoutColored) -> String {
        wrap(text, code: "2", colored: colored)
    }

    private static func wrap(_ text: String, code: String, colored: Bool) -> String {
        colored ? "\u{1B}[\(code)m\(text)\u{1B}[0m" : text
    }
}
