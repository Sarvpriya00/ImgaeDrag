import SwiftUI
import Combine

struct DownloadItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    var progress: Double // 0.0 to 1.0
    var status: String
    var isVideo: Bool
    
    init(id: UUID = UUID(), name: String, progress: Double, status: String, isVideo: Bool) {
        self.id = id
        self.name = name
        self.progress = progress
        self.status = status
        self.isVideo = isVideo
    }
}

@MainActor
class SessionManager: ObservableObject {
    @Published var isSessionActive = false
    @Published var currentSessionFolder: URL?
    @Published var currentSessionName: String = ""
    @Published var masterDirectoryPath: String = ""
    @Published var downloads: [DownloadItem] = []
    
    init() {
        loadMasterDirectory()
    }
    
    /// Loads the saved master default directory path or fallback to Downloads folder.
    func loadMasterDirectory() {
        if let bookmarkData = UserDefaults.standard.data(forKey: "MasterDirectoryBookmark") {
            var isStale = false
            do {
                // First try resolving security-scoped bookmark
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if url.startAccessingSecurityScopedResource() {
                    masterDirectoryPath = url.path
                    url.stopAccessingSecurityScopedResource()
                } else {
                    masterDirectoryPath = url.path
                }
            } catch {
                // Fallback to resolving standard bookmark
                do {
                    let url = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                    masterDirectoryPath = url.path
                } catch {
                    useFallbackDirectory()
                }
            }
        } else {
            useFallbackDirectory()
        }
    }
    
    private func useFallbackDirectory() {
        if let savedPath = UserDefaults.standard.string(forKey: "MasterDirectoryPath"),
           FileManager.default.fileExists(atPath: savedPath) {
            masterDirectoryPath = savedPath
        } else if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            masterDirectoryPath = downloads.path
        } else {
            masterDirectoryPath = NSHomeDirectory()
        }
    }
    
    /// Saves the selected directory URL as a security-scoped bookmark.
    func setMasterDirectory(url: URL) {
        do {
            // Request permission to write security-scoped bookmark data
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: "MasterDirectoryBookmark")
        } catch {
            // Fallback to standard bookmark if security scope fails (e.g. Sandbox is disabled)
            do {
                let bookmarkData = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(bookmarkData, forKey: "MasterDirectoryBookmark")
            } catch {
                print("[SessionManager] Failed to create bookmark: \(error)")
            }
        }
        
        UserDefaults.standard.set(url.path, forKey: "MasterDirectoryPath")
        masterDirectoryPath = url.path
    }
    
    /// Starts a new session by creating a timestamped folder in the master directory.
    func startSession() {
        guard !isSessionActive else { return }
        
        var masterURL: URL
        var accessedSecurityScoped = false
        
        if let bookmarkData = UserDefaults.standard.data(forKey: "MasterDirectoryBookmark") {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                accessedSecurityScoped = resolvedURL.startAccessingSecurityScopedResource()
                masterURL = resolvedURL
            } catch {
                do {
                    let resolvedURL = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: [],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )
                    masterURL = resolvedURL
                } catch {
                    masterURL = URL(fileURLWithPath: masterDirectoryPath)
                }
            }
        } else {
            masterURL = URL(fileURLWithPath: masterDirectoryPath)
        }
        
        defer {
            if accessedSecurityScoped {
                masterURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Format: dd-HH-mm
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-HH-mm"
        let sessionName = formatter.string(from: Date())
        let sessionFolder = masterURL.appendingPathComponent(sessionName)
        
        do {
            try FileManager.default.createDirectory(at: sessionFolder, withIntermediateDirectories: true, attributes: nil)
            self.currentSessionFolder = sessionFolder
            self.currentSessionName = sessionName
            self.isSessionActive = true
            print("[SessionManager] Started active session: \(sessionName)")
        } catch {
            print("[SessionManager] Failed to create session directory: \(error)")
        }
    }
    
    /// Stops the current active session.
    func stopSession() {
        guard isSessionActive else { return }
        self.isSessionActive = false
        self.currentSessionFolder = nil
        self.currentSessionName = ""
        print("[SessionManager] Session stopped.")
    }
}
