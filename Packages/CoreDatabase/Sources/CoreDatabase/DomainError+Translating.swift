import CoreDomain

extension DomainError {
    init(translating error: any Error) {
        self = (error as? DomainError) ?? .storageFailure
    }
}
