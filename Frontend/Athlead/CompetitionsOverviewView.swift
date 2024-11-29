//
//  Competition.swift
//  Athlead
//
//  Created by Wichmann, Jan on 20.11.24.
//


import SwiftUI


struct Metric {
    var time: Float32
    var timeUnit: String
    
    var length: Float32
    var lengthUnit: String
    
    var weight: Float32
    var weightUnit: String
    
    var amount: Int32
}

struct Competition: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let location: String
}

struct CompetitorContestInfo : Identifiable {
    let id = UUID()
    let name: String
    let metric : Metric
}


struct CompetitionsOverviewView: View {
    enum CompType {
        case LongJump
        case HundredMeterRun
        case HighJump
    }
    
    let competitions = [
        Competition(name: "Weitsprung", date: "20.11.2024", location: "Stadion A"),
        Competition(name: "100m Lauf", date: "21.11.2024", location: "Stadion B"),
        Competition(name: "Hochsprung", date: "22.11.2024", location: "Stadion C")
    ]
    //length = 0, lengthUnit = "", w
    let contestInfos = [
        // 100m Dummy
        CompetitorContestInfo(name: "Elias", metric: Metric(time: 9.53, timeUnit: "s", length:0.0, lengthUnit:"", weight:0.0, weightUnit: "", amount:0)),
        CompetitorContestInfo(name: "Jan", metric: Metric(time: 12.90, timeUnit: "s", length:0.0, lengthUnit:"", weight:0.0, weightUnit: "", amount:0)),
        // Long Dummy
        CompetitorContestInfo(name: "Elias", metric: Metric(time:0.0, timeUnit:"",length: 8.99, lengthUnit: "m", weight:0.0, weightUnit: "", amount:0)),
        CompetitorContestInfo(name: "Jan", metric: Metric(time:0.0, timeUnit:"", length: 4.33, lengthUnit: "m", weight:0.0, weightUnit: "", amount:0)),
        // High Dummy
        CompetitorContestInfo(name: "Elias", metric: Metric(time:0.0, timeUnit:"",length: 1.95, lengthUnit: "m", weight:0.0, weightUnit: "", amount:0)),
        CompetitorContestInfo(name: "Jan", metric: Metric(time:0.0, timeUnit:"", length: 1.40, lengthUnit: "m", weight:0.0, weightUnit: "", amount:0)),

    ]
    
    func getFormattedPlacings(competition : String, compInfos : [CompetitorContestInfo]) -> [String]
    {
        switch(competition)
        {
        case "Weitsprung":
            return compInfos.map { $0.name + " jumped " + $0.metric.length.formatted() + $0.metric.lengthUnit };
        case "100m Lauf":
            return compInfos.map { $0.name + " ran 100m " + $0.metric.time.formatted() + $0.metric.timeUnit };
        case "Hochsprung":
            return compInfos.map { $0.name + " jumped " + $0.metric.length.formatted() + $0.metric.lengthUnit + " high" };
        default:
            return ["Competition is unknown"];
        }
    }

    var body: some View {
        NavigationView {
            List(competitions) { competition in
                NavigationLink(destination: CompetitionDetailView(competition: competition,
                                                                  rowContent: getFormattedPlacings(competition : competition.name, compInfos : contestInfos)))
                {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(competition.name)
                                .font(.headline)
                            Text("\(competition.date) - \(competition.location)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Wettkämpfe")
        }
    }
}

struct CompetitionDetailView: View {
    let competition: Competition
    let rowContent: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text(competition.name)
                .font(.largeTitle)
                .bold()
            Text("Datum: \(competition.date)")
            Text("Ort: \(competition.location)")
            List {
                Section(header: Text("Ergebnisse").font(.headline)) {
                    ForEach(rowContent.indices, id: \.self) { index in
                        Text((index + 1).formatted() + "  " + rowContent[index])
                    }
                }
            }
            .padding(.top, 5)
            .foregroundColor(.primary)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
            .background(Color.white)
            .scrollContentBackground(.hidden)
        }
        
    }
}
