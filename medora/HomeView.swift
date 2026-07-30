import SwiftUI

struct HomeDashboardView: View {
    var body: some View {
        Text("Home Dashboard — Phase 2")
            .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        HomeDashboardView()
    }
}
