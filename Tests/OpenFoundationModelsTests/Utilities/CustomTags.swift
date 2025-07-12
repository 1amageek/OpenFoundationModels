import Testing

/// Custom tags for test categorization and filtering
/// 
/// These tags enable selective test execution and organization:
/// - Feature-specific tags for core functionality
/// - Layer-specific tags for architectural components
/// - Test type tags for different testing approaches
///
/// **Usage:**
/// ```swift
/// @Suite("Test Suite", .tags(.generable, .core))
/// struct MyTests { }
/// 
/// @Test("Individual test", .tags(.streaming))
/// func myTest() { }
/// ```
///
/// **Filtering:**
/// ```bash
/// swift test --filter tag:generable  # Run only Generable tests
/// swift test --filter tag:core       # Run only core component tests
/// ```
extension Tag {
    // MARK: - Feature-specific tags
    
    /// 🎯 Highest priority - Core Generable functionality
    /// Tests for @Generable macro, guided generation, constraints
    @Tag static var generable: Self
    
    /// @Guide constraint macro testing
    /// Pattern, range, enumeration constraints
    @Tag static var guide: Self
    
    /// Schema generation and validation
    /// GenerationSchema creation and accuracy
    @Tag static var schema: Self
    
    /// Constraint validation and enforcement
    /// Runtime constraint checking
    @Tag static var constraints: Self
    
    // MARK: - Layer-specific tags
    
    /// Core system components
    /// SystemLanguageModel, LanguageModelSession
    @Tag static var core: Self
    
    /// Foundation components
    /// Instructions, Prompt, Transcript, etc.
    @Tag static var foundation: Self
    
    /// Tool functionality
    /// Tool protocol, calling, integration
    @Tag static var tools: Self
    
    /// Error handling
    /// GenerationError, error contexts
    @Tag static var errors: Self
    
    // MARK: - Test type tags
    
    /// Macro expansion and generation
    /// @Generable, @Guide macro testing
    @Tag static var macros: Self
    
    /// End-to-end integration testing
    /// Complete workflows and interactions
    @Tag static var integration: Self
    
    /// Streaming functionality
    /// ResponseStream, partial updates
    @Tag static var streaming: Self
    
    /// Performance and scalability
    /// Load testing, resource usage
    @Tag static var performance: Self
    
    /// Unit testing
    /// Individual component testing
    @Tag static var unit: Self
}