  
                 
         
  
                                         
  
import Foundation
import SwiftUI
import Alamofire
import SDWebImageSwiftUI
import Combine
import Network



private enum OldOSYouTubeConnectivity {
    static func waitUntilOnline() async {
        guard let url = URL(string: "https://www.youtube.com/generate_204") else { return }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 10
        let session = URLSession(configuration: configuration)
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        for attempt in 0..<3 {
            do {
                let (_, response) = try await session.data(for: request)
                if let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) { return }
            } catch {
                if attempt == 2 { return }
            }
            await oldOSRetryDelay(attempt)
        }
    }
}

private func oldOSRetryDelay(_ attempt: Int) async {
    let delays: [UInt64] = [350_000_000, 900_000_000, 1_800_000_000]
    let index = min(max(attempt, 0), delays.count - 1)
    try? await Task.sleep(nanoseconds: delays[index])
}

@MainActor
final class OldOSYouTubePlayback {
    static let shared = OldOSYouTubePlayback()

    private let playerAPI = OldOSYouTubePlayerAPI()
    private var playbackGeneration: UInt64 = 0

    func beginPlayer(videoID: String) async throws -> AVPlayer {
        playbackGeneration &+= 1
        let generation = playbackGeneration

        let response = try await playerAPI.player(videoID: videoID)
        guard generation == playbackGeneration else { throw CancellationError() }

        guard let streamingData = response["streamingData"] as? [String: Any],
              let hlsString = streamingData["hlsManifestUrl"] as? String,
              let hlsURL = URL(string: hlsString) else {
            throw OldOSYouTubeError("YouTube did not return an HLS stream for this video.")
        }

        print("OldOS YouTube direct player: HLS manifest received for", videoID)

        let asset = AVURLAsset(url: hlsURL)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 6

        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = true

        guard generation == playbackGeneration else {
            player.pause()
            player.replaceCurrentItem(with: nil)
            throw CancellationError()
        }
        return player
    }

    func cancelPendingPlayback() {
        playbackGeneration &+= 1
    }

    func metadata(videoID: String) async throws -> YouTubeVideoData {
                                                                               
                                                                                   
                                                                                  
                                                        
        if let response = try? await playerAPI.webMetadata(videoID: videoID),
           let video = YouTubeVideoData(playerResponse: response, fallbackVideoID: videoID) {
            return video
        }
        let response = try await playerAPI.player(videoID: videoID)
        guard let video = YouTubeVideoData(playerResponse: response, fallbackVideoID: videoID) else {
            throw OldOSYouTubeError("YouTube returned incomplete video metadata.")
        }
        return video
    }
}

@MainActor
private final class OldOSYouTubePlayerAPI {
    private struct WebConfiguration {
        let apiKey: String
        let visitorData: String?
    }

    private let session: URLSession
    private var cachedConfiguration: WebConfiguration?

    private struct ClientProfile {
        let name: String
        let version: String
        let number: String
        let userAgent: String
        let deviceMake: String
        let deviceModel: String
        let osName: String
        let osVersion: String
    }

    private let clients: [ClientProfile] = [
        .init(
            name: "VISIONOS", version: "1.02", number: "101",
            userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15",
            deviceMake: "Apple", deviceModel: "RealityDevice17,1", osName: "visionOS", osVersion: "26.5.23O471"
        ),
        .init(
            name: "IOS", version: "21.26.4", number: "5",
            userAgent: "com.google.ios.youtube/21.26.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)",
            deviceMake: "Apple", deviceModel: "iPhone16,2", osName: "iPhone", osVersion: "18.3.2.22D82"
        )
    ]

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 35
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.httpAdditionalHeaders = [
            "Accept-Language": "en-US,en;q=0.9",
            "Cookie": "SOCS=CAI"
        ]
        session = URLSession(configuration: configuration)
    }

    func player(videoID: String) async throws -> [String: Any] {
        guard !videoID.isEmpty else { throw OldOSYouTubeError("Invalid YouTube video ID.") }
        await OldOSYouTubeConnectivity.waitUntilOnline()

        var lastError: Error?
        for attempt in 0..<3 {
            do {
                let configuration = try await webConfiguration(videoID: videoID, forceRefresh: attempt > 0)
                var firstPlayableResponse: [String: Any]?
                var clientError: Error?
                for client in clients {
                    do {
                        let response = try await requestPlayer(videoID: videoID, configuration: configuration, client: client)
                        if ((response["streamingData"] as? [String: Any])?["hlsManifestUrl"] as? String) != nil {
                            return response
                        }
                        if firstPlayableResponse == nil { firstPlayableResponse = response }
                    } catch {
                        clientError = error
                    }
                }
                if let firstPlayableResponse { return firstPlayableResponse }
                throw clientError ?? OldOSYouTubeError("No usable YouTube player client responded.")
            } catch {
                lastError = error
                if attempt < 2 { await oldOSRetryDelay(attempt) }
            }
        }
        throw lastError ?? OldOSYouTubeError("YouTube player request failed.")
    }

    func webMetadata(videoID: String) async throws -> [String: Any] {
        guard !videoID.isEmpty,
              let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)&hl=en&gl=US") else {
            throw OldOSYouTubeError("Invalid YouTube watch URL.")
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("https://www.youtube.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OldOSYouTubeError("Could not load YouTube metadata page (HTTP \(code)).")
        }

        for marker in ["var ytInitialPlayerResponse", "ytInitialPlayerResponse"] {
            if let json = jsonObject(after: marker, in: html) { return json }
        }
        throw OldOSYouTubeError("Could not read YouTube video metadata.")
    }

    private func jsonObject(after marker: String, in text: String) -> [String: Any]? {
        var searchStart = text.startIndex
        while searchStart < text.endIndex,
              let range = text.range(of: marker, range: searchStart..<text.endIndex) {
            let afterMarker = range.upperBound
            let scanEnd = text.index(afterMarker, offsetBy: 512, limitedBy: text.endIndex) ?? text.endIndex
            let nearby = text[afterMarker..<scanEnd]
            if let equals = nearby.firstIndex(of: "=") {
                let afterEquals = text.index(after: equals)
                let objectSearchEnd = text.index(afterEquals, offsetBy: 256, limitedBy: text.endIndex) ?? text.endIndex
                if let brace = text[afterEquals..<objectSearchEnd].firstIndex(of: "{") {
                    let tail = String(text[brace...])
                    if let jsonText = balancedJSONObject(in: tail),
                       let object = try? JSONSerialization.jsonObject(with: Data(jsonText.utf8)) as? [String: Any] {
                        return object
                    }
                }
            }
            searchStart = range.upperBound
        }
        return nil
    }

    private func balancedJSONObject(in text: String) -> String? {
        var depth = 0
        var inString = false
        var escaped = false
        var started = false
        for (offset, character) in text.enumerated() {
            if inString {
                if escaped { escaped = false; continue }
                if character == "\\" { escaped = true; continue }
                if character == "\"" { inString = false }
                continue
            }
            if character == "\"" { inString = true; continue }
            if character == "{" { depth += 1; started = true }
            if character == "}" {
                depth -= 1
                if started && depth == 0 {
                    let end = text.index(text.startIndex, offsetBy: offset + 1)
                    return String(text[..<end])
                }
            }
        }
        return nil
    }

    private func webConfiguration(videoID: String, forceRefresh: Bool) async throws -> WebConfiguration {
        if !forceRefresh, let cachedConfiguration { return cachedConfiguration }

        guard let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)&hl=en&gl=US") else {
            throw OldOSYouTubeError("Invalid YouTube watch URL.")
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("https://www.youtube.com/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OldOSYouTubeError("Could not load YouTube player configuration (HTTP \(code)).")
        }

        guard let apiKey = configString("INNERTUBE_API_KEY", in: html), !apiKey.isEmpty else {
            throw OldOSYouTubeError("Could not read YouTube InnerTube API key.")
        }
        let config = WebConfiguration(
            apiKey: apiKey,
            visitorData: configString("VISITOR_DATA", in: html) ?? configString("visitorData", in: html)
        )
        cachedConfiguration = config
        return config
    }

    private func requestPlayer(videoID: String, configuration: WebConfiguration, client: ClientProfile) async throws -> [String: Any] {
        var components = URLComponents(string: "https://www.youtube.com/youtubei/v1/player")!
        components.queryItems = [
            URLQueryItem(name: "key", value: configuration.apiKey),
            URLQueryItem(name: "prettyPrint", value: "false")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(client.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(client.number, forHTTPHeaderField: "X-YouTube-Client-Name")
        request.setValue(client.version, forHTTPHeaderField: "X-YouTube-Client-Version")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.youtube.com/watch?v=\(videoID)", forHTTPHeaderField: "Referer")
        if let visitorData = configuration.visitorData, !visitorData.isEmpty {
            request.setValue(visitorData, forHTTPHeaderField: "X-Goog-Visitor-Id")
        }

        let body: [String: Any] = [
            "context": [
                "client": [
                    "clientName": client.name,
                    "clientVersion": client.version,
                    "deviceMake": client.deviceMake,
                    "deviceModel": client.deviceModel,
                    "userAgent": client.userAgent,
                    "osName": client.osName,
                    "osVersion": client.osVersion,
                    "hl": "en",
                    "gl": "US",
                    "timeZone": "UTC",
                    "utcOffsetMinutes": 0
                ]
            ],
            "playbackContext": [
                "contentPlaybackContext": [
                    "html5Preference": "HTML5_PREF_WANTS"
                ]
            ],
            "videoId": videoID,
            "contentCheckOk": true,
            "racyCheckOk": true
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OldOSYouTubeError("YouTube player API failed (HTTP \(code)).")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OldOSYouTubeError("Could not decode YouTube player response.")
        }

        let playability = json["playabilityStatus"] as? [String: Any]
        let status = playability?["status"] as? String
        if status != nil && status != "OK" {
            let reason = (playability?["reason"] as? String) ?? "Video is not playable."
            throw OldOSYouTubeError(reason)
        }
        return json
    }

    private func configString(_ key: String, in html: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            "\\\"\(escaped)\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"",
            "\(escaped)\\s*[:=]\\s*\\\"([^\\\"]+)\\\""
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1,
               let r = Range(match.range(at: 1), in: html) {
                return String(html[r])
            }
        }
        return nil
    }
}

struct OldOSYouTubeError: LocalizedError { let message: String; init(_ message: String) { self.message = message }; var errorDescription: String? { message } }

