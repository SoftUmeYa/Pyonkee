//
//  MeshServerPartView.swift
//
//  Created by 梅澤真史 on 2022/10/09.
//

import SwiftUI

@available(iOS 14.0, *)
struct MeshServerPartView: View {
    @StateObject var server: BonjourPeer
    
    private func getIpAddress() -> String {
        if(MeshServiceAccessor.isNetReady == false){
            return ""
        }
        return server.getIpAddress()
    }
    private func toggleIsRunning(){
        if(isServingMesh) {
            server.stop()
            MeshServiceAccessor.stopMesh()
        } else {
            server.start()
            MeshServiceAccessor.startMesh()
        }
    }
    private var isServingMesh: Bool {
        return MeshServiceAccessor.isServerActive()
    }
    private var buttonLabel: LocalizedStringKey {
        return LocalizedStringKey(isServingMesh ? "Stop" : "Start")
    }
    private var foregroundColorOfIpAddressPart: Color {
        return isServingMesh ? Color.black : Color.deactivatedColor
    }
    var body: some View {
        VStack{
            Section {
                Group {
                    Spacer().frame(height: 0)
                    HStack{
                        Text("IP Address:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.black)
                        Text(self.getIpAddress())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(foregroundColorOfIpAddressPart)
                    }
                        .padding(.vertical, 10)
                    Spacer().frame(height: 5)
                    HStack{
                        Button(action:{
                            self.toggleIsRunning()
                        }){
                            Text(buttonLabel)
                                .frame(maxWidth: .infinity)
                        }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 12)
                            .background(Color.buttonBackgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    }
                    Spacer()
                    Divider()
                }
                    .padding(.horizontal, 10)
                    .padding(.vertical, -10)
            } header: {
                Group {
                    Text("Host Mesh")
                        .fontWeight(.bold)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                    .padding(.horizontal, 10)
                    .background(Color.headerBackgroundColor)
            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 0)
                .padding(.horizontal, 0)
        }
        .background(Color.backgroundColor)
    }
}

@available(iOS 14.0, *)
struct MeshServerRowView_Previews: PreviewProvider {
    @StateObject static var server = BonjourPeer()
    static var previews: some View {
        MeshServerPartView(server: server)
    }
}
