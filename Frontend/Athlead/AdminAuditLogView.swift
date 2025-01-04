//
//  AdminAuditLogView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 03.01.25.
//

import SwiftUI

// MARK: - Data Model
struct AuditLogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let user: String
    let action: String
    let method: String // HTTP method
    let isWarning: Bool // New property for warnings
}

// MARK: - Sample Data
let sampleAuditLogs: [AuditLogEntry] = [
    AuditLogEntry(id: UUID(), timestamp: Date(), user: "Elias", action: "Updated Sportfest 'Bundesjudengspiele'", method: "PATCH", isWarning: false),
    AuditLogEntry(id: UUID(), timestamp: Date().addingTimeInterval(-3600), user: "Jan", action: "Created a new user 'Collin Forslund' with role 'Contestant'", method: "POST", isWarning: false),
    AuditLogEntry(id: UUID(), timestamp: Date().addingTimeInterval(-7200), user: "Elias", action: "Deleted his own entry due to lack of skills", method: "DELETE", isWarning: true)
]

// MARK: - Filter Options
struct AuditLogFilter {
    var dateRange: ClosedRange<Date>?
    var method: String?
    var showWarningsOnly: Bool = false
}

// MARK: - AuditLogView
struct AdminAuditLogView: View {
    @State private var auditLogs: [AuditLogEntry] = sampleAuditLogs
    @State private var filter = AuditLogFilter()
    @State private var isFilterSheetPresented = false

    var filteredLogs: [AuditLogEntry] {
        auditLogs.filter { entry in
            let matchesDateRange = filter.dateRange?.contains(entry.timestamp) ?? true
            let matchesMethod = filter.method.map { $0 == entry.method } ?? true
            let matchesWarning = !filter.showWarningsOnly || entry.isWarning
            return matchesDateRange && matchesMethod && matchesWarning
        }
    }

    var body: some View {
            VStack {
                List(filteredLogs) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.action)
                            .font(.headline)
                            .foregroundColor(entry.isWarning ? .yellow : .primary)
                        HStack {
                            Text(entry.user)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(entry.method)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                            Spacer()
                            Text(entry.timestamp, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .navigationTitle("Audit Log")
                .toolbar {
                    Button(action: {
                        isFilterSheetPresented.toggle()
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
                .sheet(isPresented: $isFilterSheetPresented) {
                    FilterSheet(filter: $filter, isPresented: $isFilterSheetPresented)
                }
        }
    }
}

// MARK: - FilterSheet
struct FilterSheet: View {
    @Binding var filter: AuditLogFilter
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter Options")
                    .font(.headline)

                DatePicker("Start Date", selection: Binding(
                    get: { filter.dateRange?.lowerBound ?? Date() },
                    set: { startDate in
                        let endDate = filter.dateRange?.upperBound ?? Date()
                        filter.dateRange = startDate...endDate
                    }
                ), displayedComponents: .date)

                DatePicker("End Date", selection: Binding(
                    get: { filter.dateRange?.upperBound ?? Date() },
                    set: { endDate in
                        let startDate = filter.dateRange?.lowerBound ?? Date.distantPast
                        filter.dateRange = startDate...endDate
                    }
                ), displayedComponents: .date)

                Picker("Method", selection: $filter.method) {
                    Text("All").tag(String?.none)
                    Text("PATCH").tag(String?("PATCH"))
                    Text("POST").tag(String?("POST"))
                    Text("PUT").tag(String?("PUT"))
                    Text("DELETE").tag(String?("DELETE"))
                }
                .pickerStyle(MenuPickerStyle())

                Toggle("Show Warnings Only", isOn: $filter.showWarningsOnly)

                Spacer()
            }
            .padding()
            .navigationTitle("Filter Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