final class OldOSYouTubeDiscovery {
    static let shared = OldOSYouTubeDiscovery()
    enum Period { case today, week, all }

    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
            "Cookie": "SOCS=CAI"
        ]
        return URLSession(configuration: configuration)
    }()

    func featured() async throws -> [YouTubeVideoData] {
                                                                                     
                                                                                    
                                                                                 
        let sources: [() async throws -> [YouTubeVideoData]] = [
            { try await self.videos(from: URL(string: "https://www.youtube.com/feed/trending?hl=en&gl=US")!) },
            { try await self.videos(from: URL(string: "https://www.youtube.com/?hl=en&gl=US")!) },
            { try await self.search("popular videos") },
            { try await self.search("popular music") },
            { try await self.search("sports highlights") }
        ]

        var seen = Set<String>()
        var merged = [YouTubeVideoData]()
        var lastError: Error?
        for source in sources {
            do {
                let group = try await source()
                for video in group {
                    guard let id = video.id, seen.insert(id).inserted else { continue }
                    merged.append(video)
                    if merged.count >= 30 { return merged }
                }
                if merged.count >= 18 { return merged }
            } catch {
                lastError = error
            }
        }
        if !merged.isEmpty { return merged }
        throw lastError ?? OldOSYouTubeError("YouTube Featured returned no videos.")
    }

    func search(_ query: String) async throws -> [YouTubeVideoData] {
        var components = URLComponents(string: "https://www.youtube.com/results")!
        components.queryItems = [
            URLQueryItem(name: "search_query", value: query),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "gl", value: "US")
        ]
        return try await videos(from: components.url!)
    }

    func mostViewed(_ period: Period) async throws -> [YouTubeVideoData] {
                                                                                    
                                                                                     
                                                                                     
                                                                                        
                                                                                        
                                                                                  
        let sourceURLs = [
            URL(string: "https://www.youtube.com/feed/trending?hl=en&gl=US")!,
            URL(string: "https://www.youtube.com/feed/explore?hl=en&gl=US")!
        ]

        var seen = Set<String>()
        var candidates = [YouTubeVideoData]()
        var lastError: Error?

        for url in sourceURLs {
            do {
                let group = try await videos(from: url)
                for video in group {
                    guard let id = video.id, seen.insert(id).inserted else { continue }
                    candidates.append(video)
                }
            } catch {
                lastError = error
            }
        }

        guard !candidates.isEmpty else {
            throw lastError ?? OldOSYouTubeError("YouTube Most Viewed returned no videos.")
        }

        let maxAge: TimeInterval?
        switch period {
        case .today: maxAge = 24 * 60 * 60
        case .week:  maxAge = 7 * 24 * 60 * 60
        case .all:   maxAge = nil
        }

        let filtered = candidates.filter { video in
            guard let maxAge else { return true }
            guard let age = oldOSYouTubePublishedAge(video.published?.pretty ?? video.published?.text ?? video.uploaded?.text) else {
                                                                                      
                return true
            }
            return age <= maxAge
        }

        let ranked = filtered.sorted { lhs, rhs in
            let l = oldOSYouTubeViewCount(lhs.views?.pretty ?? lhs.views?.text)
            let r = oldOSYouTubeViewCount(rhs.views?.pretty ?? rhs.views?.text)
            if l != r { return l > r }
            let la = oldOSYouTubePublishedAge(lhs.published?.pretty ?? lhs.published?.text ?? lhs.uploaded?.text) ?? .greatestFiniteMagnitude
            let ra = oldOSYouTubePublishedAge(rhs.published?.pretty ?? rhs.published?.text ?? rhs.uploaded?.text) ?? .greatestFiniteMagnitude
            return la < ra
        }

        return Array(ranked.prefix(30))
    }

    private func videos(from url: URL) async throws -> [YouTubeVideoData] {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("https://www.youtube.com/", forHTTPHeaderField: "Referer")

        let (data, response) = try await dataWithRetry(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OldOSYouTubeError("YouTube discovery returned no HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw OldOSYouTubeError("YouTube discovery returned HTTP \(http.statusCode).")
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw OldOSYouTubeError("Could not decode YouTube discovery data.")
        }
        guard let object = initialData(in: html) else {
            print("OldOS YouTube discovery: ytInitialData not found. URL=\(url.absoluteString) bytes=\(data.count) prefix=\(String(html.prefix(220)))")
            throw OldOSYouTubeError("Could not read YouTube discovery data.")
        }

        var renderers = [[String: Any]]()
        collect(object, into: &renderers)
        var seen = Set<String>()
        let videos = renderers.compactMap { renderer -> YouTubeVideoData? in
            guard let video = YouTubeVideoData(videoRenderer: renderer), let id = video.id, seen.insert(id).inserted else { return nil }
            return video
        }
        if videos.isEmpty {
            print("OldOS YouTube discovery: ytInitialData parsed but contained no videoRenderer objects. URL=\(url.absoluteString)")
        }
        return videos
    }


    private func dataWithRetry(for request: URLRequest) async throws -> (Data, URLResponse) {
        await OldOSYouTubeConnectivity.waitUntilOnline()
        var lastError: Error?
        for attempt in 0..<3 {
            do {
                return try await session.data(for: request)
            } catch {
                lastError = error
                if attempt < 2 { await oldOSRetryDelay(attempt) }
            }
        }
        throw lastError ?? OldOSYouTubeError("YouTube network request failed.")
    }

    private func initialData(in html: String) -> Any? {
                                                                                         
                                                                   
        let markers = [
            "var ytInitialData",
            "window[\"ytInitialData\"]",
            "window['ytInitialData']",
            "window.ytInitialData",
            "ytInitialData"
        ]

        for marker in markers {
            var searchStart = html.startIndex
            while searchStart < html.endIndex,
                  let range = html.range(of: marker, range: searchStart..<html.endIndex) {
                let afterMarker = range.upperBound
                let scanEnd = html.index(afterMarker, offsetBy: 512, limitedBy: html.endIndex) ?? html.endIndex
                let nearby = html[afterMarker..<scanEnd]

                                                                                            
                                                                                  
                if let equals = nearby.firstIndex(of: "=") {
                    let afterEquals = html.index(after: equals)
                    let objectSearchEnd = html.index(afterEquals, offsetBy: 256, limitedBy: html.endIndex) ?? html.endIndex
                    if let brace = html[afterEquals..<objectSearchEnd].firstIndex(of: "{") {
                        let tail = String(html[brace...])
                        if let json = balancedObject(in: tail),
                           let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) {
                            return object
                        }
                    }
                }

                searchStart = range.upperBound
            }
        }
        return nil
    }

    private func balancedObject(in text: String) -> String? {
        var depth = 0
        var inString = false
        var escaped = false
        var started = false

        for (offset, character) in text.enumerated() {
            if inString {
                if escaped { escaped = false; continue }
                if character == "\\" { escaped = true; continue }
                if character == "\"" { inString = false }
                continue
            }

            if character == "\"" { inString = true; continue }
            if character == "{" { depth += 1; started = true }
            if character == "}" {
                depth -= 1
                if started && depth == 0 {
                    let end = text.index(text.startIndex, offsetBy: offset + 1)
                    return String(text[..<end])
                }
            }
        }
        return nil
    }

    private func collect(_ value: Any, into output: inout [[String: Any]]) {
        if let dictionary = value as? [String: Any] {
            for key in ["videoRenderer", "gridVideoRenderer", "compactVideoRenderer"] {
                if let renderer = dictionary[key] as? [String: Any] { output.append(renderer) }
            }
            for value in dictionary.values { collect(value, into: &output) }
        } else if let array = value as? [Any] {
            for value in array { collect(value, into: &output) }
        }
    }
}

final class OldOSYouTubeComments {
    static let shared = OldOSYouTubeComments()
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9",
            "Cookie": "SOCS=CAI"
        ]
        session = URLSession(configuration: configuration)
    }

    func comments(videoID: String) async throws -> YoutubeVideoComments {
        guard !videoID.isEmpty,
              let watchURL = URL(string: "https://www.youtube.com/watch?v=\(videoID)&hl=en&gl=US") else {
            throw OldOSYouTubeError("Invalid YouTube video ID.")
        }

        var watchRequest = URLRequest(url: watchURL)
        watchRequest.setValue("https://www.youtube.com/", forHTTPHeaderField: "Referer")
        let (watchData, watchResponse) = try await dataWithRetry(for: watchRequest)
        guard let http = watchResponse as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let html = String(data: watchData, encoding: .utf8) else {
            throw OldOSYouTubeError("Could not load YouTube comments page.")
        }

        guard let apiKey = configString("INNERTUBE_API_KEY", in: html),
              let clientVersion = configString("INNERTUBE_CLIENT_VERSION", in: html) else {
            throw OldOSYouTubeError("Could not read YouTube comments configuration.")
        }

        let initialNext = try await next(videoID: videoID, continuation: nil, apiKey: apiKey, clientVersion: clientVersion)

        var continuation = commentsContinuation(in: initialNext)
        if continuation == nil, let initial = initialData(in: html) {
            continuation = commentsContinuation(in: initial)
        }

        guard let continuation else {
            print("OldOS YouTube comments: no comments continuation for", videoID)
            return YoutubeVideoComments(comments: [], continuation: nil)
        }

        let responseObject = try await next(videoID: videoID, continuation: continuation, apiKey: apiKey, clientVersion: clientVersion)

        var comments = [YoutubeVideoComments.Comments]()
        var seen = Set<String>()

        var modern = [[String: Any]]()
        collectCommentEntities(responseObject, into: &modern)
        for entity in modern {
            if let comment = makeModernComment(entity), seen.insert(comment.commentID).inserted {
                comments.append(comment)
            }
        }

        var legacy = [[String: Any]]()
        collectCommentRenderers(responseObject, into: &legacy)
        for renderer in legacy {
            if let comment = makeLegacyComment(renderer), seen.insert(comment.commentID).inserted {
                comments.append(comment)
            }
        }

        print("OldOS YouTube comments: parsed", comments.count, "comments for", videoID)
        return YoutubeVideoComments(comments: comments, continuation: firstContinuation(in: responseObject))
    }

    private func next(videoID: String, continuation: String?, apiKey: String, clientVersion: String) async throws -> Any {
        var components = URLComponents(string: "https://www.youtube.com/youtubei/v1/next")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "prettyPrint", value: "false")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.youtube.com/watch?v=\(videoID)", forHTTPHeaderField: "Referer")
        request.setValue("1", forHTTPHeaderField: "X-YouTube-Client-Name")
        request.setValue(clientVersion, forHTTPHeaderField: "X-YouTube-Client-Version")

        var body: [String: Any] = [
            "context": [
                "client": [
                    "clientName": "WEB",
                    "clientVersion": clientVersion,
                    "hl": "en",
                    "gl": "US"
                ]
            ]
        ]
        if let continuation {
            body["continuation"] = continuation
        } else {
            body["videoId"] = videoID
            body["contentCheckOk"] = true
            body["racyCheckOk"] = true
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await dataWithRetry(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw OldOSYouTubeError("YouTube comments request failed (HTTP \(code)).")
        }
        return try JSONSerialization.jsonObject(with: data)
    }

    private func dataWithRetry(for request: URLRequest) async throws -> (Data, URLResponse) {
        await OldOSYouTubeConnectivity.waitUntilOnline()
        var lastError: Error?
        for attempt in 0..<3 {
            do { return try await session.data(for: request) }
            catch {
                lastError = error
                if attempt < 2 { await oldOSRetryDelay(attempt) }
            }
        }
        throw lastError ?? OldOSYouTubeError("YouTube comments request failed.")
    }

    private func configString(_ key: String, in html: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            "\\\"\(escaped)\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"",
            "\(escaped)\\s*[:=]\\s*\\\"([^\\\"]+)\\\""
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, range: range), match.numberOfRanges > 1,
               let r = Range(match.range(at: 1), in: html) {
                return String(html[r])
            }
        }
        return nil
    }

    private func initialData(in html: String) -> Any? {
        let markers = ["var ytInitialData", "window[\"ytInitialData\"]", "window['ytInitialData']", "window.ytInitialData", "ytInitialData"]
        for marker in markers {
            var searchStart = html.startIndex
            while searchStart < html.endIndex, let range = html.range(of: marker, range: searchStart..<html.endIndex) {
                let after = range.upperBound
                let scanEnd = html.index(after, offsetBy: 512, limitedBy: html.endIndex) ?? html.endIndex
                if let equals = html[after..<scanEnd].firstIndex(of: "=") {
                    let afterEquals = html.index(after: equals)
                    let objectEnd = html.index(afterEquals, offsetBy: 256, limitedBy: html.endIndex) ?? html.endIndex
                    if let brace = html[afterEquals..<objectEnd].firstIndex(of: "{"),
                       let json = balancedObject(in: String(html[brace...])),
                       let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) { return object }
                }
                searchStart = range.upperBound
            }
        }
        return nil
    }

    private func balancedObject(in text: String) -> String? {
        var depth = 0, started = false, inString = false, escaped = false
        for (offset, character) in text.enumerated() {
            if inString {
                if escaped { escaped = false; continue }
                if character == "\\" { escaped = true; continue }
                if character == "\"" { inString = false }
                continue
            }
            if character == "\"" { inString = true; continue }
            if character == "{" { depth += 1; started = true }
            if character == "}" {
                depth -= 1
                if started && depth == 0 {
                    let end = text.index(text.startIndex, offsetBy: offset + 1)
                    return String(text[..<end])
                }
            }
        }
        return nil
    }

    private func commentsContinuation(in value: Any) -> String? {
        if let d = value as? [String: Any] {
            if let panel = d["engagementPanelSectionListRenderer"] as? [String: Any] {
                let identifier = ((panel["panelIdentifier"] as? String) ?? "") + " " + ((panel["targetId"] as? String) ?? "")
                if identifier.lowercased().contains("comment"), let token = firstContinuation(in: panel) { return token }
            }
            if let item = d["itemSectionRenderer"] as? [String: Any] {
                let identifier = ((item["sectionIdentifier"] as? String) ?? "") + " " + ((item["targetId"] as? String) ?? "")
                if identifier.lowercased().contains("comment"), let token = firstContinuation(in: item) { return token }
            }
            if d["commentsEntryPointHeaderRenderer"] != nil, let token = firstContinuation(in: d) { return token }
            if let target = d["targetId"] as? String, target.lowercased().contains("comment"), let token = firstContinuation(in: d) { return token }
            for child in d.values {
                if let token = commentsContinuation(in: child) { return token }
            }
        } else if let a = value as? [Any] {
            for child in a {
                if let token = commentsContinuation(in: child) { return token }
            }
        }
        return nil
    }

    private func firstContinuation(in value: Any) -> String? {
        if let d = value as? [String: Any] {
            if let command = d["continuationCommand"] as? [String: Any], let token = command["token"] as? String { return token }
            if let command = d["reloadContinuationData"] as? [String: Any], let token = command["continuation"] as? String { return token }
            if let command = d["nextContinuationData"] as? [String: Any], let token = command["continuation"] as? String { return token }
            for child in d.values { if let token = firstContinuation(in: child) { return token } }
        } else if let a = value as? [Any] {
            for child in a { if let token = firstContinuation(in: child) { return token } }
        }
        return nil
    }

    private func collectCommentEntities(_ value: Any, into output: inout [[String: Any]]) {
        if let d = value as? [String: Any] {
            if let entity = d["commentEntityPayload"] as? [String: Any] { output.append(entity) }
            for child in d.values { collectCommentEntities(child, into: &output) }
        } else if let a = value as? [Any] {
            for child in a { collectCommentEntities(child, into: &output) }
        }
    }

    private func collectCommentRenderers(_ value: Any, into output: inout [[String: Any]]) {
        if let d = value as? [String: Any] {
            if let renderer = d["commentRenderer"] as? [String: Any] { output.append(renderer) }
            for child in d.values { collectCommentRenderers(child, into: &output) }
        } else if let a = value as? [Any] {
            for child in a { collectCommentRenderers(child, into: &output) }
        }
    }

    private func makeModernComment(_ p: [String: Any]) -> YoutubeVideoComments.Comments? {
        let properties = p["properties"] as? [String: Any] ?? [:]
        guard let id = properties["commentId"] as? String, !id.isEmpty else { return nil }
        let author = p["author"] as? [String: Any] ?? [:]
        let toolbar = p["toolbar"] as? [String: Any] ?? [:]

        var thumbnails = [YoutubeVideoComments.Comments.AuthorThumb]()
        if let avatar = p["avatar"] as? [String: Any],
           let image = avatar["image"] as? [String: Any],
           let sources = image["sources"] as? [[String: Any]] {
            thumbnails = sources.compactMap { source in
                guard let raw = source["url"] as? String else { return nil }
                let normalized = raw.hasPrefix("//") ? "https:" + raw : raw
                return YoutubeVideoComments.Comments.AuthorThumb(url: URL(string: normalized), width: source["width"] as? Int, height: source["height"] as? Int)
            }
        }
        if thumbnails.isEmpty, let raw = author["avatarThumbnailUrl"] as? String {
            thumbnails = [.init(url: URL(string: raw), width: nil, height: nil)]
        }

        let replyCount: Int? = {
            if let value = toolbar["replyCount"] as? Int { return value }
            if let value = toolbar["replyCount"] as? NSNumber { return value.intValue }
            if let value = toolbar["replyCount"] as? String { return Int(value.filter(\.isNumber)) }
            return nil
        }()
        let published = properties["publishedTime"] as? String
        let edited = published?.localizedCaseInsensitiveContains("edited") ?? false
        let likes = (toolbar["likeCountNotliked"] as? String) ?? (toolbar["likeCountLiked"] as? String) ?? (toolbar["likeCountA11y"] as? String)

        return YoutubeVideoComments.Comments(
            authorThumb: thumbnails,
            author: author["displayName"] as? String,
            authorID: author["channelId"] as? String,
            commentID: id,
            text: ((properties["content"] as? [String: Any])?["content"] as? String),
            likes: likes,
            numReplies: replyCount,
            isOwner: author["isCreator"] as? Bool,
            isHearted: nil,
            isPinned: p["pinnedText"] != nil,
            hasOwnerReplied: nil,
            time: published?.replacingOccurrences(of: " (edited)", with: ""),
            edited: edited,
            replyToken: nil,
            isVerified: author["isVerified"] as? Bool,
            isOfficialArtist: author["isArtist"] as? Bool
        )
    }

    private func makeLegacyComment(_ r: [String: Any]) -> YoutubeVideoComments.Comments? {
        guard let id = r["commentId"] as? String else { return nil }
        let thumbnails = ((r["authorThumbnail"] as? [String: Any])?["thumbnails"] as? [[String: Any]] ?? []).compactMap { thumb -> YoutubeVideoComments.Comments.AuthorThumb? in
            guard let raw = thumb["url"] as? String else { return nil }
            let normalized = raw.hasPrefix("//") ? "https:" + raw : raw
            return YoutubeVideoComments.Comments.AuthorThumb(url: URL(string: normalized), width: thumb["width"] as? Int, height: thumb["height"] as? Int)
        }
        let badge = r["authorCommentBadge"] as? [String: Any]
        return YoutubeVideoComments.Comments(
            authorThumb: thumbnails,
            author: oldOSText(r["authorText"]),
            authorID: ((r["authorEndpoint"] as? [String: Any])?["browseEndpoint"] as? [String: Any])?["browseId"] as? String,
            commentID: id,
            text: oldOSText(r["contentText"]),
            likes: oldOSText(r["voteCount"]),
            numReplies: r["replyCount"] as? Int,
            isOwner: r["authorIsChannelOwner"] as? Bool,
            isHearted: r["creatorHeart"] != nil,
            isPinned: r["pinnedCommentBadge"] != nil,
            hasOwnerReplied: nil,
            time: oldOSText(r["publishedTimeText"]),
            edited: nil,
            replyToken: nil,
            isVerified: badge != nil,
            isOfficialArtist: nil
        )
    }
}

