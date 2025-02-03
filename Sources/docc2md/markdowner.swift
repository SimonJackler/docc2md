/// Generates Markdown from a given DocC archive.
///
/// - Parameter archive: The `DocCArchive` instance to convert to Markdown.
/// - Returns: A `String` containing the Markdown representation of the provided DocC archive.
func generateMarkdown(from archive: DocCArchive) -> String {
    var markdown = ""

    if let roleHeading = archive.metadata.roleHeading {
        markdown += "*\(roleHeading)*\n\n"
    }
    if let title = archive.metadata.title {
        markdown += "# \(title)\n\n"
    }

    if let abstract = archive.abstract {
        let abstractText = renderInlineContent(abstract, archive: archive)
        if !abstractText.isEmpty {
            markdown += "\(abstractText)\n\n"
        }
    }

    if let primaryContentSections = archive.primaryContentSections {
        for contentSection in primaryContentSections {
            switch contentSection.kind {
            case "content":
                if let rendered = contentSection.content {
                    for item in rendered {
                        switch item.type {
                        case "heading":
                            if let level = item.level, let text = item.text {
                                markdown += "\(String(repeating: "#", count: level)) \(text)\n\n"
                            }
                        case "paragraph":
                            if let inline = item.inlineContent {
                                let paragraphText = renderInlineContent(inline, archive: archive)
                                markdown += "\(paragraphText)\n\n"
                            }
                        case "unorderedList":
                            if let listItems = item.items {
                                for listItem in listItems {
                                    // Each list item might contain multiple paragraphs or inline content
                                    // For simplicity, flatten them into a single line
                                    let bulletText = listItem.content.map {
                                        renderInlineContent(
                                            $0.inlineContent ?? [], archive: archive)
                                    }.joined()
                                    markdown += "- \(bulletText)\n"
                                }
                                markdown += "\n"
                            }
                        case "codeListing":
                            // A multiline code snippet
                            if let codeLines = item.code {
                                let syntax = item.syntax ?? ""
                                markdown += "```\(syntax)\n"
                                codeLines.forEach { markdown += $0 + "\n" }
                                markdown += "```\n\n"
                            }
                        default:
                            break
                        }
                    }
                }
            case "declarations":
                // Render declarations (API signatures)
                if let declarations = contentSection.declarations {
                    markdown += "### Declarations\n\n"
                    for declaration in declarations {
                        if let tokens = declaration.tokens {
                            let codeLine = tokens.map { $0.text }.joined()
                            markdown += "```\n\(codeLine)\n```\n\n"
                        }
                    }
                }
            default:
                break
            }
        }
    }

    if let topicSections = archive.topicSections {
        markdown += "## Topics\n\n"

        for topicSection in topicSections {
            markdown += "### \(topicSection.title)\n\n"

            for identifier in topicSection.identifiers {
                // Some references can have type == "unresolvable" or missing required fields
                guard
                    let reference = archive.references[identifier],
                    reference.type != "unresolvable",
                    let refURL = reference.url,
                    let refTitle = reference.title
                else { continue }

                var title = ""
                var description = ""

                if let fragment = reference.fragments,
                    let keyword = fragment.first(where: { $0.kind == "keyword" })
                {
                    title = "- [\(refTitle)](\(refURL)) `\(keyword.text)`"
                } else {
                    title = "- [\(refTitle)](\(refURL))"
                }

                if let abstract = reference.abstract {
                    let abstractText = renderInlineContent(abstract, archive: archive)
                    if !abstractText.isEmpty {
                        description = "  \(abstractText)"
                    }
                }
                markdown += title + "\n\n"
                markdown += description + "\n\n"
            }
            markdown += "\n"
        }
    }

    if let seeAlso = archive.seeAlsoSections, !seeAlso.isEmpty {
        markdown += "## See also\n\n"

        for section in seeAlso {
            if let title = section.title {
                markdown += "### \(title)\n\n"
            }
            if let identifiers = section.identifiers {
                for identifier in identifiers {
                    guard
                        let reference = archive.references[identifier],
                        reference.type != "unresolvable",
                        let refURL = reference.url,
                        let refTitle = reference.title
                    else { continue }
                    markdown += "- [\(refTitle)](\(refURL))\n"
                }
            }
            markdown += "\n"
        }
    }

    if let relationships = archive.relationshipsSections, !relationships.isEmpty {
        for relSection in relationships {
            if let title = relSection.title {
                markdown += "## \(title)\n\n"
            }
            if let identifiers = relSection.identifiers {
                for identifier in identifiers {
                    guard
                        let reference = archive.references[identifier],
                        reference.type != "unresolvable",
                        let refURL = reference.url,
                        let refTitle = reference.title
                    else { continue }
                    markdown += "- [\(refTitle)](\(refURL))\n"
                }
            }
            markdown += "\n"
        }
    }

    return markdown
}

