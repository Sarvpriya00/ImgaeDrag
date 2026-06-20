import SwiftUI
import UniformTypeIdentifiers

struct MainDropView: View {
    @ObservedObject var sessionManager: SessionManager
    
    @AppStorage("youtubeVideoQuality") private var globalQuality = "1080p"
    @AppStorage("youtubeExtractAudio") private var globalExtractAudio = false
    
    @State private var inputURL = ""
    @State private var isDraggingOver = false
    @State private var showInactiveAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var localQuality = "1080p"
    @State private var localExtractAudio = false
    
    // Vibrant yellow accent color
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(sessionManager.isSessionActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                            .shadow(color: sessionManager.isSessionActive ? Color.green : Color.clear, radius: 4)
                        
                        Text("DropSession")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if sessionManager.isSessionActive, let folder = sessionManager.currentSessionFolder {
                        Button(action: {
                            NSWorkspace.shared.open(folder)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                Text("Open Folder")
                            }
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentYellow)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                    
                    // Open Standalone Main App Window
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("openMainAppWindow"), object: nil)
                    }) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Open Dashboard")
                    
                    // Close dropdown panel
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("closeMenuBarPanel"), object: nil)
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Close Panel")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                // Session Status Card
                VStack(spacing: 8) {
                    if sessionManager.isSessionActive {
                        Text("ACTIVE SESSION")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(accentYellow)
                            .tracking(1.5)
                        
                        Text(sessionManager.currentSessionName)
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    } else {
                        Text("NO ACTIVE SESSION")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.gray)
                            .tracking(1.5)
                        
                        Text("Media staging is paused")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.03))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Drag-and-Drop Staging Shelf
                ZStack {
                    if sessionManager.isSessionActive {
                        // Staging Shelf Active
                        VStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(isDraggingOver ? accentYellow : .white.opacity(0.6))
                                .offset(y: isDraggingOver ? -5 : 0)
                                .animation(.easeInOut(duration: 0.2), value: isDraggingOver)
                            
                            Text("Drag & drop images here")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Accepts drag files and web URLs")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    isDraggingOver ? accentYellow : Color.white.opacity(0.12),
                                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4])
                                )
                                .background(isDraggingOver ? accentYellow.opacity(0.03) : Color.clear)
                        )
                    } else {
                        // Staging Shelf Inactive
                        VStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Drop Shelf Locked")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Start a session to enable downloads")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    Color.white.opacity(0.06),
                                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4])
                                )
                        )
                    }
                }
                .contentShape(Rectangle())
                .onDrop(of: [.url, .fileURL, .image, .text], isTargeted: $isDraggingOver) { providers in
                    if sessionManager.isSessionActive {
                        handleDroppedProviders(providers)
                        return true
                    } else {
                        showInactiveAlert = true
                        return false
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Link Input & One-Time Settings Override Card
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("Paste YouTube or media link...", text: $inputURL)
                            .font(.system(size: 12))
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isTextFieldFocused ? accentYellow : Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .focused($isTextFieldFocused)
                        
                        Button(action: handlePasteDownload) {
                            Text("Download")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(inputURL.isEmpty ? Color.white.opacity(0.12) : accentYellow)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .disabled(inputURL.isEmpty)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Text("One-Time Quality:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Picker("", selection: $localQuality) {
                                Text("4K Ultra HD").tag("4K")
                                Text("Full HD (1080p)").tag("1080p")
                                Text("HD (720p)").tag("720p")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 140)
                            .labelsHidden()
                        }
                        
                        Spacer()
                        
                        Toggle(isOn: $localExtractAudio) {
                            Text("Audio Only")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .toggleStyle(SwitchToggleStyle(tint: accentYellow))
                        .scaleEffect(0.8)
                    }
                    .padding(.horizontal, 4)
                }
                .padding(12)
                .background(Color.white.opacity(0.02))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Active Downloads List (Shared State)
                if !sessionManager.downloads.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Downloads Log")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Button("Clear") {
                                sessionManager.downloads.removeAll()
                            }
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(sessionManager.downloads) { item in
                                    HStack(spacing: 12) {
                                        Image(systemName: item.isVideo ? "video.fill" : "photo.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(item.status.contains("Failed") ? .red : accentYellow)
                                            .frame(width: 24, height: 24)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(6)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            
                                            Text(item.status)
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        if item.progress < 1.0 && !item.status.contains("Failed") {
                                            ProgressView(value: item.progress, total: 1.0)
                                                .progressViewStyle(.linear)
                                                .frame(width: 60)
                                                .tint(accentYellow)
                                        } else if item.status.contains("Failed") {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .foregroundColor(.red)
                                        } else {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.02))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 16)
                } else {
                    Spacer()
                }
                
                // Session Toggle Button Footer
                VStack {
                    Button(action: {
                        if sessionManager.isSessionActive {
                            sessionManager.stopSession()
                        } else {
                            sessionManager.startSession()
                        }
                    }) {
                        Text(sessionManager.isSessionActive ? "Stop Download Session" : "Start Download Session")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(sessionManager.isSessionActive ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(sessionManager.isSessionActive ? Color.white.opacity(0.08) : accentYellow)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(sessionManager.isSessionActive ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color.black.opacity(0.15))
            }
        }
        .preferredColorScheme(.dark)
        .cornerRadius(16) // Round the corners of the borderless panel window
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .alert("Staging Shelf Inactive", isPresented: $showInactiveAlert) {
            Button("Start Session") {
                sessionManager.startSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please start an active session from the menu bar or bottom control to drop files.")
        }
        .onAppear {
            localQuality = globalQuality
            localExtractAudio = globalExtractAudio
        }
        .onChange(of: globalQuality) { oldValue, newValue in
            localQuality = newValue
        }
        .onChange(of: globalExtractAudio) { oldValue, newValue in
            localExtractAudio = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveDroppedProviders)) { notification in
            if let providers = notification.object as? [NSItemProvider] {
                self.handleDroppedProviders(providers)
            }
        }
    }
    
    // MARK: - Drag and Drop Handlers
    private func handleDroppedProviders(_ providers: [NSItemProvider]) {
        guard let destFolder = sessionManager.currentSessionFolder else { return }
        
        // Capture one-time overrides before resetting
        let targetQuality = localQuality
        let targetExtractAudio = localExtractAudio
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        self.copyLocalFile(url, to: destFolder)
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Dragged raw image data (e.g. from Chrome web browser)
                let typeId = provider.registeredTypeIdentifiers.first { UTType($0)?.conforms(to: .image) == true } ?? UTType.image.identifier
                let utType = UTType(typeId) ?? .image
                let ext = utType.preferredFilenameExtension ?? "png"
                
                provider.loadDataRepresentation(forTypeIdentifier: typeId) { data, error in
                    guard let data = data else { return }
                    DispatchQueue.main.async {
                        self.saveDraggedImageData(data, extension: ext, to: destFolder)
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    guard let url = url else { return }
                    DispatchQueue.main.async {
                        self.processURL(url.absoluteString, to: destFolder, quality: targetQuality, extractAudio: targetExtractAudio)
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                _ = provider.loadObject(ofClass: String.self) { text, error in
                    guard let text = text else { return }
                    DispatchQueue.main.async {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let url = URL(string: trimmed), url.scheme != nil {
                            self.processURL(url.absoluteString, to: destFolder, quality: targetQuality, extractAudio: targetExtractAudio)
                        }
                    }
                }
            }
        }
        
        // Reset overrides to global defaults for "one time use"
        localQuality = globalQuality
        localExtractAudio = globalExtractAudio
    }
    
    private func copyLocalFile(_ srcUrl: URL, to destFolder: URL) {
        let nameWithoutExt = srcUrl.deletingPathExtension().lastPathComponent
        let ext = srcUrl.pathExtension
        
        let newItem = DownloadItem(name: srcUrl.lastPathComponent, progress: 0.0, status: "Copying...", isVideo: false)
        sessionManager.downloads.append(newItem)
        let itemId = newItem.id
        
        do {
            var destUrl = destFolder.appendingPathComponent(srcUrl.lastPathComponent)
            var counter = 1
            while FileManager.default.fileExists(atPath: destUrl.path) {
                destUrl = destFolder.appendingPathComponent("\(nameWithoutExt)_\(counter).\(ext)")
                counter += 1
            }
            
            try FileManager.default.copyItem(at: srcUrl, to: destUrl)
            
            DispatchQueue.main.async {
                if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                    self.sessionManager.downloads[index].progress = 1.0
                    self.sessionManager.downloads[index].status = "Copied"
                }
            }
        } catch {
            DispatchQueue.main.async {
                if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                    self.sessionManager.downloads[index].status = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func saveDraggedImageData(_ data: Data, extension ext: String, to destFolder: URL) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let name = "dragged_image_\(timestamp)"
        
        let newItem = DownloadItem(name: "\(name).\(ext)", progress: 0.0, status: "Saving image...", isVideo: false)
        sessionManager.downloads.append(newItem)
        let itemId = newItem.id
        
        do {
            let destUrl = destFolder.appendingPathComponent("\(name).\(ext)")
            try data.write(to: destUrl)
            
            DispatchQueue.main.async {
                if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                    self.sessionManager.downloads[index].progress = 1.0
                    self.sessionManager.downloads[index].status = "Saved"
                }
            }
        } catch {
            DispatchQueue.main.async {
                if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                    self.sessionManager.downloads[index].status = "Failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func handlePasteDownload() {
        guard sessionManager.isSessionActive, let destFolder = sessionManager.currentSessionFolder else {
            showInactiveAlert = true
            return
        }
        
        let urlStr = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        inputURL = ""
        isTextFieldFocused = false
        
        // Capture one-time overrides before resetting
        let targetQuality = localQuality
        let targetExtractAudio = localExtractAudio
        
        processURL(urlStr, to: destFolder, quality: targetQuality, extractAudio: targetExtractAudio)
        
        // Reset overrides to global defaults for "one time use"
        localQuality = globalQuality
        localExtractAudio = globalExtractAudio
    }
    
    private func processURL(_ urlString: String, to destFolder: URL, quality: String? = nil, extractAudio: Bool? = nil) {
        let isYoutube = urlString.contains("youtube.com") || urlString.contains("youtu.be")
        let parsedURL = URL(string: urlString)
        let name = isYoutube ? "YouTube Video" : (parsedURL?.lastPathComponent.isEmpty == false ? parsedURL!.lastPathComponent : "Web Image")
        
        let newItem = DownloadItem(name: name, progress: 0.0, status: "Pending", isVideo: isYoutube)
        sessionManager.downloads.append(newItem)
        let itemId = newItem.id
        
        Task {
            do {
                if isYoutube {
                    try await YTDLPService.shared.download(
                        url: urlString,
                        destinationFolder: destFolder,
                        qualityOverride: quality,
                        extractAudioOverride: extractAudio
                    ) { percent, msg in
                        DispatchQueue.main.async {
                            if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                                self.sessionManager.downloads[index].progress = percent / 100.0
                                self.sessionManager.downloads[index].status = msg
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                            self.sessionManager.downloads[index].progress = 1.0
                            self.sessionManager.downloads[index].status = "Completed"
                        }
                    }
                } else {
                    guard let url = parsedURL else {
                        throw NSError(domain: "URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Malformed URL"])
                    }
                    
                    DispatchQueue.main.async {
                        if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                            self.sessionManager.downloads[index].status = "Connecting..."
                        }
                    }
                    
                    let (data, response) = try await URLSession.shared.data(from: url)
                    let mimeType = response.mimeType
                    
                    let ext = getExtension(fromUrl: url, mimeType: mimeType)
                    let timestamp = Int(Date().timeIntervalSince1970)
                    let filename = "media_\(timestamp).\(ext)"
                    let destUrl = destFolder.appendingPathComponent(filename)
                    
                    try data.write(to: destUrl)
                    
                    DispatchQueue.main.async {
                        if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                            self.sessionManager.downloads[index].progress = 1.0
                            self.sessionManager.downloads[index].status = "Downloaded"
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let index = self.sessionManager.downloads.firstIndex(where: { $0.id == itemId }) {
                        self.sessionManager.downloads[index].status = "Failed: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func getExtension(fromUrl url: URL, mimeType: String?) -> String {
        if let mime = mimeType {
            if mime.contains("jpeg") || mime.contains("jpg") { return "jpg" }
            if mime.contains("png") { return "png" }
            if mime.contains("gif") { return "gif" }
            if mime.contains("webp") { return "webp" }
            if mime.contains("svg") { return "svg" }
        }
        
        let ext = url.pathExtension.lowercased()
        if ["png", "jpg", "jpeg", "gif", "webp", "svg"].contains(ext) {
            return ext == "jpeg" ? "jpg" : ext
        }
        
        return "jpg"
    }
}