private func oldOSText(_ value:Any?)->String? { guard let d=value as? [String:Any] else{return nil}; if let s=d["simpleText"] as? String{return s}; if let r=d["runs"] as? [[String:Any]] {let s=r.compactMap{$0["text"] as? String}.joined(); return s.isEmpty ? nil:s}; return nil }
private func oldOSDurationSeconds(_ text:String?)->Int? { guard let text else{return nil}; let p=text.split(separator:":").compactMap{Int($0)}; guard !p.isEmpty else{return nil}; return p.reversed().enumerated().reduce(0){$0+$1.element*Int(pow(60.0,Double($1.offset)))} }
private func oldOSNumericText(_ text:String?)->String { guard let text else{return ""}; return String(text.filter{$0.isNumber}) }

private func oldOSYouTubeViewCount(_ text: String?) -> Double {
    guard var raw = text?.lowercased(), !raw.isEmpty else { return 0 }
    raw = raw.replacingOccurrences(of: "views", with: "")
             .replacingOccurrences(of: "view", with: "")
             .replacingOccurrences(of: ",", with: "")
             .trimmingCharacters(in: .whitespacesAndNewlines)
    let multiplier: Double
    if raw.hasSuffix("b") { multiplier = 1_000_000_000; raw.removeLast() }
    else if raw.hasSuffix("m") { multiplier = 1_000_000; raw.removeLast() }
    else if raw.hasSuffix("k") { multiplier = 1_000; raw.removeLast() }
    else { multiplier = 1 }
    return (Double(raw.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) * multiplier
}

private func oldOSYouTubePublishedAge(_ text: String?) -> TimeInterval? {
    guard let text = text?.lowercased() else { return nil }
    if text.contains("just now") || text.contains("minute") { return 60 }
    let number = Double(text.split(separator: " ").first.flatMap { Double($0) } ?? 0)
    guard number > 0 else { return nil }
    if text.contains("hour") { return number * 60 * 60 }
    if text.contains("day") { return number * 24 * 60 * 60 }
    if text.contains("week") { return number * 7 * 24 * 60 * 60 }
    if text.contains("month") { return number * 30 * 24 * 60 * 60 }
    if text.contains("year") { return number * 365 * 24 * 60 * 60 }
    return nil
}

private func oldOSFormattedYouTubeDate(_ raw: String?) -> String {
    guard let raw, !raw.isEmpty else { return "" }
                                                               
    if raw.lowercased().contains("ago") { return raw }

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    var date = iso.date(from: raw)
    if date == nil {
        iso.formatOptions = [.withInternetDateTime]
        date = iso.date(from: raw)
    }
    if date == nil {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        date = f.date(from: String(raw.prefix(10)))
    }
    guard let date else { return String(raw.prefix(10)) }
    let out = DateFormatter()
    out.locale = Locale(identifier: "en_US")
    out.dateStyle = .medium
    out.timeStyle = .none
    return out.string(from: date)
}
private func oldOSApprovalPercent(_ video:YouTubeVideoData)->Int { let l=Int(oldOSNumericText(video.ratings?.likes?.text)) ?? 0, d=Int(oldOSNumericText(video.ratings?.dislikes?.text)) ?? 0; guard l+d>0 else{return 100}; return Int(Double(l)/Double(l+d)*100) }
@MainActor
private func oldOSStartPlayback(videoID:String?, selectedPlayer:Binding<AVPlayer>, showPlayer:Binding<Bool>, instantChange:Binding<Bool>) {
    guard let id=videoID,!id.isEmpty else{return}
    OldOSYouTubePlayback.shared.cancelPendingPlayback()
    selectedPlayer.wrappedValue.pause()
    selectedPlayer.wrappedValue.replaceCurrentItem(with: nil)
    selectedPlayer.wrappedValue=AVPlayer()
    instantChange.wrappedValue=true
    withAnimation(.linear(duration:0.4)){showPlayer.wrappedValue=true}
    Task {
        do {
            let p=try await OldOSYouTubePlayback.shared.beginPlayer(videoID:id)
            await MainActor.run {
                guard showPlayer.wrappedValue else {
                    p.pause()
                    p.replaceCurrentItem(with: nil)
                    return
                }
                selectedPlayer.wrappedValue=p
                p.play()
            }
        } catch is CancellationError {
        } catch {
            print("OldOS YouTube playback failed:",error)
        }
    }
}

@MainActor
private func oldOSStopPlayback(_ player: AVPlayer) {
    OldOSYouTubePlayback.shared.cancelPendingPlayback()
    player.pause()
    player.replaceCurrentItem(with: nil)
}

                                                                                        

struct Youtube: View {
    @StateObject var youtube_observer: YoutubeObserver = YoutubeObserver()
    @StateObject var most_viewed_observer: MostViewedObserver = MostViewedObserver()
    @StateObject var favorite_observer: favorite_videos_observer = favorite_videos_observer()
    @State var current_nav_view: String = "Main"
    @State var forward_or_backward: Bool = false
    @State var selectedTab = "Featured"
    @State var show_alert:Bool = false
    @State var increase_brightness: Bool = false
    @State var done_loading: Bool = false
    @State var selected_segment: Int = 0
    @State var search_results = [YouTubeVideoData]()
    @State var is_searching: Bool = false
    @State var featured_current_nav_view: String = "Main"
    @State var mv_current_nav_view: String = "Main"
    @State var fv_current_nav_view: String = "Main"
    @State var search_current_nav_view: String = "Main"
    @State var featured_current_video: YouTubeVideoData?
    @State var mv_current_video: YouTubeVideoData?
    @State var fv_current_video: YouTubeVideoData?
    @State var search_current_video: YouTubeVideoData?
    @State var currently_playing_video: YouTubeVideoData?
    @State var proxy: GeometryProxy?
    @State var selected_video_player: AVPlayer = AVPlayer()
    @State var show_video_player: Bool = false
    @State var instant_video_change: Bool = false
    @State var is_editing_favorites: Bool = false
    @Binding var instant_multitasking_change: Bool
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if instant_video_change {
                    containerYoutube(show_video_player: $show_video_player, instant_video_change: $instant_video_change, player: $selected_video_player).frame(width: geometry.size.width, height: geometry.size.height).zIndex(0)
                }
                    ZStack {
                        if show_video_player == false{
                        VStack {
                            status_bar_in_app().frame(minHeight: 24, maxHeight:24).zIndex(1)
                            Spacer()
                        }.transition(.asymmetric(insertion: .opacity, removal: .move(edge:.bottom)))
                        }
                        if show_video_player == false{
                        VStack(spacing:0) {
                            Spacer().frame(height: 24)
                            youtube_title_bar(title: (selectedTab == "Featured" && featured_current_nav_view == "Main") ? selectedTab : (selectedTab == "Featured" && featured_current_nav_view == "Video_Destination") ? featured_current_video?.title ?? "" : (selectedTab == "Featured" && featured_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Most Viewed" && mv_current_nav_view == "Main") ? selectedTab : (selectedTab == "Most Viewed" && mv_current_nav_view == "Video_Destination") ? mv_current_video?.title ?? "" : (selectedTab == "Most Viewed" && mv_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Search" && search_current_nav_view == "Main") ? selectedTab : (selectedTab == "Search" && search_current_nav_view == "Video_Destination") ? search_current_video?.title ?? "" : (selectedTab == "Search" && search_current_nav_view == "Video_Info") ? "More Info" : (selectedTab == "Favorites" && fv_current_nav_view == "Main") ? selectedTab : (selectedTab == "Favorites" && fv_current_nav_view == "Video_Destination") ? fv_current_video?.title ?? "" : (selectedTab == "Favorites" && fv_current_nav_view == "Video_Info") ? "More Info" : selectedTab, selectedTab: $selectedTab, selected_segment: $selected_segment, instant_multitasking_change: $instant_multitasking_change, search_results: $search_results, is_searching: $is_searching, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, mv_current_nav_view: $mv_current_nav_view, fv_current_nav_view: $fv_current_nav_view, search_current_nav_view: $search_current_nav_view, instant_video_change: $instant_video_change, is_editing_favorites: $is_editing_favorites, editing_favorites_action: {
                                withAnimation() {
                                    is_editing_favorites.toggle()
                                }
                            }).frame(minWidth: geometry.size.width, maxWidth: geometry.size.width, minHeight: 60, maxHeight:60).zIndex(1)
                            YoutubeTabView(youtube_observer: youtube_observer, most_viewed_observer: most_viewed_observer, favorite_observer: favorite_observer, selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, done_loading: $done_loading, selected_segment: $selected_segment, search_results: $search_results, is_searching: $is_searching, featured_current_nav_view: $featured_current_nav_view, mv_current_nav_view: $mv_current_nav_view, fv_current_nav_view: $fv_current_nav_view, search_current_nav_view: $search_current_nav_view, featured_current_video: $featured_current_video, mv_current_video: $mv_current_video, fv_current_video: $fv_current_video, search_current_video: $search_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, is_editing_favorites: $is_editing_favorites).clipped()
                        }.transition(.asymmetric(insertion: .move(edge:.bottom), removal: .move(edge:.bottom)))
                        }
                    }.zIndex(1)
            }.compositingGroup().clipped()
        }.onAppear() {
            UIScrollView.appearance().bounces = true
            youtube_observer.loadIfNeeded()
            if selectedTab == "Most Viewed" { most_viewed_observer.loadIfNeeded() }
        }.onChange(of: selectedTab) { tab in
            if tab == "Featured" { youtube_observer.loadIfNeeded() }
            if tab == "Most Viewed" { most_viewed_observer.loadIfNeeded() }
        }.onDisappear() {
            UIScrollView.appearance().bounces = false
        }
        
    }
}

