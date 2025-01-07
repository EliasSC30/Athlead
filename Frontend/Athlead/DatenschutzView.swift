//
//  DatenschutzView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 07.01.25.
//


import SwiftUI

struct DatenschutzView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Title
                Text("Datenschutzrichtlinie")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Intro Text
                Text("""
                    Wir freuen uns über Ihr Interesse an unserer Website. Der Schutz Ihrer Privatsphäre ist für uns sehr wichtig. Nachstehend informieren wir Sie ausführlich über den Umgang mit Ihren Daten.
                """)
                
                // Section: Verantwortliche Stelle
                SectionHeader(title: "1. Verantwortliche Stelle")
                Text("""
                    Verantwortliche Stelle für die Datenverarbeitung auf dieser Website ist:
                    Athlead Inc.
                    Adresse: 123 Sports Street, Berlin, Germany
                    Telefon: +49 123 456789
                    E-Mail: datenschutz@athlead.com
                """)

                // Section: Erhebung und Speicherung personenbezogener Daten
                SectionHeader(title: "2. Erhebung und Speicherung personenbezogener Daten")
                SectionSubheader(title: "a) Beim Besuch der Website")
                Text("""
                    Beim Aufrufen unserer Website werden automatisch Informationen an den Server unserer Website gesendet.
                    Diese Informationen werden temporär gespeichert und beinhalten:
                    - Keine Informationen werden gespeichert.
                """)
                
                // Section: Weitergabe von Daten
                SectionHeader(title: "3. Weitergabe von Daten")
                Text("""
                    Eine Übermittlung Ihrer persönlichen Daten an Dritte erfolgt nur unter bestimmten Umständen, wie:
                    - Ihre ausdrückliche Einwilligung.
                    - Zur Geltendmachung von Rechtsansprüchen.
                    - Gesetzliche Verpflichtung.
                """)

                // Section: Betroffenenrechte
                SectionHeader(title: "4. Betroffenenrechte")
                Text("""
                    Sie haben das Recht auf Auskunft, Berichtigung, Löschung und Einschränkung der Verarbeitung Ihrer personenbezogenen Daten.
                """)

                // Section: Widerspruchsrecht
                SectionHeader(title: "5. Widerspruchsrecht")
                Text("""
                    Sie haben das Recht, gemäß Art. 21 DSGVO Widerspruch gegen die Verarbeitung Ihrer personenbezogenen Daten einzulegen.
                """)

                // Section: Datensicherheit
                SectionHeader(title: "6. Datensicherheit")
                Text("""
                    Wir verwenden SSL-Verschlüsselung, um Ihre Daten zu schützen.
                """)

                // Section: Aktualität und Änderung der Datenschutzerklärung
                SectionHeader(title: "7. Aktualität und Änderung dieser Datenschutzerklärung")
                Text("""
                    Diese Datenschutzerklärung ist aktuell gültig und hat den Stand [Datum]. Änderungen können aufgrund gesetzlicher Änderungen notwendig werden.
                """)
            }
            .padding()
        }
        .navigationBarTitle("Datenschutzrichtlinie", displayMode: .inline)
    }
}
