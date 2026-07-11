import Foundation
@testable import MigratorCore

struct MockLLMProvider: LLMProvider {
    
    var stubbedResponse = LLMFixResponse(patch: nil, explanation: "mock")
    
    func proposeFix(for request: LLMFixRequest) async throws -> LLMFixResponse {
        stubbedResponse
    }
}
