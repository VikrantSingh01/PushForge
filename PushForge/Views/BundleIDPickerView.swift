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
        ("Microsoft Teams", "com.microsoft.skype.teams"),
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
        ("Microsoft Teams", "com.microsoft.teams"),
    ]

    private static let desktopApps: [(name: String, bundleID: String)] = [
        ("Safari", "com.apple.Safari"),
        ("Mail", "com.apple.mail"),
        ("Messages", "com.apple.MobileSMS"),
        ("Calendar", "com.apple.iCal"),
        ("Notes", "com.apple.Notes"),
        ("Reminders", "com.apple.reminders"),
        ("Maps", "com.apple.Maps"),
        ("Finder", "com.apple.finder"),
        ("Music", "com.apple.Music"),
        ("News", "com.apple.news"),
        ("Slack", "com.tinyspeck.slackmacgap"),
        ("Microsoft Teams", "com.microsoft.teams2"),
        ("Chrome", "com.google.Chrome"),
        ("Firefox", "org.mozilla.firefox"),
        ("VS Code", "com.microsoft.VSCode"),
    ]

    private var apps: [(name: String, bundleID: String)] {
        switch targetPlatform {
        case .iOSSimulator: Self.iosApps
        case .androidEmulator: Self.androidApps
        case .desktop: Self.desktopApps
        }
    }

    private var placeholder: String {
        switch targetPlatform {
        case .iOSSimulator: "com.example.myapp"
        case .androidEmulator: "com.example.myapp"
        case .desktop: "com.example.webapp"
        }
    }

    private var label: String {
        switch targetPlatform {
        case .iOSSimulator: "Bundle ID"
        case .androidEmulator: "Package"
        case .desktop: "App ID"
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
