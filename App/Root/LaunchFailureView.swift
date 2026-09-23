import CoreDomain
import CoreUI
import SwiftUI

struct LaunchFailureView: View {
    let failure: DomainError

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(verbatim: "No pudimos abrir tus datos")
                .font(Typography.label)
                .foregroundStyle(Palette.textPrimary)
            Text(verbatim: failure.message)
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
            Text(verbatim: "Cierra la app y vuelve a abrirla.")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, Spacing.s4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Palette.background)
    }
}

#Preview {
    LaunchFailureView(failure: DomainError.storageFailure)
}