var youtube_tabs = ["Featured", "Most Viewed", "Search", "Favorites", "More"]
struct YoutubeTabView : View {
    @StateObject var youtube_observer: YoutubeObserver
    @StateObject var most_viewed_observer: MostViewedObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var selectedTab:String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var done_loading: Bool
    @Binding var selected_segment: Int
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var featured_current_nav_view: String
    @Binding var mv_current_nav_view: String
    @Binding var fv_current_nav_view: String
    @Binding var search_current_nav_view: String
    @Binding var featured_current_video: YouTubeVideoData?
    @Binding var mv_current_video: YouTubeVideoData?
    @Binding var fv_current_video: YouTubeVideoData?
    @Binding var search_current_video: YouTubeVideoData?
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    @Binding var is_editing_favorites: Bool
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {
                
                ScrollView([], showsIndicators: false) {
                    switch selectedTab {
                    case "Featured":
                        YoutubeFeaturedView(youtube_observer: youtube_observer, favorite_observer: favorite_observer, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, featured_current_video: $featured_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Most Viewed":
                        YoutubeMostViewedView(most_viewed_observer: most_viewed_observer, favorite_observer: favorite_observer, mv_current_nav_view: $mv_current_nav_view, mv_current_video: $mv_current_video, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, selected_segment: $selected_segment, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Most Viewed").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Search":
                        YoutubeSearchView(favorite_observer: favorite_observer, search_current_nav_view: $search_current_nav_view, search_current_video: $search_current_video, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, search_results: $search_results, is_searching: $is_searching, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Search").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Favorites":
                        YoutubeFavoriteView(favorite_observer: favorite_observer, fv_current_nav_view: $fv_current_nav_view, fv_current_video: $fv_current_video, is_editing_favorites: $is_editing_favorites, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Favorites").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "More":
                        youtube_more().frame(height: geometry.size.height - 57).tag("More").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    default:
                        YoutubeFeaturedView(youtube_observer: youtube_observer, favorite_observer: favorite_observer, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, featured_current_nav_view: $featured_current_nav_view, featured_current_video: $featured_current_video, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player).frame(height: geometry.size.height - 57).tag("Featured").transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                                         
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){
                        
                        ForEach(youtube_tabs,id: \.self){image in
                            TabButton_Youtube(image: image, selectedTab: $selectedTab, geometry: geometry)
                            
                                               
                            
                            if image != tabs.last{
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }.frame(height:55)
                }.padding(.bottom, 0)
            }
        }
    }
    
}
import AVFoundation
struct player_test: View {
    @State var player = AVPlayer(url: URL(string: "https://r1---sn-vgqs7nly.googlevideo.com/videoplayback?expire=1629081499&ei=OnsZYfKQO4zNuAKfpojIAg&ip=107.178.237.6&id=o-AF6w1T2QjFauxYrlIeOyCbl_UQ2ahTVwd9KZYtmOMTM2&itag=22&source=youtube&requiressl=yes&vprv=1&mime=video%2Fmp4&ns=SBT0QS4TNrGDT49vrGpMkBwG&cnr=14&ratebypass=yes&dur=1194.550&lmt=1628954646720174&fexp=9466585,24001373,24007246&beids=9466585&c=WEB&txp=5516222&n=Kn_U2Y73ohwVbbBTlx1&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cvprv%2Cmime%2Cns%2Ccnr%2Cratebypass%2Cdur%2Clmt&sig=AOq0QJ8wRgIhAILaKVvw6gOgE6vtwWyQg1ViOxN_GleoCnxbZ8eAhVxVAiEAgfDbceNF6H3xSC37xij_xTE9gYJYg-qX9pA6yufVnA0%3D&redirect_counter=1&cm2rm=sn-qxos67z&req_id=fa0406c7e4aba3ee&cms_redirect=yes&mh=61&mip=47.20.27.224&mm=34&mn=sn-vgqs7nly&ms=ltu&mt=1629059630&mv=u&mvi=1&pl=23&lsparams=mh,mip,mm,mn,ms,mv,mvi,pl&lsig=AG3C_xAwRQIhAJQ3vVKO8IE9O4t4yQxj8GhsoYHKm6BxVzCqzvbOptqBAiBaBvie7gp2D-N2W_GjinOPA3G4P6T0ECefvWF5L7WixA%3D%3D") ?? URL(string: "google.com")!)
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                PlayerContainerView(player: player, gravity: .fit).frame(width: geometry.size.width, height:geometry.size.height)
            }.background(Color.white)
        }
    }
}

struct YoutubeVideoInfoView: View {
    @State var selected: Int = 0
    @State var comments: YoutubeVideoComments?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var current_video: YouTubeVideoData?
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settings_main_list()
                ScrollView(showsIndicators: true) {
                    VStack {
                        Spacer().frame(height: 15)
                        
                        dual_segmented_control_big_bluegray(selected: $selected, first_text: "Info", second_text: "More Videos", should_animate: false).frame(width: geometry.size.width-24, height: 45)
                        
                        Spacer().frame(height:15)
                        VStack {
                            Text(current_video?.description ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 13)).fixedSize(horizontal: false, vertical: true).padding([.top, .leading, .trailing]).padding(.bottom, 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Added").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text(oldOSFormattedYouTubeDate(current_video?.uploaded?.text)).font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(.black)
                                Spacer()
                            }.padding([.top, .bottom], 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Category").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text(current_video?.category ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(.black)                                         
                                Spacer()
                            }.padding([.top, .bottom], 3)
                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                            HStack(alignment: .top) {
                                HStack(alignment: .top, spacing: 0) {
                                    Spacer()
                                    Text("Tags").multilineTextAlignment(.trailing).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255))
                                }.frame(width: geometry.size.width/5)
                                Text((current_video?.keywords ?? []).map{String($0)}.joined(separator: ", ")).font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(.black)                                         
                                Spacer()
                            }.padding([.top], 3).padding(.bottom)
                        }.background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        
                        Spacer().frame(height: 15)
                        HStack {
                            Spacer()
                            Text("Rate, Comment or Flag").foregroundColor(.black).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                            Spacer()
                        }.frame(height: 50).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height: 10)
                        
                        VStack(spacing:0) {
                            ForEach(comments?.comments ?? [], id:\.commentID) { comment in
                                ZStack {
                                    Rectangle().fill(((comments?.comments ?? []).firstIndex(where: {$0.commentID == comment.commentID}) ?? 0) % 2 == 0 ? Color(red: 242/255, green: 242/255, blue: 242/255) : Color(red: 255/255, green: 255/255, blue: 255/255))
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack {
                                            Text(comment.author ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 165/255, green: 65/255, blue: 35/255)).padding([.leading, .trailing])
                                            Spacer()
                                            Text((comment.time ?? "").startcased()).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).padding([.leading, .trailing])
                                        }
                                        Spacer().frame(height: 10)
                                        Text(comment.text ?? "").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(.black).padding([.leading, .trailing])
                                        Spacer()
                                        if comment.commentID != (comments?.comments ?? []).last?.commentID {
                                            Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                                        }
                                    }.frame(minHeight: 90)
                                }.frame(minHeight: 90)
                            }
                        }.background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height: 10)
                    }
                }
            }
        }.onAppear() {
            guard let id = current_video?.id, !id.isEmpty else { return }
            Task {
                do {
                    let result = try await OldOSYouTubeComments.shared.comments(videoID: id)
                    await MainActor.run { comments = result }
                } catch {
                    print("OldOS YouTube comments failed:", error)
                    await MainActor.run { comments = YoutubeVideoComments(comments: [], continuation: nil) }
                }
            }
        }
    }
}

extension StringProtocol {
    func startcased() -> String {
        components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

struct YoutubeDetailView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var current_video: YouTubeVideoData?

    private var likeCount: Int {
        let likeText = current_video?.ratings?.likes?.text ?? ""
        let likeFiltered = likeText.filter("0123456789.".contains)
        return Int(likeFiltered) ?? 1
    }
    private var dislikeCount: Int {
        let dislikeText = current_video?.ratings?.dislikes?.text ?? ""
        let dislikeFiltered = dislikeText.filter("0123456789.".contains)
        return Int(dislikeFiltered) ?? 1
    }
    private var viewCount: String {
        let viewText = current_video?.views?.text ?? ""
        return viewText.filter("0123456789.".contains)
    }
    private var videoDuration: Double {
        let durationText = current_video?.duration?.lengthSec ?? ""
        let durationFiltered = durationText.filter("0123456789.".contains)
        return Double(durationFiltered) ?? 0
    }

    var body: some View {
        GeometryReader { geometry in
            let like_count = likeCount
            let dislike_count = dislikeCount
            let view_count = viewCount
            let duration = videoDuration
            ZStack {
                settings_main_list()
                ScrollView(showsIndicators: true) {
                    VStack {
                        Spacer().frame(height: 20)
                        VStack(spacing: 0) {
                            HStack {
                                WebImage(url: current_video?.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                    Image("DefaultThumbnail")
                                }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3.75, height: 60).background(Color.black).padding(.leading, 6).cornerRadius(4)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(current_video?.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                    HStack(alignment: .top, spacing: 2.5) {
                                        Image("thumbsUp").offset(y: -4.5)
                                        let percent: Int = {
                                            let like = Float(like_count)
                                            let dislike = Float(dislike_count)
                                            let total = like + dislike
                                            return total > 0 ? Int((like / total) * 100) : 0
                                        }()
                                        Text("\(percent)%").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                        Text(view_count + " views").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))


                                        Spacer()
                                    }.offset(y: 4).padding(.bottom, 4)
                                    HStack() {
                                        Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                        }
                                        Text(current_video?.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Info"}
                                    }
                                }) {
                                    Image("ABTableNextButton").padding(.trailing, 12)
                                }
                            }
                        }.frame(height: 90).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer().frame(height:10)
                        HStack(spacing: 0) {
                            Button(action: {
                                if favorite_observer.favorites.contains(current_video?.id ?? "") == false {
                                    favorite_observer.favorites.append(current_video?.id ?? "")
                                }
                            }) {
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Add to", second_line: "Favorites")))])
                            }
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Add to", second_line: "Playlist")))])
                            list_section_content_only(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, content: [list_row(title: "", content: AnyView(multiline_text_content(first_line: "Share", second_line: "Video")))])
                        }
                        Spacer().frame(height: 20)
                        HStack {
                            Text("Related Videos").foregroundColor(Color(red: 76/255, green: 86/255, blue: 108/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9).padding([.leading, .trailing], 24)
                            Spacer()
                        }
                        Spacer().frame(height: 10)
                        HStack {
                            Spacer()
                            Text("No Related Videos").foregroundColor(Color(red: 56/255, green: 95/255, blue: 210/255)).font(.custom("Helvetica Neue Bold", fixedSize: 17))
                            Spacer()
                        }.frame(height: 90).background(Color.white.cornerRadius(10)).cornerRadius(10).strokeRoundedRectangle(10, Color(red: 171/255, green: 171/255, blue: 171/255), lineWidth: 1).padding([.leading, .trailing], 12)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct YoutubeFeaturedView: View {
    @StateObject var youtube_observer: YoutubeObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var featured_current_nav_view: String
    @Binding var featured_current_video: YouTubeVideoData?
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch featured_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        
                        VStack {
                            if youtube_observer.videos.isEmpty {
                                HStack {
                                    Spacer()
                                    if youtube_observer.errorMessage == nil { ProgressView().progressViewStyle(CircularProgressViewStyle()); Spacer().frame(width: 8) }
                                    Text(youtube_observer.errorMessage ?? "Loading...").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                result_content_view(current_nav_view: $featured_current_nav_view, current_video: $featured_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: youtube_observer.videos, geometry: geometry) {
                                    EmptyView()
                                }
                                Spacer()
                            }
                        }
                        
                    }
                }.transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $featured_current_nav_view, forward_or_backward: $forward_or_backward, current_video: featured_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $featured_current_nav_view, forward_or_backward: $forward_or_backward, current_video: featured_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }.background(Color.white)
    }
}

private struct YoutubeFeaturedVideoList: View {
    @ObservedObject var youtube_observer: YoutubeObserver
    @ObservedObject var favorite_observer: favorite_videos_observer
    @Binding var forward_or_backward: Bool
    @Binding var featured_current_nav_view: String
    @Binding var featured_current_video: YouTubeVideoData?
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var geometry: GeometryProxy

