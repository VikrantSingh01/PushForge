import SwiftUI

struct BundleIDPickerView: View {
    @Binding var bundleIdentifier: String
    var targetPlatform: TargetPlatform = .iOSSimulator

    private static let iosApps: [(name: String, bundleID: String)] = [
        ("Settings", "com.apple.Preferences"),
        ("Safari", "com.apple.mobilesafari"),
        ("Messages", "com.apple.MobileSMS"),
        ("Maps", "com.apple.Maps"),
        ("Calendar", "com.apple.mobilecal"),
        ("Photos", "com.apple.mobileslideshow"),
        ("Notes", "com.apple.mobilenotes"),
        ("Contacts", "com.apple.MobileAddressBook"),
        ("Reminders", "com.apple.reminders"),
        ("Clock", "com.apple.mobiletimer"),
        ("Weather", "com.apple.weather"),
        ("Files", "com.apple.DocumentsApp"),
        ("Camera", "com.apple.camera"),
        ("Health", "com.apple.Health"),
    ]

    private static let androidApps: [(name: String, bundleID: String)] = [
        ("Settings", "com.android.settings"),
        ("Contacts", "com.android.contacts"),
        ("Phone", "com.android.dialer"),
        ("Messages", "com.android.messaging"),
        ("Calendar", "com.android.calendar"),
        ("Camera", "com.android.camera2"),
        ("Gallery", "com.android.gallery3d"),
        ("Chrome", "com.android.chrome"),
        ("Gmail", "com.google.android.gm"),
        ("Google Maps", "com.google.android.apps.maps"),
        ("YouTube", "com.google.android.youtube"),
        ("Play Store", "com.android.vending"),
        ("Clock", "com.google.android.deskclock"),
        ("Calculator", "com.google.android.calculator"),
    ]

    private var apps: [(name: String, bundleID: String)] {
        switch targetPlatform {
        case .iOSSimulator: Self.iosApps
        case .androidEmulator: Self.androidApps
        }
    }

    private var placeholder: String {
        switch targetPlatform {
        case .iOSSimulator: "com.example.myapp"
        case .androidEmulator: "com.example.myapp"
        }
    }

    private var label: String {
        switch targetPlatform {
        case .iOSSimulator: "Bundle ID"
        case .androidEmulator: "Package"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .fontWeight(.medium)
            TextField(placeholder, text: $bundleIdentifier)
                .textFieldStyle(.roundedBorder)
            Menu {
                ForEach(apps, id: \.bundleID) { app in
                    Button {
                        bundleIdentifier = app.bundleID
                    } label: {
                        Text("\(app.name) — \(app.bundleID)")
                    }
                }
            } label: {
                Image(systemName: "chevron.down.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}
