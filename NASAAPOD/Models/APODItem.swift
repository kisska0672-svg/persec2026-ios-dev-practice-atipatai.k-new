import Foundation

struct APODItem: Decodable, Identifiable, Equatable, Hashable {
    var id: String { date }

    let copyright: String?
    let date: String
    let explanation: String
    let hdurl: URL?
    let mediaType: String
    let serviceVersion: String
    let title: String
    let url: URL?
    let thumbnailUrl: URL?

    enum CodingKeys: String, CodingKey {
        case copyright
        case date
        case explanation
        case hdurl
        case mediaType = "media_type"
        case serviceVersion = "service_version"
        case title
        case url
        case permalink
        case thumbnailUrl = "thumbnail_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        copyright = try container.decodeIfPresent(String.self, forKey: .copyright)?.strippingHTMLTags()
        date = try container.decode(String.self, forKey: .date)
        explanation = try container.decode(String.self, forKey: .explanation).strippingHTMLTags()
        hdurl = try container.decodeIfPresent(URL.self, forKey: .hdurl)
        mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType) ?? "image"
        serviceVersion = try container.decodeIfPresent(String.self, forKey: .serviceVersion) ?? "science.nasa.gov apod-basic"
        title = try container.decode(String.self, forKey: .title).strippingHTMLTags()

        let permalinkURL = try container.decodeIfPresent(URL.self, forKey: .permalink)
        let urlValue = try container.decodeIfPresent(URL.self, forKey: .url)
        url = permalinkURL ?? urlValue

        thumbnailUrl = try container.decodeIfPresent(URL.self, forKey: .thumbnailUrl)
    }

    init(
        copyright: String?,
        date: String,
        explanation: String,
        hdurl: URL?,
        mediaType: String,
        serviceVersion: String,
        title: String,
        url: URL?,
        thumbnailUrl: URL?
    ) {
        self.copyright = copyright
        self.date = date
        self.explanation = explanation
        self.hdurl = hdurl
        self.mediaType = mediaType
        self.serviceVersion = serviceVersion
        self.title = title
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}

private extension String {
    func strippingHTMLTags() -> String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "\n\n\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
