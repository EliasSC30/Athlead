//
//  ParticipantView.swift
//  Athlead
//
//  Created by Oezcan, Elias on 28.12.24.
//

import Foundation
import SwiftUI


struct ParticipantView : View {
    @State var myContests: [ContestForJudge] = []
    @State private var children: [Person] = []
    @State private var isFetching = true;
    
    var body: some View {
        VStack{
            Text("Meine Wettkämpfe")
            if children.isEmpty {
                NavigationLink(destination: ParentView(children: $children)){
                    Text("Meine Kinder")
                }
            } else {
                if myContests.isEmpty {
                    Text("Keine Wettkämpfe")
                } else {
                    NavigationStack {
                        ForEach(myContests) { contest in
                            NavigationLink(destination: ContestDetailView(contest: contest)) {
                                HStack {
                                    Text("\(contest.ct_name)")
                                }
                                .padding(4.0)
                            }
                            .padding(1.0)
                            .background(Color.white)
                            .shadow(radius: 5.0)
                            .cornerRadius(1.0, antialiased: false)
                            .foregroundColor(Color.black)
                        }
                    }
                }
            }
        }.onAppear {
            fetch("contests/participants/mycontests", ContestForJudgeResponse.self){ result in
                switch result {
                case .success(let result): myContests = result.data;
                case .failure(let err): print("Could not fetch my contests: ", err);
                }
            }
            
            fetch("parents/children", ParentsChildrenResponse.self){ result in
                switch result {
                case .success(let resp): children = resp.children
                case .failure(let err): print(err);
                }
            }
            
            isFetching = false;
        }
    }
}

struct ParentView: View {
    @Binding var children: [Person]
    
    var body: some View {
        List {
            ForEach(children){ child in
                HStack {
                    Text("\(child.FIRSTNAME) \(child.LASTNAME)")
                }
            }
        }
    }
}


