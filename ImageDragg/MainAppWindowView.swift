import SwiftUI

struct MainAppWindowView: View {
    @ObservedObject var sessionManager: SessionManager
    @State var selectedTab: String = "dashboard" // "dashboard" or "settings"
    
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar / Navigation
                VStack(spacing: 12) {
                    // Logo/App Info
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentYellow)
                        
                        Text("DropSession")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 24)
                    
                    // Navigation Options
                    SidebarButton(title: "Dashboard", icon: "square.grid.2x2.fill", isActive: selectedTab == "dashboard") {
                        selectedTab = "dashboard"
                    }
                    
                    SidebarButton(title: "Settings", icon: "gearshape.fill", isActive: selectedTab == "settings") {
                        selectedTab = "settings"
                    }
                    
                    Spacer()
                    
                    // Session Status Indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(sessionManager.isSessionActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                            .shadow(color: sessionManager.isSessionActive ? Color.green.opacity(0.5) : Color.clear, radius: 4)
                        
                        Text(sessionManager.isSessionActive ? "Active Session" : "Staging Paused")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 12)
                }
                .frame(width: 180)
                .padding(.top, 32)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.12))
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Content Canvas
                VStack(spacing: 0) {
                    if selectedTab == "dashboard" {
                        appDashboardView
                    } else if selectedTab == "settings" {
                        appSettingsView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
        }
        .frame(width: 750, height: 500)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Dashboard Tab
    private var appDashboardView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Manage active sessions and view download history.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Status Card
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(sessionManager.isSessionActive ? "ACTIVE SESSION" : "PAUSED")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(sessionManager.isSessionActive ? accentYellow : .gray)
                        .tracking(1.5)
                    
                    Text(sessionManager.isSessionActive ? sessionManager.currentSessionName : "Media staging is paused")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    if sessionManager.isSessionActive, let folder = sessionManager.currentSessionFolder {
                        Text(folder.path)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 10) {
                    if sessionManager.isSessionActive, let folder = sessionManager.currentSessionFolder {
                        Button(action: {
                            NSWorkspace.shared.open(folder)
                        }) {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.white.opacity(0.8))
                                .padding(10)
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button(action: {
                        if sessionManager.isSessionActive {
                            sessionManager.stopSession()
                        } else {
                            sessionManager.startSession()
                        }
                    }) {
                        Text(sessionManager.isSessionActive ? "Stop Session" : "Start Session")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(sessionManager.isSessionActive ? .white : .black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(sessionManager.isSessionActive ? Color.white.opacity(0.08) : accentYellow)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(sessionManager.isSessionActive ? Color.white.opacity(0.12) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            
            // Download List Header
            HStack {
                Text("Downloads History")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !sessionManager.downloads.isEmpty {
                    Button("Clear History") {
                        sessionManager.downloads.removeAll()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))
                    .buttonStyle(.plain)
                }
            }
            
            // Downloads Scroll View
            if sessionManager.downloads.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(.white.opacity(0.15))
                    
                    Text("No downloads in this session")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.01))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
            } else {
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
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text(item.status)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.4))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if item.progress < 1.0 && !item.status.contains("Failed") {
                                    ProgressView(value: item.progress, total: 1.0)
                                        .progressViewStyle(.linear)
                                        .frame(width: 120)
                                        .tint(accentYellow)
                                } else if item.status.contains("Failed") {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Settings Tab (General + YouTube Settings)
    @AppStorage("youtubeVideoQuality") private var youtubeVideoQuality = "1080p"
    @AppStorage("youtubeExtractAudio") private var youtubeExtractAudio = false
    
    private var appSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Configure your storage directory and video downloader defaults.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                // Section 1: Storage
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage Path")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text(sessionManager.masterDirectoryPath)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        
                        Button(action: selectFolder) {
                            Text("Browse...")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(accentYellow)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.08))
                
                // Section 2: yt-dlp Video settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("YouTube Downloader Configuration")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Video Quality Limit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Picker("", selection: $youtubeVideoQuality) {
                                Text("4K Ultra HD (2160p)").tag("4K")
                                Text("Full HD (1080p)").tag("1080p")
                                Text("HD (720p)").tag("720p")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 200)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.05))
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Extract Audio Only")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Save downloads as high quality MP3 audio tracks.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $youtubeExtractAudio)
                                .toggleStyle(SwitchToggleStyle(tint: accentYellow))
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Choose master directory for DropSession storage"
        openPanel.prompt = "Select"
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                sessionManager.setMasterDirectory(url: url)
            }
        }
    }
}

struct SidebarButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    private let accentYellow = Color(red: 1.0, green: 0.84, blue: 0.0) // #FFD700
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .foregroundColor(isActive ? .black : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isActive ? accentYellow : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
