import CoreDomain

extension DomainError {
    public var message: String {
        switch self {
        case .negativeAmount: "El monto no puede ser negativo."
        case .zeroAmount: "Escribe un monto mayor que cero."
        case .occurredAfterToday: "La fecha no puede ser posterior a hoy."
        case .impossibleOccurredAt: "Esa fecha no existe."
        case .impossibleMonth: "Ese mes no existe."
        case .storageFailure: "No se pudo leer ni guardar en este iPhone. Inténtalo de nuevo."
        }
    }
}
