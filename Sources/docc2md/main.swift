import Foundation

let help = """
    Usage: docc2md [-g/--github] <doccarchivePath> <outputFolder>
    
    Example:
    
      docc2md -g SlothCreator.doccarchive /tmp/SlothCreator/
    
    Options:
    
      -g/--github: format the markdown for GitHub, enabling dark/light image variants
    """

private var isG = false
private var argIndex = 1

if CommandLine.arguments.count > argIndex {
    let firstArg = CommandLine.arguments[argIndex]
    if firstArg == "-g" || firstArg == "--github" {
        isG = true
        argIndex = 2
    }
}

guard CommandLine.arguments.count > argIndex else {
    print(help)
    exit(1)
}

let inputPath = CommandLine.arguments[argIndex]
var outputPath = "./"
if CommandLine.arguments.count >= argIndex + 2 {
     outputPath = CommandLine.arguments[argIndex + 1]
}
let isForGitHub = isG

let fileManager = FileManager.default

do {
    if fileManager.fileExists(atPath: inputPath, isDirectory: nil) {
        let pathExtension = inputPath.split(separator: ".").last
        if pathExtension == "doccarchive" || pathExtension == "doccarchive/" {
            try copyImages(from: inputPath, to: outputPath)
            let moduleName = ((inputPath as NSString).lastPathComponent  as NSString).deletingPathExtension
            let dataPath = inputPath + "/data/documentation/"
            let processedFileCount = try processJsonFolder(at: dataPath, to: outputPath, moduleName: moduleName)
            print("Converted \(processedFileCount) files to markdown to \(outputPath)")
            exit(0)
        } else {
            throw Docc2mdError.fileError("Error: '\(inputPath)' is not an Swift DocC archive.")
        }
    } else {
        throw Docc2mdError.fileError("Error: '\(inputPath)' does not exist.")
    }
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
