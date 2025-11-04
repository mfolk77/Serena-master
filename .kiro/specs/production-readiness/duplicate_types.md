# Duplicate Types in SerenaMaster Codebase

This document identifies duplicate type definitions across the SerenaMaster codebase that need to be consolidated into CoreModels.swift.

## Identified Duplicate Types

### 1. ValidationResult, ValidationError, ValidationWarning
- **Primary Location**: CoreModels.swift
- **Duplicate Location**: FTAIParser.swift
- **Status**: Partially fixed according to IMMEDIATE_FIXES_TODO.md
- **Notes**: FTAIParser.swift is using these types from CoreModels.swift but there are still references that need to be updated

### 2. FormatValidationResult, FormatIssue
- **Primary Location**: FTAIParser.swift
- **Canonical Location**: Should be moved to CoreModels.swift
- **Notes**: These types are specific to FTAI parsing but should be consolidated in CoreModels for consistency

### 3. VoiceConfig
- **Primary Location**: CoreModels.swift
- **Duplicate Location**: CoreProtocols.swift
- **Notes**: Two different definitions of VoiceConfig exist, causing ambiguity in IntegrationTestRunner.swift

### 4. SystemHealth
- **Primary Location**: CoreProtocols.swift
- **Duplicate Location**: Possibly in other files
- **Notes**: Mentioned in IMMEDIATE_FIXES_TODO.md as resolved, but may need verification

### 5. AgentStatus
- **Primary Location**: CoreModels.swift
- **Duplicate Location**: CoreProtocols.swift
- **Status**: Fixed according to IMMEDIATE_FIXES_TODO.md
- **Notes**: Verify all references use the canonical type

### 6. PerformanceMetric
- **Primary Location**: Unknown (not found in examined files)
- **Duplicate Location**: SystemLogger.swift
- **Notes**: Used in SystemLogger.swift but not defined in CoreModels.swift

### 7. CodableMemoryEntry
- **Primary Location**: Unknown (not found in examined files)
- **Duplicate Location**: MemoryManager.swift
- **Notes**: Used for serialization in MemoryManager.swift but not defined in CoreModels.swift

### 8. MemoryStats
- **Primary Location**: CoreProtocols.swift
- **Duplicate Location**: Possibly in MemoryManager.swift
- **Notes**: Should be consolidated in CoreModels.swift

### 9. SystemLoad
- **Primary Location**: CoreProtocols.swift
- **Duplicate Location**: Possibly in AgentRouter.swift
- **Notes**: Should be consolidated in CoreModels.swift

### 10. ErrorContext
- **Primary Location**: OrchestrationErrors.swift
- **Duplicate Location**: Possibly in other files
- **Notes**: Should be consolidated in CoreModels.swift or OrchestrationErrors.swift

## Canonical Location Recommendations

The following types should be moved to or kept in these canonical locations:

### CoreModels.swift (Primary location for shared data models)
- ValidationResult
- ValidationError
- ValidationWarning
- FormatValidationResult
- FormatIssue
- VoiceConfig
- AgentStatus
- PerformanceMetric
- CodableMemoryEntry
- MemoryStats
- SystemLoad
- ErrorContext

### OrchestrationErrors.swift (Error-specific types)
- All error enums and error-related types

## Next Steps

1. Verify each duplicate type by examining its usage across the codebase
2. Determine the canonical version of each type based on completeness and usage
3. Consolidate duplicate types into CoreModels.swift
4. Update all references to use the canonical types
5. Fix any resulting type mismatches or compilation errors