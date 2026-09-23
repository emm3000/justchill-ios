import CoreDomain
import FeatureTransaction
import Observation

extension MonthModel {
    func waitUntilLoaded() async -> MonthPresentation? {
        let presentations: Observations<MonthPresentation?, Never> = Observations { self.presentation }
        for await presentation: MonthPresentation? in presentations where presentation != nil {
            return presentation
        }
        return nil
    }

    func waitForFailure() async {
        let failures: Observations<DomainError?, Never> = Observations { self.failure }
        for await failure: DomainError? in failures where failure != nil {
            return
        }
    }

    func recordSpend(count: Int) async -> [Amount] {
        let spends: Observations<Amount?, Never> = Observations { self.presentation?.spend }
        var recorded: [Amount] = []
        for await spend: Amount? in spends {
            guard let spend: Amount = spend else { continue }
            recorded.append(spend)
            if recorded.count == count { break }
        }
        return recorded
    }
}
