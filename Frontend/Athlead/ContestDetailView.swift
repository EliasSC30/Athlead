//
//  ContestDetailView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.12.24.
//
import SwiftUI

struct ContestDetailView: View {
    let contest : Contest = Contest(ID: "1", SPORTFEST_ID: "1", DETAILS_ID: "1", CONTESTRESULT_ID: "1")
    
    struct Contest: Identifiable, Hashable {
        let ID: String
        let SPORTFEST_ID: String
        let DETAILS_ID: String
        let CONTESTRESULT_ID: String
        
        var id: String { return self.ID }
    }
    
    var body: some View {
        
        VStack {
            
            Text("Wettkampf")
            
        }
    }
}
    
    
    

