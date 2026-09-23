public enum AccountType: String, CaseIterable, Hashable, Sendable {
    case bank = "Bank"
    case cash = "Cash"
    case creditCard = "CreditCard"
    case investment = "Investment"
    case wallet = "Wallet"
}
