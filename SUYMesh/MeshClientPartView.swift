//
//  SwiftUIView.swift
//  BonjourTest
//
//  Created by 梅澤真史 on 2022/10/09.
//

import SwiftUI

@available(iOS 14.0, *)
struct MeshClientPartView: View {
    
    @StateObject var client: BonjourPeer
    
    @State private var textInputValue: String = MeshServiceAccessor.connectedIpAddress
    @State private var isConnected: Bool = false
    @State private var isConnecting: Bool = false
    private let placeholder: String = NSLocalizedString("Enter IP Address", comment: "")
    private let warningImage: UIImage = (UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal))!
    private var options: [DropdownOption] {
        return self.client.serverPeerNames.map{
            DropdownOption(key: $0, value: $0)
        }
    }
    
    private var buttonLabel: LocalizedStringKey {
        let isRunning = MeshServiceAccessor.isMeshRunning();
        suylog("isRunning: \(isRunning)")
        return LocalizedStringKey(isConnected ? "Leave" : "Join")
    }
    
    private func toggleConnect(){
        if(isConnected){
            MeshServiceAccessor.leaveMesh()
            MeshServiceAccessor.clearConnectedIpAddress()
            isConnected = MeshServiceAccessor.isClientActive()
        } else {
            let ipAddress = textInputValue
            if(textInputValue.count == 0) {
                return self.warnConnectionFailed();
            }
            MeshServiceAccessor.joinMesh(ipAddress)
            self.confirmConnected(ipAddress)
        }
    }
    
    private func confirmConnected(_ ipAddress:String){
        deferConnect(ipAddress, waitSeconds: 1, onFailed: {
            deferConnect(ipAddress, waitSeconds: 2, onFailed: {
                deferConnect(ipAddress, waitSeconds: 3, onFailed: {
                    self.warnConnectionFailed()
                })
            })
        })
    }
    
    private func confirmAlreadyConnectedOnOpen(){
        let ipAddress = MeshServiceAccessor.connectedIpAddress
        if(ipAddress != ""){
            deferConnect(ipAddress, waitSeconds: 1, onFailed: {
                deferConnect(ipAddress, waitSeconds: 2, onFailed: {
                    textInputValue = ""
                    MeshServiceAccessor.clearConnectedIpAddress()
                    isConnecting = false;
                })
            })
        }
    }
    
    private func deferConnect(_ ipAddress: String, waitSeconds:Int, onFailed:@escaping ()->Void ){
        isConnecting = true;
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(waitSeconds)) {
            isConnected = MeshServiceAccessor.isMeshMember(ipAddress)
            if(!isConnected){
                onFailed()
                MeshServiceAccessor.clearConnectedIpAddress()
            } else {
                isConnecting = false;
                MeshServiceAccessor.connectedIpAddress = ipAddress
            }
        }
    }
    
    private func warnConnectionFailed() {
        SUYToast.showToast(message: NSLocalizedString("Cannot connect", comment: ""), image: (warningImage), position: "bottom")
        isConnecting = false;
    }
    
    var body: some View {
        VStack{
            Section {
                Group {
                    Spacer().frame(height: 0)
                    HStack{
                        DropdownSelector(
                            textInputValue: $textInputValue,
                            placeholder: placeholder,
                            options: options,
                            onOptionSelected: { option in
                                textInputValue = option.value
                        })
                            .padding(.vertical, 12)
                            .disabled(isConnected)
                        Button(action:{
                            self.toggleConnect()
                        }){
                            Text(buttonLabel)
                                .padding(.horizontal, 5)
                        }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 12)
                            .background(Color.buttonBackgroundColor)
                            .disabled(isConnecting)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                    }
                        .zIndex(100)
                    Spacer()
                    Divider()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, -10)
            } header: {
                Group {
                    Text("Join Mesh")
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
        .onAppear{
            client.start()
            self.confirmAlreadyConnectedOnOpen()
        }
    }
}

@available(iOS 14.0, *)
struct MeshClientRowView_Previews: PreviewProvider {
    @StateObject static var client =  BonjourPeer(isClient: true)
    static var previews: some View {
        MeshClientPartView(client: client)
    }
}
