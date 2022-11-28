//
//  ContentView.swift
//  Shared
//
//  Created by 梅澤真史 on 2022/09/09.
//

import SwiftUI

@available(iOS 14.0, *)
struct MeshTabItemViewSelector: View
{
    @StateObject var client: BonjourPeer
    @StateObject var server: BonjourPeer
    
    @Binding var selectedIndex: Int
    
    var body: some View {
        return Group
        {
            if selectedIndex == 0
            {
                MeshClientPartView(client: client)
            }
            else if selectedIndex == 1
            {
                MeshServerPartView(server: server)
            }
        }
    }
    
}

@available(iOS 14.0, *)
struct MeshTabView: View {
    @StateObject var client: BonjourPeer
    @StateObject var server: BonjourPeer

    @State private var selectionIndex = 0
    @State private var fixedSelectionIndex = 1
    private var disabledIndex: Int {
        if(shouldDisableClientPart){
            return 0
        }
        if(shouldDisableServerPart){
            return 1
        }
        return -1
    }
    
    private var currentIndex: Binding<Int>{
        return selectionIndex == disabledIndex ? $fixedSelectionIndex : $selectionIndex
    }
    
    private var shouldDisableClientPart: Bool {
        return MeshServiceAccessor.isServerActive()
    }
    private var shouldDisableServerPart: Bool {
        return MeshServiceAccessor.isAlreadyConnected()
    }
    
    var body: some View
    {
        TabView(selection: $selectionIndex)
        {
            MeshTabItemViewSelector(client: client, server: server, selectedIndex: currentIndex)
                .tabItem {
                    Image(systemName: "person.wave.2")
                    Text("Join Mesh")
                }
                .tag(0)
            MeshTabItemViewSelector(client: client, server: server, selectedIndex: currentIndex)
                .tabItem {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Host Mesh")
                }
                .tag(1)
        }
        .accentColor(selectionIndex == disabledIndex ? Color.gray : Color.blue)
        .onChange(of: selectionIndex) { _ in
            if selectionIndex == disabledIndex {
                selectionIndex = fixedSelectionIndex
            } else {
                fixedSelectionIndex = selectionIndex
            }
        }
        .onAppear{
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)], for: .selected)
            UITabBar.appearance().isTranslucent = false
            selectionIndex = (shouldDisableClientPart) ? 1 : 0
            fixedSelectionIndex = (shouldDisableServerPart) ? 0 : 1
        }
    }
    
}

@available(iOS 14.0, *)
struct MeshTab_Previews: PreviewProvider {
    @StateObject static var client =  BonjourPeer(isClient: true)
    @StateObject static var server =  BonjourPeer()
    static var previews: some View {
        MeshTabView(client: client, server: server)
    }
}

