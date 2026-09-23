import CoreDomain
import FeatureTransaction
import Observation

extension AmountPadModel {
    func waitUntilLoaded() async {
        let loaded: Observations<Bool, Never> = Observations { self.accounts != nil && self.monthSpend != nil }
        for await isLoaded: Bool in loaded where isLoaded {
            return
        }
    }

    func waitForFailure() async {
        let failures: Observations<DomainError?, Never> = Observations { self.failure }
        for await failure: DomainError? in failures where failure != nil {
            return
        }
    }

    func recordMonthSpend(count: Int) async -> [Amount] {
        let totals: Observations<Amount?, Never> = Observations { self.monthSpend }
        var recorded: [Amount] = []
        for await total: Amount? in totals {
            guard let total: Amount = total else { continue }
            recorded.append(total)
            if recorded.count == count { break }
        }
        return recorded
    }
}
