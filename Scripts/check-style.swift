import Foundation
import SwiftParser
import SwiftSyntax

// Parse Swift syntax instead of counting braces inside strings and comments.
final class StyleAudit: SyntaxVisitor {
  let path: String
  let locations: SourceLocationConverter
  var failures: [String] = []
  var longestFunction: Int = 0

  init(path: String, tree: SourceFileSyntax) {
    self.path = path
    locations = SourceLocationConverter(fileName: path, tree: tree)
    super.init(viewMode: .sourceAccurate)
  }

  override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    if let body = node.body { inspect(body, name: node.name.text) }
    return .visitChildren
  }

  override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    if let body = node.body { inspect(body, name: "init") }
    return .visitChildren
  }

  override func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    if let body = node.body { inspect(body, name: node.accessorSpecifier.text) }
    return .visitChildren
  }

  override func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
    guard let block = node.accessorBlock, case .getter = block.accessors else { return .visitChildren }
    inspectRange(first: block.leftBrace.endPosition, last: block.rightBrace.positionAfterSkippingLeadingTrivia,
                 name: node.pattern.trimmedDescription)
    return .visitChildren
  }

  private func inspect(_ body: CodeBlockSyntax, name: String) {
    inspectRange(first: body.leftBrace.endPosition, last: body.rightBrace.positionAfterSkippingLeadingTrivia, name: name)
  }

  private func inspectRange(first: AbsolutePosition, last: AbsolutePosition, name: String) {
    let firstLine = locations.location(for: first).line
    let lastLine = locations.location(for: last).line
    let length = max(1, lastLine - firstLine - 1)
    longestFunction = max(longestFunction, length)
    if length > 20 {
      failures.append("\(path):\(firstLine): \(name) has \(length) body lines; expected at most 20.")
    }
  }

}

let sourceRoot = URL(fileURLWithPath: "PerDay")
let sourceFiles = FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)!
var failures: [String] = []
var fileCount: Int = 0
var largestFile: Int = 0
var longestFunction: Int = 0
for case let file as URL in sourceFiles where file.pathExtension == "swift" {
  let source = try String(contentsOf: file, encoding: .utf8)
  let lineCount = source.split(separator: "\n", omittingEmptySubsequences: false).count - 1
  fileCount += 1
  largestFile = max(largestFile, lineCount)
  if lineCount >= 500 { failures.append("\(file.path): \(lineCount) lines; expected fewer than 500.") }
  let tree = Parser.parse(source: source)
  let audit = StyleAudit(path: file.path, tree: tree)
  audit.walk(tree)
  longestFunction = max(longestFunction, audit.longestFunction)
  failures.append(contentsOf: audit.failures)
}
for failure in failures { print(failure) }
print("Checked \(fileCount) Swift files; largest file: \(largestFile) lines; longest function body: \(longestFunction) lines.")
exit(failures.isEmpty ? 0 : 1)