    var body: some View {
        VStack(spacing:0){
            ForEach(youtube_observer.featured, id:\.id) { video in
                let like_count = Int(youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.likeCount ?? "") ?? 1
                let dislike_count = Int(youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.dislikeCount ?? "") ?? 1
                let view_count = youtube_observer.featured_stats[optional: youtube_observer.featured_stats.firstIndex(where: {$0.id == video.id}) ?? 0]?.statistics.viewCount ?? ""
                let duration = youtube_observer.featured_details[optional: youtube_observer.featured_details.firstIndex(where: {$0.id == video.id}) ?? 0]?.contentDetails.duration ?? ""
                Button(action:{
                    oldOSStartPlayback(videoID: video.id, selectedPlayer: $selected_video_player, showPlayer: $show_video_player, instantChange: $instant_video_change)


                }) {
                    VStack(spacing: 0) {
                        HStack {
                            WebImage(url: video.snippet.thumbnails.medium.url).resizable().placeholder {
                                Image("DefaultThumbnail")
                            }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.snippet.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                HStack(alignment: .top, spacing: 2.5) {
                                    Image("thumbsUp").offset(y: -4.5)
                                    Text("\(Int(like_count/(like_count + dislike_count)*100))%").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                    Text(view_count + " views").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))


                                    Spacer()
                                }.offset(y: 4).padding(.bottom, 4)
                                HStack() {



                                    Text(duration.getYoutubeFormattedDuration()).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(1).onAppear() {

                                    }

                                    Text(video.snippet.channelTitle ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                }
                            }
                            Spacer()
                            Button(action: {
                                Task {
                                    let id = video.id
                                    guard !id.isEmpty else { return }
                                    if let result = try? await OldOSYouTubePlayback.shared.metadata(videoID: id) {
                                        await MainActor.run {
                                            featured_current_video = result
                                            forward_or_backward = false
                                            withAnimation(.linear(duration: 0.28)){ featured_current_nav_view = "Video_Destination" }
                                        }
                                    }
                                }
                            }) {
                                Image("ABTableNextButton").padding(.trailing, 12)
                            }
                        }

                        Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)

                    }.frame(height: 90)
                }.frame(height: 90).buttonStyle(BlankButtonStyle())
            }
        }.background(Color.white)
    }
}

struct YoutubeMostViewedView: View {
    @StateObject var most_viewed_observer: MostViewedObserver
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var mv_current_nav_view: String
    @Binding var mv_current_video: YouTubeVideoData?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var selected_segment: Int
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch mv_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view(current_nav_view: $mv_current_nav_view, current_video: $mv_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: selected_segment == 0 ? most_viewed_observer.today : selected_segment == 1 ? most_viewed_observer.this_week : most_viewed_observer.all_time, geometry: geometry, placeholder_content: {
                            HStack {
                                Spacer()
                                ProgressView().progressViewStyle(CircularProgressViewStyle())
                                Spacer().frame(width: 8)
                                Text("Loading...").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                Spacer()
                                
                            }.frame(width: geometry.size.width, height: geometry.size.height)
                        })
                        Spacer()
                    }
                    
                }.background(Color.white).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $mv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: mv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $mv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: mv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }
    }
}

struct YoutubeSearchView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var search_current_nav_view: String
    @Binding var search_current_video: YouTubeVideoData?
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch search_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view(current_nav_view: $search_current_nav_view, current_video: $search_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: search_results, geometry: geometry, placeholder_content: {
                            if is_searching {
                                HStack {
                                    Spacer()
                                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                                    Spacer().frame(width: 8)
                                    Text("Loading...").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                    
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            } else {
                                HStack {
                                    Spacer()
                                    Text("No Videos").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                    Spacer()
                                    
                                }.frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        })
                        Spacer()
                    }
                }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $search_current_nav_view, forward_or_backward: $forward_or_backward, current_video: search_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $search_current_nav_view, forward_or_backward: $forward_or_backward, current_video: search_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }.background(Color.white)
    }
}


struct result_content_view<PlaceholderContent: View>: View {
    @Binding var current_nav_view: String
    @Binding var current_video: YouTubeVideoData?
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var content: [YouTubeVideoData]
    var geometry: GeometryProxy
    var placeholder_content: () -> PlaceholderContent
    init(current_nav_view: Binding<String>, current_video: Binding<YouTubeVideoData?>, forward_or_backward: Binding<Bool>, show_video_player: Binding<Bool>, instant_video_change: Binding<Bool>, selected_video_player: Binding<AVPlayer>, content:  [YouTubeVideoData], geometry: GeometryProxy, @ViewBuilder placeholder_content: @escaping () -> PlaceholderContent) {
        _current_nav_view = current_nav_view
        _current_video = current_video
        _forward_or_backward = forward_or_backward
        _show_video_player = show_video_player
        _instant_video_change = instant_video_change
        _selected_video_player = selected_video_player
        self.placeholder_content = placeholder_content
        self.content = content
        self.geometry = geometry
    }
    var body: some View {
        VStack {
            if content.isEmpty {
               
                placeholder_content()
          
            } else {
                VStack(spacing:0){
                    ForEach(content, id:\.id) { video in
                        let index = content.firstIndex(where: { $0.id == video.id }) ?? 0
                        let videoData = content[optional: index]
                        let likeText = videoData?.ratings?.likes?.text ?? ""
                        let dislikeText = videoData?.ratings?.dislikes?.text ?? ""
                        let like_count = Int(likeText.filter("0123456789.".contains)) ?? 1
                        let dislike_count = Int(dislikeText.filter("0123456789.".contains)) ?? 1
                        let view_count = (videoData?.views?.text ?? "").filter("0123456789.".contains)
                        let durationRaw = videoData?.duration?.lengthSec ?? ""
                        let duration = Double(durationRaw.filter("0123456789.".contains) ?? "") ?? 0
                        let percentage = oldOSApprovalPercent(video)

                        Button(action:{
                            oldOSStartPlayback(videoID: video.id, selectedPlayer: $selected_video_player, showPlayer: $show_video_player, instantChange: $instant_video_change)
                            
                        }) {
                            VStack(spacing: 0) {
                                HStack {
                                    
                                    WebImage(url: video.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                        Image("DefaultThumbnail")
                                    }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                        HStack(alignment: .top, spacing: 2.5) {
                                            Image("thumbsUp").offset(y: -4.5)
                                            Text("\(percentage)%").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                            Text(view_count + " views").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255))
                                            
                                            
                                            Spacer()
                                        }.offset(y: 4).padding(.bottom, 4)
                                        HStack() {
                                       
                                            
                                            
                                            Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                               
                                            }
                                            
                                            Text(video.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Button(action: {
                                        current_video = video
                                        if let id = video.id {
                                            Task {
                                                if let enriched = try? await OldOSYouTubePlayback.shared.metadata(videoID: id) {
                                                    await MainActor.run { current_video = enriched }
                                                }
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Destination"}
                                        }
                                    }) {
                                        Image("ABTableNextButton").padding(.trailing, 12)
                                    }
                                }
                              
                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
            
                                
                            }.frame(height: 90)
                        }.frame(height: 90).buttonStyle(BlankButtonStyle())
                    }
                }.background(Color.white)
           
            }
         
        }
        
    }
}

struct result_content_view_favorites<PlaceholderContent: View>: View {
    @State var to_delete: String = ""
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var is_editing_favorites: Bool
    @Binding var current_nav_view: String
    @Binding var current_video: YouTubeVideoData?
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var content: [YouTubeVideoData]
    var geometry: GeometryProxy
    var placeholder_content: PlaceholderContent
    init(favorite_observer: StateObject<favorite_videos_observer>, is_editing_favorites: Binding<Bool>, current_nav_view: Binding<String>, current_video: Binding<YouTubeVideoData?>, forward_or_backward: Binding<Bool>, show_video_player: Binding<Bool>, instant_video_change: Binding<Bool>, selected_video_player: Binding<AVPlayer>, content:  [YouTubeVideoData], geometry: GeometryProxy, @ViewBuilder placeholder_content: @escaping () -> PlaceholderContent) {
        _is_editing_favorites = is_editing_favorites
        _current_nav_view = current_nav_view
        _current_video = current_video
        _forward_or_backward = forward_or_backward
        _show_video_player = show_video_player
        _instant_video_change = instant_video_change
        _selected_video_player = selected_video_player
        self.placeholder_content = placeholder_content()
        self.content = content
        self.geometry = geometry
        _favorite_observer = favorite_observer
    }
    var body: some View {
        VStack {
            if content.isEmpty {
              
                placeholder_content
              
            } else {
                VStack(spacing:0){
                    ForEach(content, id:\.id) { video in
                        let like_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.likes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let dislike_count = Int((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.ratings?.dislikes?.text ?? "").filter("0123456789.".contains)) ?? 1
                        let view_count = (content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.views?.text ?? "").filter("0123456789.".contains) ?? ""
                        let duration = Double((content[optional: content.firstIndex(where: {$0.id == video.id}) ?? 0]?.duration?.lengthSec ?? "").filter("0123456789.".contains) ?? "") ?? 0
                        Button(action:{
                            if !is_editing_favorites {
                            oldOSStartPlayback(videoID: video.id, selectedPlayer: $selected_video_player, showPlayer: $show_video_player, instantChange: $instant_video_change)
                            }
                            
                        }) {
                            VStack(spacing: 0) {
                                HStack {
                                    if is_editing_favorites == true {
                                        Button(action:{
                                            withAnimation(.linear(duration:0.15)) {
                                                if to_delete != video.id ?? "" {
                                                to_delete = video.id ?? ""
                                                } else {
                                                    to_delete = ""
                                                }
                                            }
                                        }) {
                                            ZStack {
                                            Image("UIRemoveControlMinus")
                                                Text("—").foregroundColor(.white).font(.system(size: 15, weight: .heavy, design: .default)).offset(y:to_delete == video.id ? -0.8 : -2).rotationEffect(.degrees(to_delete == video.id ? -90 : 0), anchor: .center).offset(y:to_delete == video.id ? -0.5 : 0)
                                            }
                                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:.leading), removal: .move(edge:.leading)).combined(with: .opacity)).offset(x:-2).padding(.leading, 5)
                                    }
                                    WebImage(url: video.thumbnails?[optional: 0]?.url).resizable().placeholder {
                                        Image("DefaultThumbnail")
                                    }.aspectRatio(contentMode: .fit).frame(width:geometry.size.width/3, height: 89).background(Color.black).border_top(width: 1, edges:[.trailing], color: Color(red: 217/255, green: 217/255, blue: 217/255))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                        HStack(alignment: .top, spacing: 2.5) {
                                            Image("thumbsUp").offset(y: -4.5)
                                            Text("\(oldOSApprovalPercent(video))%").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 73/255, green: 128/255, blue: 35/255))
                                            Text(view_count + " views").font(.custom("Helvetica Neue Regular", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(0)
                                            
                                            
                                            Spacer()
                                        }.offset(y: 4).padding(.bottom, 4)
                                        HStack() {
                           
                                            
                                            
                                            Text(duration.asString(style: .positional)).font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.black).lineLimit(1).onAppear() {
                                 
                                            }
                                          
                                            Text(video.channel?.name ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 103/255, green: 109/255, blue: 115/255)).lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if !is_editing_favorites {
                                    Button(action: {
                                        if !is_editing_favorites {
                                        current_video = video
                                        if let id = video.id {
                                            Task {
                                                if let enriched = try? await OldOSYouTubePlayback.shared.metadata(videoID: id) {
                                                    await MainActor.run { current_video = enriched }
                                                }
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Video_Destination"}
                                        }
                                        }
                                    }) {
                                        Image("ABTableNextButton").padding(.trailing, 12)
                                    }
                                    }
                                    if to_delete == video.id ?? "", is_editing_favorites == true {
                                        Spacer()
                                        tool_bar_rectangle_button(action: {withAnimation() {
                                            if let idx = favorite_observer.favorites.firstIndex(where: {$0 == video.id}) {
                                                favorite_observer.favorites.remove(at: idx)
                                            }
                                            if let idx = favorite_observer.videos.firstIndex(where: {$0.id == video.id}) {
                                                favorite_observer.videos.remove(at: idx)
                                            }
                                        }}, button_type: .red, content: "Delete").padding(.trailing, 12).transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge:.trailing)).combined(with: .opacity))
                                    }
                                }
                             
                                Rectangle().fill(Color(red: 171/255, green: 171/255, blue: 171/255)).frame(height: 1)
                
                                
                            }.frame(height: 90)
                        }.frame(height: 90).buttonStyle(BlankButtonStyle())
                    }
                }.background(Color.white)

            }
     
        }
        
    }
}

