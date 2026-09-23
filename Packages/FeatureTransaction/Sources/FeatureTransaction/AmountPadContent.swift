import CoreDomain
import CoreUI
import SwiftUI

struct AmountPadContent: View {
    let amount: Amount
    let type: TransactionType
    let accountName: String?
    let monthSpend: Amount?
    let canSave: Bool
    let savedTransactionID: TransactionID?
    let failure: DomainError?
    let onKey: (KeypadKey) -> Void
    let onSave: () -> Void
    let onDismissFailure: () -> Void
    let onOpenMonth: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion: Bool

    var body: some View {
        VStack(spacing: Spacing.s6) {
            SummaryButton(action: onOpenMonth) {
                MonthSpendHeader(spend: monthSpend)
            }
            .accessibilityHint(Text(verbatim: "Abre los movimientos del mes"))
            .padding(.horizontal, Spacing.s4)
            Spacer(minLength: 0)
            typedAmount
                .padding(.horizontal, Spacing.s4)
            DefaultsChips(type: type, accountName: accountName)
            Group {
                Keypad(onKey: onKey)
                PrimaryButton("Guardar", action: onSave)
                    .disabled(!canSave)
            }
            .padding(.horizontal, Spacing.s4)
        }
        .padding(.vertical, Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .onSwipeUp(perform: onOpenMonth)
        .alert("Algo salió mal", isPresented: isShowingFailure) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(verbatim: failure?.message ?? "")
        }
    }

    private var typedAmount: some View {
        ZStack {
            AmountDisplay(amount, sign: type == .income ? .positive : .unsigned)
                .id(savedTransactionID)
                .transition(.asymmetric(insertion: .opacity, removal: Motion.signatureTransition(reduceMotion: reduceMotion)))
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.signature, value: savedTransactionID)
    }

    private var isShowingFailure: Binding<Bool> {
        Binding(
            get: { failure != nil },
            set: { (isPresented: Bool) in
                if !isPresented { onDismissFailure() }
            }
        )
    }
}

#Preview("Empty") {
    AmountPadContent(
        amount: Amount.zero,
        type: .spend,
        accountName: "Efectivo",
        monthSpend: (try? Amount(cents: 184_250)) ?? Amount.zero,
        canSave: false,
        savedTransactionID: nil,
        failure: nil,
        onKey: { _ in },
        onSave: {},
        onDismissFailure: {},
        onOpenMonth: {}
    )
}

#Preview("Typed Spend") {
    AmountPadContent(
        amount: (try? Amount(cents: 1_250)) ?? Amount.zero,
        type: .spend,
        accountName: "Efectivo",
        monthSpend: (try? Amount(cents: 184_250)) ?? Amount.zero,
        canSave: true,
        savedTransactionID: nil,
        failure: nil,
        onKey: { _ in },
        onSave: {},
        onDismissFailure: {},
        onOpenMonth: {}
    )
}

#Preview("Typed Income") {
    AmountPadContent(
        amount: (try? Amount(cents: 350_000)) ?? Amount.zero,
        type: .income,
        accountName: "Efectivo",
        monthSpend: (try? Amount(cents: 184_250)) ?? Amount.zero,
        canSave: true,
        savedTransactionID: nil,
        failure: nil,
        onKey: { _ in },
        onSave: {},
        onDismissFailure: {},
        onOpenMonth: {}
    )
}

#Preview("No Account") {
    AmountPadContent(
        amount: (try? Amount(cents: 1_250)) ?? Amount.zero,
        type: .spend,
        accountName: nil,
        monthSpend: Amount.zero,
        canSave: false,
        savedTransactionID: nil,
        failure: nil,
        onKey: { _ in },
        onSave: {},
        onDismissFailure: {},
        onOpenMonth: {}
    )
}

#Preview("Storage failure") {
    AmountPadContent(
        amount: (try? Amount(cents: 1_250)) ?? Amount.zero,
        type: .spend,
        accountName: "Efectivo",
        monthSpend: nil,
        canSave: true,
        savedTransactionID: nil,
        failure: .storageFailure,
        onKey: { _ in },
        onSave: {},
        onDismissFailure: {},
        onOpenMonth: {}
    )
}
