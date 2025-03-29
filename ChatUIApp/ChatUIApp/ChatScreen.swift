//
//  ChatScreen.swift
//  Assignment
//
//  Created by Gaurang on 27/03/25.
//

import SwiftUI

struct ChatScreen: View {
    @State private var text = ""
    @State private var sheetHeight: CGFloat = 200
    @State private var isFullyExpanded = false
    private let buttonHeight: CGFloat = 50
    private let vSpacing: CGFloat = 20
    @State var selectedDetent: PresentationDetent = .height(200)
    @State var detents: Set<PresentationDetent> = [.height(200), .large ]
    
    var body: some View {
        VStack(spacing: vSpacing) {
            HStack{
                TextField(text: $text, axis: .vertical) {
                    Text("Start typing...")
                }
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                if !text.isEmpty {
                    Button(action: {
                        selectedDetent = selectedDetent == .large ? .height(200) : .large
                    }, label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    })
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
            HStack {
                Button(action: {}, label: {
                    Image(systemName: "photo.artframe.circle.fill")
                })
                Spacer()
                Button(action: {}, label: {
                    Image(systemName: "paperplane.circle.fill")
                })
            }.font(.system(size: 50))
                .padding(.horizontal)
        }
        
        .presentationDetents(detents, selection: $selectedDetent)
        .interactiveDismissDisabled()
        
    }
    
    
}