struct YoutubeFavoriteView: View {
    @StateObject var favorite_observer: favorite_videos_observer
    @Binding var fv_current_nav_view: String
    @Binding var fv_current_video: YouTubeVideoData?
    @Binding var is_editing_favorites: Bool
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var selected_video_player: AVPlayer
    var body: some View {
        GeometryReader { geometry in
            switch fv_current_nav_view {
            case "Main":
                VStack(spacing:0) {
                    ScrollView(showsIndicators: true) {
                        result_content_view_favorites(favorite_observer: _favorite_observer, is_editing_favorites: $is_editing_favorites, current_nav_view: $fv_current_nav_view, current_video: $fv_current_video, forward_or_backward: $forward_or_backward, show_video_player: $show_video_player, instant_video_change: $instant_video_change, selected_video_player: $selected_video_player, content: favorite_observer.videos, geometry: geometry, placeholder_content: {
                            HStack {
                                Spacer()
                                Text("No Videos").font(.custom("Helvetica Neue Regular", fixedSize: 16)).foregroundColor(Color(red: 129/255, green: 129/255, blue: 129/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                                Spacer()
                                
                            }.frame(width: geometry.size.width, height: geometry.size.height)
                        })
                        Spacer()
                    }
                    
                }.background(Color.white).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Destination":
                YoutubeDetailView(favorite_observer: favorite_observer, current_nav_view: $fv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: fv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Video_Info":
                YoutubeVideoInfoView(current_nav_view: $fv_current_nav_view, forward_or_backward: $forward_or_backward, current_video: fv_current_video).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                Spacer()
            }
        }
    }
}

class favorite_videos_observer: ObservableObject {
    @Published var favorites: [String] {
        didSet {
            let oldCount = (UserDefaults.standard.object(forKey: "yt_favorites") as? [String] ?? []).count
            UserDefaults.standard.set(favorites, forKey: "yt_favorites")
            if oldCount < favorites.count { refresh() }
        }
    }
    @Published var videos = [YouTubeVideoData]()

    init() {
        self.favorites = UserDefaults.standard.object(forKey: "yt_favorites") as? [String] ?? []
        reloadAll()
    }

    private func reloadAll() {
        let ids = favorites
        Task {
            var loaded = [YouTubeVideoData]()
            for id in ids {
                if let video = try? await OldOSYouTubePlayback.shared.metadata(videoID: id) {
                    loaded.append(video)
                }
            }
            await MainActor.run { self.videos = loaded }
        }
    }

    func refresh() {
        guard let id = favorites.last else { return }
        Task {
            guard let video = try? await OldOSYouTubePlayback.shared.metadata(videoID: id) else { return }
            await MainActor.run {
                if self.videos.contains(where: { $0.id == video.id }) == false {
                    self.videos.append(video)
                }
            }
        }
    }
}


struct youtube_more_item: Identifiable {
    let id = UUID()
    let name: String
    let image: String
}

struct youtube_more: View {
    var items = [youtube_more_item(name: "Most Recent", image: "YTBarMostRecent"), youtube_more_item(name: "Top Rated", image: "YTBarFavorites"), youtube_more_item(name: "History", image: "YTBarHistory"), youtube_more_item(name: "My Videos", image: "YTBarMyVideos"), youtube_more_item(name: "Subscriptions", image: "YTBarSubscriptions"), youtube_more_item(name: "Playlists", image: "YTBarPlaylists")]
    var body: some View {
        NoSepratorList {
            ForEach(items, id:\.id) { item in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center) {
                        Spacer().frame(width:1, height: 44-0.95)
                        Image(item.image).frame(width:25, height: 44-0.95)
                        Text(item.name).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                        Spacer()
                        Image("UITableNext").padding(.trailing, 12)
                    }.padding(.leading, 15)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    
                }
            }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()
            
        }.background(Color.white)
    }
}



struct containerYoutube: View {
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @Binding var player: AVPlayer
    @StateObject private var playerObserver = PlayerItemObserver()

    var body: some View {
        YoutubeVideoPlayer(
            player: $player,
            show_video_player: $show_video_player,
            instant_video_change: $instant_video_change,
            playerObserver: playerObserver
        )
        .onAppear {
            playerObserver.attach(to: player)
        }
        .onReceive(Just(ObjectIdentifier(player))) { _ in
            playerObserver.attach(to: player)
        }
    }
}

struct YoutubeVideoPlayer: View {
    @Binding var player: AVPlayer
    @Binding var show_video_player: Bool
    @Binding var instant_video_change: Bool
    @ObservedObject var playerObserver: PlayerItemObserver
    @State var showing_title: Bool = false
    @State var gravity: PlayerGravity = .fit
    @State var show_controls: Bool = true
    @State var pervent_delta: Bool = false
    @State private var controlsHideGeneration: UInt64 = 0
    @ObservedObject private var volObserver = VolumeObserver()
    var body: some View {
        GeometryReader {geometry in
            
            ZStack {
                if player.currentItem != nil {
                    PlayerContainerView(player: player, gravity: gravity)
                        .frame(width: geometry.size.height, height: geometry.size.width)
                        .background(Color.black)
                        .onTapGesture() {
                        if pervent_delta == false {
                            pervent_delta = true
                            withAnimation(.linear(duration: show_controls == true ? 0.25 : 0.1)) {
                                show_controls.toggle()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                pervent_delta = false
                            }
                            if show_controls { scheduleControlsHide() } else { cancelControlsHide() }
                        }
                    }
                } else {
                    Rectangle().fill(LinearGradient([Color(red: 145/255, green: 145/255, blue: 145/255), .black], from: .top, to: .bottom)).frame(width: geometry.size.height, height: geometry.size.width)
                    Image("YouTubeBug")
                }
                if show_controls {
                    VStack(spacing: 0) {
                        status_bar().frame(width: geometry.size.height, height: 24)
                        video_player_title_bar(player: $player, gravity: $gravity, playerObserver: playerObserver, title: "", is_loading: playerObserver.itemStatus != .readyToPlay, back_action: {
                            oldOSStopPlayback(player); withAnimation(.linear(duration: 0.075)){show_controls = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { withAnimation(.linear(duration: 0.4)) {show_video_player = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                instant_video_change = false
                            }}
                        }, gravity_action: {
                            if gravity == .fit {
                                gravity = .aspectFill
                            } else {
                                gravity = .fit
                            }
                        }).frame(width: geometry.size.height, height: 60)
                        Spacer()
                    }.frame(width: geometry.size.height, height: geometry.size.width).zIndex(1)
                    VStack {
                        Spacer()
                        video_player_footer(player: $player, playerObserver: playerObserver, back_action: {
                            oldOSStopPlayback(player); withAnimation(.linear(duration: 0.075)){show_controls = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { withAnimation(.linear(duration: 0.4)) {show_video_player = false}; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                instant_video_change = false
                            }}
                        }).frame(width: geometry.size.height - 250, height: geometry.size.width/4).padding(.bottom, 40)
                    }.frame(width: geometry.size.height, height: geometry.size.width).zIndex(1)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.rotationEffect(.degrees(90))
        .onReceive(playerObserver.$currentStatus) { newStatus in
            if newStatus == .playing {
                scheduleControlsHide()
            } else {
                cancelControlsHide()
            }
        }
        .onChange(of: playerObserver.shouldUpdateFromTimer) { isTimerDriven in
            if isTimerDriven == false {
                                                                                     
                                                                                    
                cancelControlsHide()
                if !show_controls { withAnimation(.linear(duration: 0.1)) { show_controls = true } }
            } else if playerObserver.currentStatus == .playing {
                                                                                   
                                                                                        
                scheduleControlsHide()
            }
        }
        .onDisappear() {
            cancelControlsHide()
            oldOSStopPlayback(player)
            playerObserver.invalidate()
        }
    }

    private func cancelControlsHide() {
        controlsHideGeneration &+= 1
    }

    private func scheduleControlsHide(after delay: Double = 3.0) {
        controlsHideGeneration &+= 1
        let generation = controlsHideGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard generation == controlsHideGeneration,
                  playerObserver.shouldUpdateFromTimer != false,
                  playerObserver.currentStatus == .playing,
                  show_controls else { return }
            withAnimation(.linear(duration: 0.25)) { show_controls = false }
        }
    }
}

class VPUtility: NSObject {
    
    private static var timeHMSFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter
    }()
    
    static func formatSecondsToHMS(_ seconds: Double) -> String {
        guard !seconds.isNaN,
              let text = timeHMSFormatter.string(from: seconds) else {
            return "00:00"
        }
        
        return text
    }
    
}

struct video_player_footer: View {
    @Binding var player: AVPlayer
    @ObservedObject private var volObserver = VolumeObserver()
    @ObservedObject var playerObserver: PlayerItemObserver
    public var back_action: (() -> Void)?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(LinearGradient([(Color(red: 191/255, green: 191/255, blue: 191/255), location: 0), (Color(red: 64/255, green: 64/255, blue: 64/255), location: 0.50), (Color(red: 0/255, green: 0/255, blue: 0/255), location: 0.50), (Color(red: 0/255, green: 0/255, blue: 0/255), location: 1)], from: .top, to: .bottom)).opacity(0.6).strokeRoundedRectangle(8, LinearGradient([(Color(red: 212/255, green: 212/255, blue: 212/255), location: 0), (Color(red: 179/255, green: 179/255, blue: 179/255), location: 0.04), (Color(red: 155/255, green: 155/255, blue: 155/255), location: 1)], from: .top, to: .bottom), lineWidth: 2)
                VStack(spacing: 0) {
                    HStack {
                        Image("mp_addbookmark").padding(.leading, 12)
                        Spacer()
                        Button(action: {
                            if playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 {
                                back_action?()
                            }
                        }) {
                            Image("mp_prevtrack")
                        }.opacity(playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 ? 1 : 0.6)
                        Spacer()
                        Button(action: {
                            if playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 {
                                if playerObserver.currentStatus != .playing {
                                    player.play()
                                } else {
                                    player.pause()
                                }
                            }
                        }) {
                            Image(playerObserver.currentStatus != .playing ? "mp_play" : "mp_pause")
                        }.frame(width: 40).opacity(playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 ? 1 : 0.6)
                        Spacer()
                        Button(action: {
                            if playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 {
                                back_action?()
                            }
                        }) {
                            Image("mp_nexttrack")
                        }.opacity(playerObserver.itemStatus == .readyToPlay && playerObserver.duration > 0 ? 1 : 0.6)
                        Spacer()
                        Image("mp_email").padding(.trailing, 12)
                    }.frame(width: geometry.size.width).padding(.top, 10)
                    CustomSliderVideo(player: $player, type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                        ZStack {
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                            
                            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                            ZStack {
                                Image("volume-slider-fat-knob").resizable().scaledToFill()
                                
                            }.modifier(modifiers.knob)
                        }
                    }.frame(height: 25).padding([.top, .bottom]).padding([.leading, .trailing], 30)
                }.frame(height: geometry.size.height)
            }
        }
    }
}

struct video_player_title_bar : View {
    @Binding var player: AVPlayer
    @Binding var gravity: PlayerGravity
    @ObservedObject var playerObserver: PlayerItemObserver
    var title: String
    var is_loading: Bool
    public var back_action: (() -> Void)?
    public var gravity_action: (() -> Void)?
    var shows_back: Bool?
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.005), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 0.95, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025).opacity(0.65).shadow(color: Color.black.opacity(0.25), radius: 0.25, x: 0, y: -0.5)                                        
            VStack {
                Spacer()
                if is_loading {
                    ZStack {
                        HStack {
                            Text("Loading...").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.white)
                            Spacer().frame(width: 8)
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        }
                        HStack {
                            tool_bar_rectangle_button(action: {back_action?()}, button_type: .blue, content: "Done").padding(.leading, 5)
                            Spacer()
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        tool_bar_rectangle_button(action: {back_action?()}, button_type: .blue, content: "Done").padding(.leading, 5)
                        Spacer()
                        Text("\(VPUtility.formatSecondsToHMS(playerObserver.seekPos * playerObserver.duration))").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).padding([.leading], 15)
                        CustomSliderVideo(player: $player, type: "Video", should_update_from_timer: $playerObserver.shouldUpdateFromTimer, value: $playerObserver.seekPos, range: (0, 1)) { modifiers in
                            ZStack {
                                ZStack {
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 9).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)
                                    
                                    LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 9).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                }.overlay(LinearGradient([Color(red: 48/255, green: 50/255, blue: 53/255), Color(red: 87/255, green: 93/255, blue: 97/255)], from: .top, to: .bottom).mask(LinearGradient([(Color.black, location: 0), (Color.black, location: playerObserver.duration > 0 ? playerObserver.buffer/playerObserver.duration : 0), (Color.white, location: playerObserver.duration > 0 ? playerObserver.buffer/playerObserver.duration : 0)], from: .leading, to: .trailing).frame(height: 4.5).cornerRadius(4.25/8.5*4.5).luminanceToAlpha()).frame(height: 4.5).cornerRadius(4.25/8.5*4.5).padding([.leading, .trailing], 7).offset(y: 0.25))
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                    
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 25)
                        Text("-\(VPUtility.formatSecondsToHMS(max(0, playerObserver.duration - playerObserver.seekPos * playerObserver.duration)))").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).padding([.trailing], 15)
                        Spacer()
                        tool_bar_rectangle_button_image_done_size(action: {gravity_action?()}, button_type: .black, content: gravity == .fit ? "mp_zoomout" : "mp_zoomin", use_image: true).padding(.trailing, 5)
                    }
                }
                Spacer()
            }
        }
    }
}



class PlayerItemObserver: ObservableObject {
    @Published var currentStatus: AVPlayer.TimeControlStatus?
    @Published var playerStatus: AVPlayer.Status?
    @Published var itemStatus: AVPlayerItem.Status = .unknown
    @Published var seekPos: Double = 0.0
    @Published var buffer: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var shouldUpdateFromTimer: Bool? = true

    private weak var player: AVPlayer?
    private var observedPlayerID: ObjectIdentifier?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()

    init(player: AVPlayer? = nil) {
        if let player {
            attach(to: player)
        }
    }

