import SwiftUI
import MigratorCore

struct ContentView: View {
    var body: some View {
        Text("SwiftMigrator — MigratorCore v\(MigratorCore.version)")
            .foregroundStyle(.secondary)
            .frame(minWidth: 480, minHeight: 320)
    }
}

#Preview {
    ContentView()
}
