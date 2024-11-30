//
//  JudgeOverviewView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 30.11.24.
//

import SwiftUI


struct JudgeOverviewView : View {
    let competitions = ["100m Lauf", "Weitsprung", "Hochsprung"]
    
    var body: some View {
        print("REcompute!!!")
        return
        HStack {
            NavigationView {
                ScrollView {
                        VStack(spacing: 12) {
                            Text("Wettkämpfe").bold().font(.title)
                            ForEach(competitions.indices, id: \.self) { index in
                                NavigationLink("\(competitions[index])",
                                               destination: JudgeContestView(COMPETITION: competitions[index])
                                    ) // NavigationLink
                                    .bold()
                                    .background(Color.white)
                                    .foregroundColor(Color.black)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity).onAppear(){print("Appearing")}
                            } // ForEach
                            .padding(.top, 10)
                        } // VStack
                } // ScrollView
            } // NavigationView
        }
    }
}