    func attach(to newPlayer: AVPlayer) {
        let newID = ObjectIdentifier(newPlayer)
        guard observedPlayerID != newID else { return }

        detach()
        player = newPlayer
        observedPlayerID = newID

        currentStatus = newPlayer.timeControlStatus
        playerStatus = newPlayer.status
        itemStatus = newPlayer.currentItem?.status ?? .unknown
        seekPos = 0
        buffer = 0
        duration = 0

        newPlayer.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.currentStatus = status
                if status == .waitingToPlayAtSpecifiedRate {
                    print("OldOS YouTube AVPlayer waiting:", newPlayer.reasonForWaitingToPlay?.rawValue ?? "unknown")
                }
            }
            .store(in: &cancellables)

        newPlayer.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.playerStatus = status
                if status == .failed {
                    print("OldOS YouTube AVPlayer failed:", newPlayer.error?.localizedDescription ?? "unknown")
                }
            }
            .store(in: &cancellables)

        if let item = newPlayer.currentItem {
            item.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    self?.itemStatus = status
                    switch status {
                    case .readyToPlay:
                        print("OldOS YouTube AVPlayerItem readyToPlay")
                    case .failed:
                        print("OldOS YouTube AVPlayerItem failed:", item.error?.localizedDescription ?? "unknown")
                    case .unknown:
                        break
                    @unknown default:
                        break
                    }
                }
                .store(in: &cancellables)

            item.publisher(for: \.loadedTimeRanges)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] ranges in
                    guard let range = ranges.first?.timeRangeValue else { return }
                    self?.buffer = max(0, CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration))
                }
                .store(in: &cancellables)
        }

        timeObserverToken = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
            queue: .main
        ) { [weak self, weak newPlayer] time in
            guard let self, let item = newPlayer?.currentItem else { return }
            let d = item.duration.seconds
            if d.isFinite, d > 0 {
                self.duration = d
                if self.shouldUpdateFromTimer != false {
                    self.seekPos = min(max(time.seconds / d, 0), 1)
                }
            }
        }
    }

    private func detach() {
        cancellables.removeAll()
        if let token = timeObserverToken, let player {
            player.removeTimeObserver(token)
        }
        timeObserverToken = nil
        player = nil
        observedPlayerID = nil
    }

    func invalidate() {
        detach()
    }

    deinit {
        detach()
    }
}


extension Double {
    func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
        let formatter = DateComponentsFormatter()
        if self > 3600 {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else {
            formatter.allowedUnits = [.minute, .second]
        }
        formatter.unitsStyle = style
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? ""
    }
}

struct youtube_title_bar : View {
    var title:String
    @Binding var selectedTab: String
    @Binding var selected_segment: Int
    @Binding var instant_multitasking_change: Bool
    @Binding var search_results: [YouTubeVideoData]
    @Binding var is_searching: Bool
    @Binding var forward_or_backward: Bool
    @Binding var featured_current_nav_view: String
    @Binding var mv_current_nav_view: String
    @Binding var fv_current_nav_view: String
    @Binding var search_current_nav_view: String
    @Binding var instant_video_change: Bool
    @Binding var is_editing_favorites: Bool
    @State var search: String = ""
    @State var place_holder = ""
    var no_right_padding: Bool?
    @State var editing_state: String = "None"
    public var done_action: (() -> Void)?
    public var editing_favorites_action: (() -> Void)?
    var show_done: Bool?
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    var body :some View {
        GeometryReader {geometry in
            ZStack {
                LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if (selectedTab != "Most Viewed" || mv_current_nav_view != "Main"), (selectedTab != "Search" || search_current_nav_view != "Main") {
                            Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).id(title).frame(maxWidth: selectedTab == "Most Viewed" ? 145 : 180)
                        } else if selectedTab == "Most Viewed" {
                            tri_segmented_control_youtube(selected: $selected_segment, instant_multitasking_change: $instant_multitasking_change, first_text: "Today", second_text: "This week", third_text: "All", should_animate: instant_video_change).frame(width: geometry.size.width-24, height: 30)
                        } else if selectedTab == "Search" {
                            VStack {
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer(minLength: 5)
                                        HStack (alignment: .center,
                                                spacing: 10) {
                                            Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)
                                    
                                            
                                            TextField ("YouTube", text: $search, onEditingChanged: { (changed) in
                                                if changed  {
                                                    withAnimation() {
                                                        editing_state = "Active_Empty"
                                                    }
                                                } else {
                                                    withAnimation() {
                                                        editing_state = "None"
                                                    }
                                                }
                                            }) {
                                                withAnimation() {
                                                    editing_state = "None"
                                                }
                                                if search != "" {
                                                    search_results.removeAll()
                                                    is_searching = true
                                                    Task {
                                                        do {
                                                            let results = try await OldOSYouTubeDiscovery.shared.search(search)
                                                            await MainActor.run {
                                                                search_results = results
                                                                is_searching = false
                                                            }
                                                        } catch {
                                                            print("OldOS YouTube search failed:", error)
                                                            await MainActor.run { is_searching = false }
                                                        }
                                                    }
                                                }
                                                
                                            }.onChange(of: search) { _ in
                                                if search != "" {
                                                    editing_state = "Active"
                                                } else {
                                                    if editing_state != "None" {
                                                        editing_state = "Active_Empty"
                                                    }
                                                }
                                            }.keyboardType(.alphabet).submitLabel(.search).oldOSKeyboard(.search)
                                            if search.count != 0 {
                                                Button(action:{search = ""}) {
                                                    Image("UITextFieldClearButton")
                                                }.fixedSize()
                                            }
                                        }.padding([.top,.bottom], 5).padding(.leading, 5).cornerRadius(40)
                                        Spacer(minLength: 8)
                                    } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, 5.5)
                                }
                                Spacer()
                            }
                        }
                        Spacer()
                    }
                    Spacer()
                }
                if show_done == true {
                    HStack {
                        Spacer()
                        tool_bar_rectangle_button(action: {done_action?()}, button_type: .blue, content: "Done").padding(.trailing, 5)
                    }
                }
                if selectedTab == "Featured", featured_current_nav_view != "Main" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){featured_current_nav_view = (featured_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Search").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Most Viewed", mv_current_nav_view != "Main" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){mv_current_nav_view = (mv_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button_wp5").resizable().scaledToFit().frame(width:200*84/162*(33/34.33783783783784), height: 33)
                                    HStack(alignment: .center) {
                                        Text("Most Viewed").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Search", search_current_nav_view != "Main" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){search_current_nav_view = (search_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Search").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading, 5).offset(y: -1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge:.trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "Favorites", fv_current_nav_view != "Main" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            Button(action:{
                                forward_or_backward = true; withAnimation(.linear(duration: 0.28)){fv_current_nav_view = (fv_current_nav_view == "Video_Info" ? "Video_Destination": "Main")}
                            }){
                                ZStack {
                                    Image("Button2").resizable().aspectRatio(contentMode: .fit).frame(width:77)
                                    HStack(alignment: .center) {
                                        Text("Favorites").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading, 5).offset(y: -1.1)
                                    }
                                }.padding(.leading, 6)
                            }.transition(AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                            Spacer()
                        }
                        Spacer()
                    }.offset(y: -0.5)
                    
                }
                if selectedTab == "Favorites", fv_current_nav_view == "Main" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            tool_bar_rectangle_button(action: {}, button_type: .blue_gray, content: " Sign In ").padding(.leading, 5)
                            Spacer()
                            tool_bar_rectangle_button(action: {editing_favorites_action?()}, button_type: is_editing_favorites == false ? .blue_gray : .blue, content: is_editing_favorites == false ? " Edit " : "Done").padding(.trailing, 5)
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
                if selectedTab == "More" {                                      
                    VStack {
                        Spacer()
                        HStack {
                            tool_bar_rectangle_button(action: {}, button_type: .blue_gray, content: " Sign In ").padding(.leading, 5)
                            Spacer()
                        }
                        Spacer()
                    }.offset(y:-0.5)
                    
                }
            }
        }
    }
}

extension String {
    
    func getYoutubeFormattedDuration() -> String {
        
        let formattedDuration = self.replacingOccurrences(of: "PT", with: "").replacingOccurrences(of: "H", with:":").replacingOccurrences(of: "M", with: ":").replacingOccurrences(of: "S", with: "")
        
        let components = formattedDuration.components(separatedBy: ":")
        var duration = ""
        for component in components {
            duration = duration.count > 0 ? duration + ":" : duration
            if component.count < 2 {
                duration += "0" + component
                continue
            }
            duration += component
        }
        
        return duration
        
    }
    
}

func format_video_duration(duration: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    let date = formatter.date(from: duration) ?? Date()
    return formatter.string(from: date)
}

class YoutubeObserver: ObservableObject {
    @Published var featured = [YoutubeFeatured.Item]()
    @Published var featured_stats = [YoutubeVideoStats.Item]()
    @Published var featured_details = [YoutubeVideoDetails.Item]()
    @Published var videos = [YouTubeVideoData]()
    @Published var errorMessage: String?
    private var hasStarted = false

    init() {}

    func loadIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        parse_data()
    }

    func parse_data() {
        Task {
            do {
                let result = try await OldOSYouTubeDiscovery.shared.featured()
                await MainActor.run { self.videos = result; self.errorMessage = nil }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.hasStarted = false }
            }
        }
    }
}

class MostViewedObserver: ObservableObject {
    @Published var today = [YouTubeVideoData]()
    @Published var this_week = [YouTubeVideoData]()
    @Published var all_time = [YouTubeVideoData]()
    @Published var errorMessage: String?
    private var hasStarted = false

    init() {}

    func loadIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        parse_data()
    }

    func parse_data() {
        Task {
                                                                                       
                                                                            
            var anyLoaded = false
            var lastError: Error?

            do {
                let t = try await OldOSYouTubeDiscovery.shared.mostViewed(.today)
                await MainActor.run { self.today = t; self.errorMessage = nil }
                anyLoaded = anyLoaded || !t.isEmpty
            } catch { lastError = error }

            do {
                let w = try await OldOSYouTubeDiscovery.shared.mostViewed(.week)
                await MainActor.run { self.this_week = w; self.errorMessage = nil }
                anyLoaded = anyLoaded || !w.isEmpty
            } catch { lastError = error }

            do {
                let a = try await OldOSYouTubeDiscovery.shared.mostViewed(.all)
                await MainActor.run { self.all_time = a; self.errorMessage = nil }
                anyLoaded = anyLoaded || !a.isEmpty
            } catch { lastError = error }

            if !anyLoaded {
                await MainActor.run {
                    self.errorMessage = lastError?.localizedDescription ?? "YouTube Most Viewed returned no videos."
                    self.hasStarted = false
                }
            }
        }
    }
}


func parseJsonSearchData(data: Data) -> [YoutubeVideoSearchData.Videos]? {
    
    var application_data = [YoutubeVideoSearchData.Videos]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoSearchData.self, from: data)
        application_data = loanDataStore.videos ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}


