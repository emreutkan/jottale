import Foundation
import ZIPFoundation  // You must add ZIPFoundation via Swift Package Manager

/// Parses an ePub file into a ``Book`` metadata object and an array of ``Chapter`` objects.
///
/// **ePub format overview:**
/// An ePub is a ZIP archive containing:
/// - `META-INF/container.xml` – points to the OPF package document
/// - `*.opf` – lists all content files (spine order) and metadata
/// - `*.xhtml` / `*.html` – individual content documents
/// - A cover image (referenced in the OPF metadata)
final class ePubParserService {

    // MARK: - Public API

    /// Parses the ePub at `url` and returns a ``Book`` plus its ``Chapter`` list.
    ///
    /// - Parameter url: File URL of the `.epub` to parse.
    /// - Returns: A tuple of the parsed ``Book`` and its ordered ``Chapter`` array.
    /// - Throws: ``ePubParserError`` if the file cannot be read or parsed.
    func parse(ePubAt url: URL) throws -> (Book, [Chapter]) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: tempDir,
                                                withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // 1. Unzip the ePub
        try FileManager.default.unzipItem(at: url, to: tempDir)

        // 2. Locate the OPF document
        let opfURL = try findOPF(in: tempDir)
        let opfDir = opfURL.deletingLastPathComponent()

        // 3. Parse OPF for metadata and spine
        let opfData = try Data(contentsOf: opfURL)
        let opfParser = OPFParser(data: opfData, baseURL: opfDir)
        let metadata = try opfParser.parseMetadata()
        let spineItems = try opfParser.parseSpineItems()

        // 4. Copy ePub to Documents and record the path
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destURL = docsDir.appendingPathComponent(url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.copyItem(at: url, to: destURL)
        }

        // 5. Copy cover image if present
        var coverImagePath: String?
        if let coverSrc = metadata.coverImagePath {
            let coverSourceURL = opfDir.appendingPathComponent(coverSrc)
            let coverDest = docsDir.appendingPathComponent("covers")
                .appendingPathComponent(url.deletingPathExtension().lastPathComponent + "_cover." + coverSourceURL.pathExtension)
            try? FileManager.default.createDirectory(
                at: coverDest.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: coverDest.path) {
                try? FileManager.default.copyItem(at: coverSourceURL, to: coverDest)
            }
            coverImagePath = coverDest.path
        }

        // 6. Build Book model
        let book = Book(
            title: metadata.title,
            author: metadata.author,
            coverImagePath: coverImagePath,
            filePath: url.lastPathComponent
        )

        // 7. Parse chapters from spine
        let chapters = try spineItems.enumerated().map { index, item -> Chapter in
            let htmlURL = opfDir.appendingPathComponent(item)
            let rawHTML = (try? String(contentsOf: htmlURL, encoding: .utf8)) ?? ""
            let cleanText = stripHTML(rawHTML)
            let chapterTitle = extractChapterTitle(from: rawHTML) ?? "Chapter \(index + 1)"
            return Chapter(title: chapterTitle, content: cleanText, index: index)
        }

        return (book, chapters)
    }

    // MARK: - Private Helpers

    /// Reads `META-INF/container.xml` to find the path to the OPF file.
    private func findOPF(in directory: URL) throws -> URL {
        let containerURL = directory.appendingPathComponent("META-INF/container.xml")
        let data = try Data(contentsOf: containerURL)
        let xml = try XMLDocument(data: data)
        guard let rootFilePath = try xml.nodes(forXPath: "//*[@media-type='application/oebps-package+xml']/@full-path").first?.stringValue
                ?? xml.nodes(forXPath: "//@full-path").first?.stringValue else {
            throw ePubParserError.missingOPF
        }
        return directory.appendingPathComponent(rootFilePath)
    }

    /// Removes HTML tags and decodes common HTML entities to produce clean plain text.
    private func stripHTML(_ html: String) -> String {
        // Use NSAttributedString for robust HTML-to-plain-text conversion
        guard let data = html.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            // Fallback: naive regex strip
            return html.replacingOccurrences(of: "<[^>]+>",
                                              with: " ",
                                              options: .regularExpression)
                       .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Attempts to extract a chapter title from `<title>` or the first `<h1>`–`<h3>` tag.
    private func extractChapterTitle(from html: String) -> String? {
        let patterns = ["<title[^>]*>([^<]+)</title>",
                        "<h[1-3][^>]*>([^<]+)</h[1-3]>"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}

// MARK: - OPFParser (internal helper)

/// Lightweight SAX-style parser for the OPF package document.
private final class OPFParser: NSObject, XMLParserDelegate {

    struct Metadata {
        var title: String = "Unknown Title"
        var author: String = "Unknown Author"
        var coverImagePath: String?
    }

    private let data: Data
    private let baseURL: URL
    private var metadata = Metadata()
    private var spineIDs: [String] = []
    private var manifestItems: [String: String] = [:]  // id -> href
    private var coverImageID: String?

    private var currentElement = ""
    private var currentText = ""

    init(data: Data, baseURL: URL) {
        self.data = data
        self.baseURL = baseURL
    }

    func parseMetadata() throws -> Metadata {
        try runParser()
        return metadata
    }

    func parseSpineItems() throws -> [String] {
        try runParser()
        return spineIDs.compactMap { manifestItems[$0] }
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?,
                attributes: [String: String]) {
        currentElement = elementName.lowercased()
        currentText = ""

        switch currentElement {
        case "item":
            if let id = attributes["id"], let href = attributes["href"] {
                manifestItems[id] = href
                // Detect cover image item
                if let props = attributes["properties"], props.contains("cover-image") {
                    coverImageID = id
                }
                if let mediaType = attributes["media-type"], mediaType.hasPrefix("image/"),
                   id.lowercased().contains("cover") {
                    coverImageID = id
                }
            }
        case "itemref":
            if let idref = attributes["idref"] {
                spineIDs.append(idref)
            }
        case "meta":
            if attributes["name"] == "cover", let content = attributes["content"] {
                coverImageID = content
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch elementName.lowercased() {
        case "dc:title", "title":
            if !text.isEmpty { metadata.title = text }
        case "dc:creator", "creator":
            if !text.isEmpty { metadata.author = text }
        default:
            break
        }
    }

    // MARK: - Private

    private func runParser() throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let error = parser.parserError {
            throw ePubParserError.xmlParseFailed(error)
        }
        if let coverID = coverImageID {
            metadata.coverImagePath = manifestItems[coverID]
        }
    }
}

// MARK: - Errors

enum ePubParserError: LocalizedError {
    case missingOPF
    case xmlParseFailed(Error)

    var errorDescription: String? {
        switch self {
        case .missingOPF:
            return "Could not locate the OPF package document inside the ePub."
        case .xmlParseFailed(let error):
            return "XML parsing failed: \(error.localizedDescription)"
        }
    }
}
