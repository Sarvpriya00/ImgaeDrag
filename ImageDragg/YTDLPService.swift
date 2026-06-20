import Foundation

class YTDLPService {
    static let shared = YTDLPService()
    
    private init() {}
    
    /// Finds the path of yt-dlp executable on the system.
    private func locateYTDLP() -> String? {
        let paths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp",
            "/bin/yt-dlp"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    /// Finds the directory containing the ffmpeg binary to enable video merging.
    private func locateFFmpegDirectory() -> String? {
        let paths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg",
            "/bin/ffmpeg"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path).deletingLastPathComponent().path
            }
        }
        
        return nil
    }
    
    /// Downloads a media file from a URL to the designated folder.
    /// - Parameters:
    ///   - url: The media URL to download.
    ///   - destinationFolder: The target URL folder where the download will be saved.
    ///   - onProgress: Closure passing current download percentage (0 to 100) and status message.
    func download(
        url: String,
        destinationFolder: URL,
        qualityOverride: String? = nil,
        extractAudioOverride: Bool? = nil,
        onProgress: @escaping (Double, String) -> Void
    ) async throws {
        guard let executablePath = locateYTDLP() else {
            throw NSError(
                domain: "YTDLPService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "yt-dlp command not found. Please install it via Homebrew: `brew install yt-dlp`"]
            )
        }
        
        let quality = qualityOverride ?? (UserDefaults.standard.string(forKey: "youtubeVideoQuality") ?? "1080p")
        let extractAudio = extractAudioOverride ?? UserDefaults.standard.bool(forKey: "youtubeExtractAudio")
        
        var arguments = [String]()
        
        if extractAudio {
            arguments.append(contentsOf: ["-x", "--audio-format", "mp3"])
        } else {
            switch quality {
            case "4K":
                arguments.append(contentsOf: ["-f", "bestvideo[height<=2160]+bestaudio/best"])
            case "720p":
                arguments.append(contentsOf: ["-f", "bestvideo[height<=720]+bestaudio/best"])
            case "1080p":
                fallthrough
            default:
                arguments.append(contentsOf: ["-f", "bestvideo[height<=1080]+bestaudio/best"])
            }
        }
        
        if let ffmpegDir = locateFFmpegDirectory() {
            arguments.append(contentsOf: ["--ffmpeg-location", ffmpegDir])
        }
        
        // Output template. E.g., /path/to/folder/%(title)s.%(ext)s
        let outputTemplate = destinationFolder.appendingPathComponent("%(title)s.%(ext)s").path
        arguments.append(contentsOf: ["-o", outputTemplate, "--no-playlist", "--newline"])
        arguments.append(url)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            let state = DownloadState()
            
            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                if let line = String(data: data, encoding: .utf8) {
                    if let percent = Self.parseProgress(from: line) {
                        DispatchQueue.main.async {
                            onProgress(percent, "Downloading... \(Int(percent))%")
                        }
                    }
                }
            }
            
            process.terminationHandler = { proc in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                guard !state.checkAndMarkFinished() else { return }
                
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMessage = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let displayMessage = errMessage.isEmpty ? "Termination status code \(proc.terminationStatus)" : errMessage
                    
                    continuation.resume(
                        throwing: NSError(
                            domain: "YTDLPService",
                            code: Int(proc.terminationStatus),
                            userInfo: [NSLocalizedDescriptionKey: displayMessage]
                        )
                    )
                }
            }
            
            do {
                try process.run()
            } catch {
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                if !state.checkAndMarkFinished() {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Parses progress percentages from yt-dlp output format.
    nonisolated private static func parseProgress(from line: String) -> Double? {
        // Sample match: [download]  15.4% of  89.20MiB...
        let pattern = "\\[download\\]\\s+(\\d+(?:\\.\\d+)?)\\%"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
        if let match = regex.firstMatch(in: line, options: [], range: nsRange) {
            if match.numberOfRanges > 1 {
                let percentRange = match.range(at: 1)
                if let range = Range(percentRange, in: line) {
                    return Double(line[range])
                }
            }
        }
        
        return nil
    }
}

nonisolated private final class DownloadState: @unchecked Sendable {
    private let lock = NSLock()
    private var hasFinished = false
    
    nonisolated func checkAndMarkFinished() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if hasFinished {
            return true
        }
        hasFinished = true
        return false
    }
}
