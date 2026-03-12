/**
 * Smart Token Management System for Anvil
 * Handles conversation summarization and context preservation
 */

class TokenManager {
    constructor() {
        this.maxTokens = 200000; // Conservative limit
        this.reserveTokens = 50000; // Reserve for responses
        this.criticalSections = [
            'CLAUDE.md',
            'Learned',
            'Recent notes',
            'GitHub connection',
            'Tool usage patterns'
        ];
    }

    /**
     * Estimate token count (rough approximation: 1 token ≈ 4 characters)
     */
    estimateTokens(text) {
        return Math.ceil(text.length / 4);
    }

    /**
     * Extract critical information that must be preserved
     */
    extractCriticalContext(conversation) {
        const critical = {
            timestamp: new Date().toISOString(),
            tools_used: [],
            key_achievements: [],
            github_status: 'connected',
            file_operations: [],
            learning_insights: []
        };

        // Extract tool usage patterns
        const toolMatches = conversation.match(/<function_calls>[\s\S]*?<\/antml:function_calls>/g) || [];
        critical.tools_used = toolMatches.map(match => {
            const toolName = match.match(/<invoke name="([^"]+)">/);
            return toolName ? toolName[1] : 'unknown';
        });

        // Extract file operations
        const fileOps = conversation.match(/file_write.*?path.*?['"](.*?)['"].*?content/g) || [];
        critical.file_operations = fileOps.map(op => {
            const path = op.match(/['"](.*?)['"]/);
            return path ? path[1] : 'unknown';
        });

        // Extract learning insights (💡 markers)
        const insights = conversation.match(/💡.*$/gm) || [];
        critical.learning_insights = insights.slice(-10); // Keep last 10 insights

        return critical;
    }

    /**
     * Summarize a conversation segment intelligently
     */
    summarizeSegment(segment, context) {
        const summary = {
            timestamp: new Date().toISOString(),
            main_topics: [],
            tools_executed: context.tools_used,
            files_created: context.file_operations,
            key_outcomes: []
        };

        // Identify main topics (simple keyword extraction)
        const topics = segment.match(/\b(GitHub|file|token|manage|build|create|fix|error|success)\w*/gi) || [];
        summary.main_topics = [...new Set(topics)].slice(0, 5);

        // Extract outcomes
        if (segment.includes('✅')) {
            summary.key_outcomes.push('Success: Task completed');
        }
        if (segment.includes('⚠️')) {
            summary.key_outcomes.push('Warning: Issue identified');
        }
        if (segment.includes('🎯')) {
            summary.key_outcomes.push('Achievement unlocked');
        }

        return summary;
    }

    /**
     * Smart compression of conversation history
     */
    compressConversation(fullConversation) {
        const tokens = this.estimateTokens(fullConversation);
        
        if (tokens <= this.maxTokens - this.reserveTokens) {
            return fullConversation; // No compression needed
        }

        console.log(`🔧 Token limit reached (${tokens}/${this.maxTokens}). Compressing...`);

        // Extract critical context first
        const critical = this.extractCriticalContext(fullConversation);
        
        // Split conversation into segments (by timestamps or major breaks)
        const segments = fullConversation.split(/(?=## \d{1,2}\/\d{1,2}\/\d{4})|(?=💡)|(?=🎯)/);
        
        let compressed = `# Conversation Summary (Auto-generated)\n`;
        compressed += `Generated: ${critical.timestamp}\n\n`;
        
        // Always preserve the most recent segment in full
        const recentSegment = segments[segments.length - 1];
        compressed += `## Recent Activity (Full Detail)\n${recentSegment}\n\n`;
        
        // Summarize older segments
        compressed += `## Historical Summary\n`;
        for (let i = 0; i < segments.length - 1; i++) {
            const segment = segments[i];
            if (segment.length > 500) { // Only summarize substantial segments
                const summary = this.summarizeSegment(segment, critical);
                compressed += `### Segment ${i + 1}\n`;
                compressed += `- Topics: ${summary.main_topics.join(', ')}\n`;
                compressed += `- Tools: ${summary.tools_executed.join(', ')}\n`;
                compressed += `- Outcomes: ${summary.key_outcomes.join(', ')}\n\n`;
            }
        }

        // Preserve critical context
        compressed += `## Preserved Context\n`;
        compressed += `- GitHub Status: ${critical.github_status}\n`;
        compressed += `- Files Modified: ${critical.file_operations.join(', ')}\n`;
        compressed += `- Key Insights:\n`;
        critical.learning_insights.forEach(insight => {
            compressed += `  ${insight}\n`;
        });

        return compressed;
    }

    /**
     * Check if compression is needed and execute if so
     */
    manageTokens(conversation) {
        const tokens = this.estimateTokens(conversation);
        
        if (tokens > this.maxTokens - this.reserveTokens) {
            console.log(`🚨 Token management triggered: ${tokens}/${this.maxTokens} tokens`);
            return this.compressConversation(conversation);
        }
        
        console.log(`✅ Token usage OK: ${tokens}/${this.maxTokens} tokens`);
        return conversation;
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TokenManager;
}

// Browser global
if (typeof window !== 'undefined') {
    window.TokenManager = TokenManager;
}

console.log('🎯 Smart Token Management System loaded!');