/// Renders the inline content for the given parameters.
/// 
/// This function processes the inline content and returns the rendered result.
/// 
/// - Parameters:
///   - content: The inline content to be rendered.
///   - options: Additional options to customize the rendering process.
/// - Returns: The rendered inline content as a string.
private func renderInlineContent(
    _ inlineItems: [DocCArchive.InlineContent],
    archive: DocCArchive
) -> String {
    return inlineItems.map { item in
        switch item.type {
        case "reference":
            return renderReference(item, archive: archive)
        case "image":
            return renderImage(item, archive: archive)
        default:
            return renderTextOrCode(item)
        }
    }.joined()
}

/// Renders a reference from the given `DocCArchive.InlineContent` item.
/// 
/// - Parameters:
///   - item: The `DocCArchive.InlineContent` item to be rendered.
///   - archive: The `DocCArchive` containing the item.
/// - Returns: A `String` representation of the rendered reference.

private func renderReference(_ item: DocCArchive.InlineContent, archive: DocCArchive) -> String {
    guard let refID = item.identifier else {
        return item.text ?? ""
    }
    if let ref = archive.references[refID],
       let url = ref.url,
       let title = ref.title {
        return "[\(title)](\(url))"
    } else {
        return item.text ?? refID
    }
}

/// Renders an image from the given `DocCArchive.InlineContent` item.
/// 
/// - Parameters:
///   - item: The `DocCArchive.InlineContent` item that contains the image data.
///   - archive: The `DocCArchive` instance that contains the context for the image.
/// - Returns: A `String` representation of the rendered image.
private func renderImage(_ item: DocCArchive.InlineContent, archive: DocCArchive) -> String {
    guard let identifier = item.identifier,
          let reference = archive.references[identifier],
          let variants = reference.variants else {
        return item.text ?? ""
    }

    let alt = reference.alt ?? "Image"

    if variants.count > 1 && isForGitHub {
        return renderPictureTag(darkLightPairs: variants, alt: alt)
    } else {
        if let firstVariant = variants.first {
            return "![\(alt)](\(firstVariant.url))\n"
        }
        return ""
    }
}

/// Renders an HTML `<picture>` tag with the provided image variants and alt text.
/// 
/// - Parameters:
///   - darkLightPairs: An array of `DocCArchive.Reference.ImgVariant` representing the image variants for dark and light modes.
///   - alt: A `String` representing the alternative text for the image.
/// - Returns: A `String` containing the HTML `<picture>` tag with the specified image variants and alt text.
private func renderPictureTag(darkLightPairs: [DocCArchive.Reference.ImgVariant], alt: String) -> String {
    var result = "<picture>\n"
    if let dark = darkLightPairs.first(where: { $0.traits.contains("dark") }) {
        result += "  <source media=\"(prefers-color-scheme: dark)\" srcset=\"\(dark.url)\">\n"
    }
    if let light = darkLightPairs.first(where: { $0.traits.contains("light") }) {
        result += "  <img alt=\"\(alt)\" src=\"\(light.url)\">\n"
    }
    result += "</picture>\n"
    return result
}

/// Renders the given inline content.
/// 
/// - Parameter item: The inline content to be rendered.
/// - Returns: A string representation of the inline content, formatted as either text or code.
private func renderTextOrCode(_ item: DocCArchive.InlineContent) -> String {
    var output = ""
    if let text = item.text {
        output += text
    }
    if let code = item.code {
        output += "`\(code)`"
    }
    return output
}
