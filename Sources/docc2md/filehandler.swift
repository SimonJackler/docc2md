import Foundation

/// Copies the 'images' folder from the archive folder to the output folder.
///
/// - Parameters:
///   - archiveFolder: The path to the archive folder containing the 'images' folder.
///   - outputFolder: The path to the output folder where the 'images' folder should be copied.
func copyImages(from archiveFolder: String, to outputFolder: String) throws {
    let fileManager = FileManager.default
    let imagesFolderPath = (archiveFolder as NSString).appendingPathComponent("images")
    let destinationPath = ((outputFolder as NSString).appendingPathComponent("docs") as NSString).appendingPathComponent("images")

    if fileManager.fileExists(atPath: imagesFolderPath) {
        try fileManager.createDirectory(
            atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
        let contents = try fileManager.contentsOfDirectory(atPath: imagesFolderPath)
        for item in contents { 
            let sourcePath = (imagesFolderPath as NSString).appendingPathComponent(item)
            let destPath = (destinationPath as NSString).appendingPathComponent(item)
            if fileManager.fileExists(atPath: destPath) {
                try fileManager.removeItem(atPath: destPath)
            }
            try fileManager.copyItem(atPath: sourcePath, toPath: destPath)
        }
    } else {
        throw Docc2mdError.fileError("Images folder does not exist at path: \(imagesFolderPath)")
    }
}

/// Processes JSON files in the specified data folder and outputs the results to the specified output folder.
///
/// - Parameters:
///   - dataFolder: The path to the folder containing the JSON files to be processed.
///   - outputFolder: The path to the folder where the processed files will be saved.
/// - Throws: An error if the processing fails.
/// - Returns: The number of files successfully processed.
func processJsonFolder(at dataFolder: String, to outputFolder: String, moduleName: String) throws -> Int {
    // Enumerate subpaths
    let fileManager = FileManager.default
    guard let enumerator = fileManager.enumerator(atPath: dataFolder) else {
        throw Docc2mdError.fileError("Could not enumerate folder: \(dataFolder)")
    }
    var count = 0
    for case let subpath as String in enumerator {
        if subpath.lowercased().hasSuffix(".json") {
            let inputPath = (dataFolder as NSString).appendingPathComponent(subpath)
            let outputSubpath = (subpath as NSString).deletingPathExtension

            let outputPath: String
            if outputSubpath == moduleName {
                outputPath = (outputFolder as NSString).appendingPathComponent("README.md")
            } else {
                outputPath = ((outputFolder as NSString).appendingPathComponent("docs") as NSString).appendingPathComponent(outputSubpath + ".md")
            }
            try processJsonFile(at: inputPath, to: outputPath)
            count += 1
        }
    }
    return count
}

/// Processes a JSON file from the specified input path and writes the result to the specified output path.
/// 
/// - Parameters:
///   - inputPath: The file path of the input JSON file.
///   - outputPath: The file path where the processed output should be written.
/// - Throws: An error if the file cannot be read or written.
func processJsonFile(at inputPath: String, to outputPath: String) throws {
    let jsonData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
    let decoder = JSONDecoder()
    let archive = try decoder.decode(DocCArchive.self, from: jsonData)

    var markdown = generateMarkdown(from: archive)
    let outURL = URL(fileURLWithPath: outputPath)
    markdown = fixLinks(markdown, relativeTo: outputPath)

    try FileManager.default.createDirectory(
        at: outURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil)

    try markdown.write(to: outURL, atomically: true, encoding: .utf8)
}

/// Fixes the links in the given markdown content to be relative to the specified output path.
///
/// - Parameters:
///   - markdown: The markdown content as a string.
///   - outputPath: The path to which the links should be made relative.
/// - Returns: A new markdown string with the links adjusted to be relative to the specified output path.
func fixLinks(_ markdown: String, relativeTo outputPath: String) -> String {
    let docPath = outputPath.split(separator: "/").dropFirst().dropFirst().joined(separator: "/")
    let outURL = URL(fileURLWithPath: "/" + docPath)

    func replaceLinks(in wholeMatch: String, url: String) -> String {
            if url.contains("http") {
                return wholeMatch
            }
            let path = "/docs".appending(url.replacingOccurrences(of: "/documentation", with: ""))
            var linkURL = URL(fileURLWithPath: path)
            let ext = linkURL.pathExtension
            if ext != "md" && ext != "png" && ext != "jpg" && ext != "jpeg" && ext != "gif" && ext != "svg" {
                linkURL = URL(fileURLWithPath: "\(path).md")
            }
            if let newUrl = relativePath(from: outURL, toPath: linkURL) {
                return wholeMatch.replacing(url, with: newUrl)
            }
            return wholeMatch
    }
    
    var updatedLinks = markdown.replacing(
        /\]\((?<url>.+)\)(\s|$)/,
        with: { match in
            return replaceLinks(in: "\(match.0)", url: "\(match.url)")
        }
    )

    updatedLinks = updatedLinks.replacing(
        /src.*\=\"(?<url>.+)\"\>/,
        with: { match in
            return replaceLinks(in: "\(match.0)", url: "\(match.url)")
        }
    )
    return updatedLinks
}

/// Computes the relative path from a base URL to a target URL.
///
/// - Parameters:
///   - base: The base URL from which the relative path should be calculated.
///   - target: The target URL to which the relative path should be calculated.
/// - Returns: A `String` representing the relative path from the base URL to the target URL, or `nil` if the relative path could not be determined.
func relativePath(from base: URL, toPath target: URL) -> String? {
    guard target.isFileURL && base.isFileURL else {
        return nil
    }
    var workBase = base
    if workBase.pathExtension != "" {
        workBase = workBase.deletingLastPathComponent()
    }
    // Make paths absolute:
    let destComponents = target.standardized.resolvingSymlinksInPath().pathComponents
    let baseComponents = workBase.standardized.resolvingSymlinksInPath().pathComponents
    // Number of common path components:
    var i = 0
    while i < destComponents.count && i < baseComponents.count
        && destComponents[i] == baseComponents[i]
    {
        i += 1
    }
    // Build relative path:
    var relComponents = Array(repeating: "..", count: baseComponents.count - i)
    relComponents.append(contentsOf: destComponents[i...])
    return relComponents.joined(separator: "/")
}
