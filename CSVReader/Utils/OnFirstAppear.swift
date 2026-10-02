import SwiftUI

private struct OnFirstAppearModifier: ViewModifier {
    @State private var didAppear = false

    let action: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            guard !didAppear else { return }
            didAppear = true
            action()
        }
    }
}

extension View {
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
}
