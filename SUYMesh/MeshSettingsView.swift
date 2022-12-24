//
//  ContentView.swift
//  Shared
//
//  Created by 梅澤真史 on 2022/09/09.
//

import SwiftUI

@available(iOS 14.0, *)
struct MeshSettingsView: View {
    var dismiss: () -> Void = {}
    
    @StateObject var client = MeshServiceAccessor.bonjourPeerClient()
    @StateObject var server = MeshServiceAccessor.bonjourPeerServer()
    
    init(dismiss: @escaping () -> Void, client: BonjourPeer = MeshServiceAccessor.bonjourPeerClient(), server: BonjourPeer = MeshServiceAccessor.bonjourPeerServer()) {
        self.dismiss = dismiss
        MeshServiceAccessor.setup()
    }
    
    var body: some View {
        VStack {
            closeButton
            MeshTabView(client: client, server: server)
            Spacer()
        }
            .background(Color.backgroundColor)
            .onDisappear {
                client.stop()
            }
    }
    
    var closeButton: some View {
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image("flat-close")
                            .padding(0)
                    }
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.leading, 10)
            }
        }
}

@available(iOS 14.0, *)
struct MeshSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        MeshSettingsView(dismiss: { })
    }
}
