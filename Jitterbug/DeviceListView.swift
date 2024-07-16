//
// Copyright © 2021 osy. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject private var main: Main
    @State private var showIpAlert: Bool = false
    @State private var manualAddHostPresented: Bool = false
    @State private var isFirstTime = true

    var body: some View {
        List {
            if !main.savedHosts.isEmpty {
                Section(header: Text("Saved")) {
                    ForEach(main.savedHosts) { host in
                        NavigationLink(destination: DeviceDetailsView(host: host), tag: host.identifier, selection: $main.selectedHostId) {
                            HostView(host: host, saved: true)
                                .foregroundColor(host.discovered ? .primary : .secondary)
                        }.deviceListContextMenu(host: host)
                    }
                }
            }
            Section(header: Text("Discovered")) {
                ForEach(main.foundHosts) { host in
                    NavigationLink(destination: DeviceDetailsView(host: host), tag: host.identifier, selection: $main.selectedHostId) {
                        HostView(host: host, saved: false)
                    }.deviceListContextMenu(host: host)
                }
            }
        }
        .onAppear {
            if isFirstTime {
                isFirstTime = false
                main.startScanning()
            }
        }
        .onDisappear {
//            main.stopScanning()
        }
        .navigationTitle("Devices")
        .toolbar {
            Button {
                manualAddHostPresented.toggle()
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
        .popover(isPresented: $manualAddHostPresented, arrowEdge: .trailing) {
            // BUG: SwiftUI won't let us put this on the navbar or it won't close properly
            ManualAddHostView()
        }
    }
}

struct HostView: View {
    @EnvironmentObject private var main: Main
    
    let host: JBHostDevice
    let saved: Bool
    
    var body: some View {
        HStack {
            Button {
                if saved {
                    main.removeSavedHost(host)
                } else {
                    main.saveHost(host)
                }
            } label: {
                Label("Save", systemImage: saved ? "star.fill" : "star")
                    .foregroundColor(.accentColor)
            }
            switch (host.hostDeviceType) {
            case .typeUnknown:
                Label("Unknown", systemImage: "questionmark")
            case .typeiPhone:
                Label("iPhone", systemImage: "apps.iphone")
            case .typeiPad:
                Label("iPhone", systemImage: "apps.ipad")
            @unknown default:
                Label("Unknown", systemImage: "questionmark")
            }
            Text(host.name)
            Spacer()
        }.buttonStyle(PlainButtonStyle())
    }
}

struct ContextMenuViewModifier: ViewModifier {
    @EnvironmentObject private var main: Main
    let host: JBHostDevice
    
    func body(content: Content) -> some View {
        content.contextMenu {
            #if os(iOS)
            Button {
                UIPasteboard.general.url = main.encodeURL(forHost: host)
            } label: {
                Label("Copy Shortcut URL", systemImage: "link")
                    .labelStyle(DefaultLabelStyle())
            }
            #endif
            Button {
                main.savePairing(nil, forHostIdentifier: host.identifier)
                main.saveDiskImage(nil, signature: nil, forHostIdentifier: host.identifier)
                #if os(macOS)
                main.backgroundTask(message: NSLocalizedString("Unpairing...", comment: "DeviceListView")) {
                    if !host.isConnected {
                        try host.startLockdown()
                    }
                    try host.resetPairing()
                }
                #endif
            } label: {
                Label("Clear Pairing", systemImage: "xmark.circle")
                    .labelStyle(DefaultLabelStyle())
            }
        }
    }
}

extension View {
    func deviceListContextMenu(host: JBHostDevice) -> some View {
        self.modifier(ContextMenuViewModifier(host: host))
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
    }
}
