import Foundation

/// Manages conversation history between user and assistant
public actor Transcript {
    /// All entries in the transcript
    private(set) public var entries: [TranscriptEntry] = []
    
    /// Maximum number of tokens allowed
    public let maxTokens: Int
    
    /// Current approximate token count
    private var currentTokenCount: Int = 0
    
    /// Initialize a transcript
    /// - Parameter maxTokens: Maximum tokens allowed (default: 4096)
    public init(maxTokens: Int = 4096) {
        self.maxTokens = maxTokens
    }
    
    /// Add an entry to the transcript
    /// - Parameter entry: The entry to add
    public func add(_ entry: TranscriptEntry) {
        entries.append(entry)
        updateTokenCount(for: entry)
        
        // Compact if needed
        if currentTokenCount > maxTokens {
            Task {
                await compactIfNeeded()
            }
        }
    }
    
    /// Add multiple entries
    /// - Parameter entries: The entries to add
    public func addAll(_ entries: [TranscriptEntry]) {
        for entry in entries {
            add(entry)
        }
    }
    
    /// Clear all entries
    public func clear() {
        entries.removeAll()
        currentTokenCount = 0
    }
    
    /// Get entries filtered by role
    /// - Parameter role: The role to filter by
    /// - Returns: Filtered entries
    public func entries(for role: TranscriptEntry.Role) -> [TranscriptEntry] {
        entries.filter { $0.role == role }
    }
    
    /// Get the last N entries
    /// - Parameter count: Number of entries to retrieve
    /// - Returns: The last N entries
    public func lastEntries(_ count: Int) -> [TranscriptEntry] {
        Array(entries.suffix(count))
    }
    
    /// Compact the transcript if it exceeds token limits
    public func compactIfNeeded() async {
        guard currentTokenCount > maxTokens else { return }
        
        // Simple strategy: keep system messages and recent history
        let systemEntries = entries.filter { $0.role == .system }
        let recentCount = min(10, entries.count / 2)
        let recentEntries = Array(entries.suffix(recentCount))
        
        // Create summary entry for removed content
        let removedCount = entries.count - systemEntries.count - recentCount
        if removedCount > 0 {
            let summaryEntry = TranscriptEntry(
                role: .system,
                content: "[Previous \(removedCount) messages were summarized to fit context window]"
            )
            
            entries = systemEntries + [summaryEntry] + recentEntries
            recalculateTokenCount()
        }
    }
    
    /// Export transcript as formatted text
    /// - Returns: Formatted transcript text
    public func exportAsText() -> String {
        entries.map { entry in
            let role = entry.role.rawValue.capitalized
            let content = entry.content ?? entry.toolCall?.name ?? entry.toolOutput?.content ?? ""
            return "\(role): \(content)"
        }.joined(separator: "\n\n")
    }
    
    // MARK: - Private
    
    private func updateTokenCount(for entry: TranscriptEntry) {
        // Approximate token counting (4 characters per token)
        let text = entry.content ?? entry.toolCall?.arguments ?? entry.toolOutput?.content ?? ""
        currentTokenCount += (text.count + 3) / 4
    }
    
    private func recalculateTokenCount() {
        currentTokenCount = 0
        for entry in entries {
            updateTokenCount(for: entry)
        }
    }
}