func parseJsonYoutubeMostViewedData(data: Data) -> [MostViewed.Item]? {
    
    var application_data = [MostViewed.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(MostViewed.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}

func parseJsonYoutubeFeaturedData(data: Data) -> [YoutubeFeatured.Item]? {
    
    var application_data = [YoutubeFeatured.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeFeatured.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}


func parseJsonYoutubeFeaturedDataS(data: Data) -> [YoutubeVideoStats.Item]? {
    
    var application_data = [YoutubeVideoStats.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoStats.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}

func parseJsonYoutubeFeaturedDataD(data: Data) -> [YoutubeVideoDetails.Item]? {
    
    var application_data = [YoutubeVideoDetails.Item]()
    
    let decoder = JSONDecoder()
    
    do {
        let loanDataStore = try decoder.decode(YoutubeVideoDetails.self, from: data)
        application_data = loanDataStore.items ?? []
        
    } catch {
        print(error)
    }
    
    return application_data
}

struct TabButton_Youtube : View {
    
    var image : String
    @Binding var selectedTab : String
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(width: geometry.size.width/5 - 5, height: 51).blendMode(.screen)
                    VStack(spacing: 2) {
                        if image == "Featured" {
                            Image("UITabBarFeaturedSelected2").resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5)
                        } else {
                            ZStack {
                                Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5).overlay(
                                    LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30.5, height: 30.5)).offset(y:-0.5)
                                
                                Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : 30, height: 30).overlay(
                                    ZStack {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Search" ? 38 : image == "Contacts" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                        if image == "Featured" {
                                            VStack(spacing:0) {
                                                HStack(spacing:0) {
                                                    ZStack {
                                                        Ellipse().fill(LinearGradient(gradient: Gradient(stops:[.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(width: 16, height: 12).offset(y:-1)
                                                    }
                                                    Spacer().frame(width: 7)
                                                    ZStack {
                                                        Ellipse().fill(Color(red: 185/255, green: 249/255, blue: 254/255)).frame(width: 16, height: 12).offset(y:-1)
                                                        Ellipse().fill(LinearGradient(gradient: Gradient(stops:[.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(width: 16, height: 6).brightness(0.095).offset(y:1.5)
                                                    }
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                            }
                        }
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
                            if image != "Most Viewed" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_Store").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Search" ? 25 : image == "Featured" ? 37.5 : image == "Most Viewed" ? 35.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            if image != "Most Viewed" {
                                Spacer()
                            }
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: image == "Most Viewed" ? 10.75 : 11)).fixedSize(horizontal: true, vertical: false)
                            if image != "Most Viewed" {
                                Spacer()
                            }
                        }.frame(maxWidth: geometry.size.width/5 - 5)
                    }
                }
            }
        }
    }
}


struct YoutubeFeatured: Codable {
    struct Item: Codable {
        struct Snippet: Codable {
            struct Thumbnail: Codable {
                struct Default: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Medium: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct High: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Standard: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Maxre: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                let `default`: Default
                let medium: Medium
                let high: High
                let standard: Standard?
                let maxres: Maxre?
            }
            
            struct Localized: Codable {
                let title: String
                let description: String
            }
            
            let publishedAt: String?
            let channelID: String
            let title: String
            let description: String
            let thumbnails: Thumbnail
            let channelTitle: String
            let tags: [String]?
            let categoryID: String
            let liveBroadcastContent: String
            let localized: Localized
            let defaultLanguage: String?
            let defaultAudioLanguage: String?
            
            private enum CodingKeys: String, CodingKey {
                case publishedAt
                case channelID = "channelId"
                case title
                case description
                case thumbnails
                case channelTitle
                case tags
                case categoryID = "categoryId"
                case liveBroadcastContent
                case localized
                case defaultLanguage
                case defaultAudioLanguage
            }
        }
        
        let kind: String?
        let etag: String?
        let id: String
        let snippet: Snippet
    }
    
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct MostViewed: Codable {
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    struct Item: Codable {
        struct ID: Codable {
            let kind: String?
            let videoID: String
            
            private enum CodingKeys: String, CodingKey {
                case kind
                case videoID = "videoId"
            }
        }
        
        struct Snippet: Codable {
            struct Thumbnail: Codable {
                struct Default: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct Medium: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                struct High: Codable {
                    let url: URL
                    let width: Int
                    let height: Int
                }
                
                let `default`: Default
                let medium: Medium
                let high: High
            }
            
            let publishedAt: String?
            let channelID: String
            let title: String
            let description: String
            let thumbnails: Thumbnail
            let channelTitle: String
            let liveBroadcastContent: String
            let publishTime: String?
            
            private enum CodingKeys: String, CodingKey {
                case publishedAt
                case channelID = "channelId"
                case title
                case description
                case thumbnails
                case channelTitle
                case liveBroadcastContent
                case publishTime
            }
        }
        
        let kind: String?
        let etag: String?
        let id: ID
        let snippet: Snippet
    }
    
    let kind: String?
    let etag: String?
    let nextPageToken: String?
    let regionCode: String?
    let pageInfo: PageInfo?
    let items: [Item]?
}

struct YoutubeVideoDetails: Codable {
    struct Item: Codable {
        struct ContentDetail: Codable {
            struct ContentRating: Codable {
            }
            
            let duration: String
            let dimension: String
            let definition: String
            let caption: String
            let licensedContent: Bool
            let contentRating: ContentRating
            let projection: String
        }
        
        let kind: String?
        let etag: String?
        let id: String?
        let contentDetails: ContentDetail
    }
    
    struct PageInfo: Codable {
        let totalResults: Int?
        let resultsPerPage: Int?
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct YoutubeVideoStats: Codable {
    struct Item: Codable {
        struct Statistic: Codable {
            let viewCount: String?
            let likeCount: String?
            let dislikeCount: String?
            let favoriteCount: String?
            let commentCount: String?
        }
        
        let kind: String?
        let etag: String?
        let id: String
        let statistics: Statistic
    }
    
    struct PageInfo: Codable {
        let totalResults: Int
        let resultsPerPage: Int
    }
    
    let kind: String?
    let etag: String?
    let items: [Item]?
    let nextPageToken: String?
    let pageInfo: PageInfo?
}

struct YouTubeVideoData: Codable {
    struct Channel: Codable {
        struct Subscriber: Codable {
            let pretty: String?
        }
        
        struct Icon: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let subscribers: Subscriber?
        let icons: [Icon]?
    }
    
    struct Duration: Codable {
        let lengthSec: String?
    }
    
    struct Thumbnail: Codable {
        let url: URL?
        let width: Int?
        let height: Int?
    }
    
    struct Rating: Codable {
        struct Like: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Dislike: Codable {
            let text: String?
            let pretty: String?
        }
        
        let likes: Like?
        let dislikes: Dislike?
    }
    
    struct View: Codable {
        let text: String?
        let pretty: String?
    }
    
    struct Published: Codable {
        let pretty: String?
        let text: String?
    }
    
    struct Uploaded: Codable {
        let text: String?
    }
    
    struct Embed: Codable {
        let iframeURL: URL?
        let flashURL: URL?
        let width: Int?
        let height: Int?
        let flashSecureURL: URL?
        
        private enum CodingKeys: String, CodingKey {
            case iframeURL = "iframeUrl"
            case flashURL = "flashUrl"
            case width
            case height
            case flashSecureURL = "flashSecureUrl"
        }
    }
    
    struct Stream: Codable {
        struct Format: Codable {
            let itag: Int?
            let url: URL?
            let mimeType: String?
            let bitrate: Int?
            let width: Int?
            let height: Int?
            let lastModified: String?
            let contentLength: String?
            let quality: String?
            let fps: Int?
            let qualityLabel: String?
            let projectionType: String?
            let averageBitrate: Int?
            let audioQuality: String?
            let approxDurationMs: String?
            let audioSampleRate: String?
            let audioChannels: Int?
        }
        
        struct AdaptiveFormat: Codable {
            struct InitRange: Codable {
                let start: String?
                let end: String?
            }
            
            struct IndexRange: Codable {
                let start: String?
                let end: String?
            }
            
            struct ColorInfo: Codable {
                let primaries: String?
                let transferCharacteristics: String?
                let matrixCoefficients: String?
            }
            
            let itag: Int?
            let url: URL?
            let mimeType: String?
            let bitrate: Int?
            let width: Int?
            let height: Int?
            let initRange: InitRange?
            let indexRange: IndexRange?
            let lastModified: String?
            let contentLength: String?
            let quality: String?
            let fps: Int?
            let qualityLabel: String?
            let projectionType: String?
            let averageBitrate: Int?
            let approxDurationMs: String?
            let colorInfo: ColorInfo?
            let highReplication: Bool?
            let audioQuality: String?
            let audioSampleRate: String?
            let audioChannels: Int?
            let loudnessDb: Double?
        }
        
        struct Player: Codable {
            let url: URL?
        }
        
        let expiresInSeconds: String?
        let formats: [Format]?
        let adaptiveFormats: [AdaptiveFormat]?
        let player: Player?
    }
    
    let title: String?
    let id: String?
    let url: URL?
    let shortDescription: String?
    let description: String?
    let channel: Channel?
    let duration: Duration?
    let thumbnails: [Thumbnail]?
    let ratings: Rating?
    let views: View?
    let published: Published?
    let uploaded: Uploaded?
    let keywords: [String]?
    let isLive: Bool?
    let isUnlisted: Bool?
    let isFamilySafe: Bool?
    let category: String?
    let embed: Embed?
    let streams: Stream?
}


extension YouTubeVideoData {
    init?(playerResponse response: [String: Any], fallbackVideoID: String) {
        guard let details = response["videoDetails"] as? [String: Any] else { return nil }
        let id = (details["videoId"] as? String) ?? fallbackVideoID
        guard !id.isEmpty else { return nil }

        let title = details["title"] as? String
        let description = details["shortDescription"] as? String
        let author = details["author"] as? String
        let channelID = details["channelId"] as? String
        let length = details["lengthSeconds"] as? String
        let viewCount = details["viewCount"] as? String
        let keywords = details["keywords"] as? [String]
        let isLive = details["isLiveContent"] as? Bool

        let thumbObjects = ((details["thumbnail"] as? [String: Any])?["thumbnails"] as? [[String: Any]] ?? [])
        let thumbnails: [Thumbnail] = thumbObjects.compactMap { raw in
            guard let urlString = raw["url"] as? String else { return nil }
            return .init(url: URL(string: urlString), width: raw["width"] as? Int, height: raw["height"] as? Int)
        }

        let microformat = (response["microformat"] as? [String: Any])?["playerMicroformatRenderer"] as? [String: Any]
        let uploadDate = (microformat?["uploadDate"] as? String) ?? (microformat?["publishDate"] as? String)
        let category = microformat?["category"] as? String
        let familySafe = microformat?["isFamilySafe"] as? Bool
        let unlisted = microformat?["isUnlisted"] as? Bool

        let prettyDate: String? = {
            guard let uploadDate else { return nil }
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = "yyyy-MM-dd"
            guard let date = parser.date(from: uploadDate) else { return uploadDate }
            let output = DateFormatter()
            output.dateStyle = .medium
            output.timeStyle = .none
            return output.string(from: date)
        }()

        self.init(
            title: title,
            id: id,
            url: URL(string: "https://www.youtube.com/watch?v=\(id)"),
            shortDescription: description,
            description: description,
            channel: .init(name: author, id: channelID, url: channelID.flatMap { URL(string: "https://www.youtube.com/channel/\($0)") }, subscribers: nil, icons: nil),
            duration: .init(lengthSec: length),
            thumbnails: thumbnails.isEmpty ? nil : thumbnails,
            ratings: nil,
            views: .init(text: viewCount, pretty: viewCount),
            published: .init(pretty: prettyDate, text: prettyDate),
            uploaded: .init(text: prettyDate),
            keywords: keywords,
            isLive: isLive,
            isUnlisted: unlisted,
            isFamilySafe: familySafe,
            category: category,
            embed: nil,
            streams: nil
        )
    }

    init?(videoRenderer r: [String: Any]) {
        guard let id = r["videoId"] as? String else { return nil }
        let title = oldOSText(r["title"])
        let channel = oldOSText(r["ownerText"]) ?? oldOSText(r["longBylineText"])
        let viewsPretty = oldOSText(r["viewCountText"]) ?? oldOSText(r["shortViewCountText"])
        let published = oldOSText(r["publishedTimeText"])
        let durationText = oldOSText(r["lengthText"])
        let seconds = oldOSDurationSeconds(durationText)
        var thumb: URL?
        if let t = r["thumbnail"] as? [String: Any], let arr = t["thumbnails"] as? [[String: Any]] {
            thumb = arr.last.flatMap { ($0["url"] as? String).flatMap(URL.init(string:)) }
        }
        self.init(
            title: title,
            id: id,
            url: URL(string: "https://www.youtube.com/watch?v=\(id)"),
            shortDescription: nil,
            description: nil,
            channel: .init(name: channel, id: nil, url: nil, subscribers: nil, icons: nil),
            duration: .init(lengthSec: seconds.map(String.init)),
            thumbnails: thumb.map { [.init(url: $0, width: nil, height: nil)] },
            ratings: nil,
            views: .init(text: oldOSNumericText(viewsPretty), pretty: viewsPretty),
            published: .init(pretty: published, text: published),
            uploaded: .init(text: published),
            keywords: nil,
            isLive: nil,
            isUnlisted: nil,
            isFamilySafe: nil,
            category: nil,
            embed: nil,
            streams: nil
        )
    }
}

struct YoutubeVideoSearchData: Codable {
    struct Videos: Codable {
        struct Channel: Codable {
            let name: String?
            let id: String?
            let url: URL?
        }
        
        struct Duration: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Published: Codable {
            let pretty: String?
        }
        
        struct Views: Codable {
            let text: String?
            let pretty: String?
            let prettyLong: String?
        }
        
        struct Thumbnails: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let title: String?
        let id: String?
        let url: URL?
        let channel: Channel?
        let duration: Duration?
        let published: Published?
        let views: Views?
        let thumbnails: [Thumbnails]?
    }
    
    struct Channels: Codable {
        struct Subscribers: Codable {
            let text: String?
            let pretty: String?
        }
        
        struct Icons: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let subscribers: Subscribers?
        let videoCount: String?
        let icons: [Icons]?
    }
    
    struct Playlists: Codable {
        struct Thumbnails: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        struct Published: Codable {
        }
        
        let name: String?
        let id: String?
        let url: URL?
        let thumbnails: [Thumbnails]?
        let videoCount: String?
        let published: Published?
    }
    
    let videos: [Videos]?
    let channels: [Channels]?
    let playlists: [Playlists]?
}

struct YoutubeVideoComments: Codable {
    struct Comments: Codable {
        struct AuthorThumb: Codable {
            let url: URL?
            let width: Int?
            let height: Int?
        }
        
        let authorThumb: [AuthorThumb]?
        let author: String?
        let authorID: String?
        let commentID: String
        let text: String?
        let likes: String?
        let numReplies: Int?
        let isOwner: Bool?
        let isHearted: Bool?
        let isPinned: Bool?
        let hasOwnerReplied: Bool?
        let time: String?
        let edited: Bool?
        let replyToken: String?
        let isVerified: Bool?
        let isOfficialArtist: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case authorThumb
            case author
            case authorID = "authorId"
            case commentID = "commentId"
            case text
            case likes
            case numReplies
            case isOwner
            case isHearted
            case isPinned
            case hasOwnerReplied
            case time
            case edited
            case replyToken
            case isVerified
            case isOfficialArtist
        }
    }
    
    let comments: [Comments]
    let continuation: String?
}


struct BlankButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(Color.white)
    }
}





