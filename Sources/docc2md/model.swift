
enum Docc2mdError: Error {
    case fileError(String)
}

struct DocCArchive: Codable {
    struct Variant: Codable {
        let traits: [Trait]
        let paths: [String]?
        let url: String?
    }

    struct Trait: Codable {
        let interfaceLanguage: String?
    }

    struct Identifier: Codable {
        let url: String
        let interfaceLanguage: String
    }

    struct Section: Codable {
        let identifiers: [String]
        let title: String
        let anchor: String?
        let generated: Bool?
    }

    struct SeeAlsoSection: Codable {
        let title: String?
        let generated: Bool?
        let identifiers: [String]?
        let anchor: String?
    }

    struct RelationshipsSection: Codable {
        let title: String?
        let identifiers: [String]?
        let kind: String?
        let type: String?
    }

    struct PrimaryContentSection: Codable {
        let kind: String

        let content: [RenderedContent]?

        let declarations: [Declaration]?
    }

    struct RenderedContent: Codable {
        let text: String?
        let type: String?
        let level: Int?
        let anchor: String?

        // For paragraphs, headings, or lists:
        let inlineContent: [InlineContent]?
        let items: [ListItem]?

        // For code listings:
        let syntax: String?
        let code: [String]?
    }

    struct InlineContent: Codable {
        let text: String?
        let type: String?
        let code: String?

        let identifier: String?

        let isActive: Bool?
    }

    struct ListItem: Codable {
        let content: [RenderedContent]
    }

    struct Declaration: Codable {
        let tokens: [Token]?
        let platforms: [String]?
        let languages: [String]?
    }

    struct Token: Codable {
        let kind: String
        let text: String
    }

    struct Metadata: Codable {
        let roleHeading: String?
        let role: String?
        let symbolKind: String?
        let modules: [Module]?
        let title: String?
        let externalID: String?

        let fragments: [Fragment]?
        let navigatorTitle: [Fragment]?
    }

    struct Fragment: Codable {
        let kind: String
        let text: String
        let code: String?
    }

    struct Module: Codable {
        let name: String
    }

    struct SchemaVersion: Codable {
        let minor: Int
        let patch: Int
        let major: Int
    }

    struct Hierarchy: Codable {
        let paths: [[String]]
    }

    let variants: [Variant]
    let kind: String
    let abstract: [InlineContent]?
    let identifier: Identifier
    let hierarchy: Hierarchy
    let sections: [String]
    let schemaVersion: SchemaVersion
    let metadata: Metadata
    let topicSections: [Section]?

    let seeAlsoSections: [SeeAlsoSection]?
    let relationshipsSections: [RelationshipsSection]?

    let primaryContentSections: [PrimaryContentSection]?
    let references: [String: Reference]

    struct Reference: Codable {
        let url: String?
        let type: String?
        let role: String?
        let title: String?
        let abstract: [InlineContent]?
        let kind: String?
        let identifier: String
        let fragments: [Fragment]?
        let navigatorTitle: [Fragment]?
        let alt: String?
        let variants: [ImgVariant]?
        
        struct ImgVariant: Codable {
            let traits: [String]
            let url: String
        }
    }

    private enum CodingKeys: String, CodingKey {
        case variants
        case kind
        case abstract
        case identifier
        case hierarchy
        case sections
        case schemaVersion
        case metadata
        case topicSections
        case primaryContentSections
        case references
        case seeAlsoSections
        case relationshipsSections
    }
}