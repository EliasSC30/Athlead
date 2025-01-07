//
//  ImpressumView.swift
//  Athlead
//
//  Created by Wichmann, Jan on 07.01.25.
//


import SwiftUI

struct ImpressumView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Title
                Text("Impressum")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Section: Angaben gemäß § 5 TMG
                SectionHeader(title: "Angaben gemäß § 5 TMG")
                Text("""
                    Unternehmensname: Athlead Inc.
                    Adresse: 123 Sports Street
                    PLZ Ort: Berlin, 12345
                    Vertreten durch: Nathanäl Hendrik Forlsund
                """)
                
                // Section: Kontakt
                SectionHeader(title: "Kontakt")
                Text("""
                    Telefon: +49 123 456789
                    Telefax: +49 123 456789
                    E-Mail: contact@athlead.com
                """)
                
                // Section: Registereintrag
                SectionHeader(title: "Registereintrag")
                Text("""
                    Eintragung im Handelsregister.
                    Registergericht: Amtsgericht Berlin
                    Registernummer: 12345678
                """)
                
                // Section: Umsatzsteuer-ID
                SectionHeader(title: "Umsatzsteuer-ID")
                Text("""
                    Umsatzsteuer-Identifikationsnummer gemäß §27 a Umsatzsteuergesetz: DE123456789
                """)
                
                // Section: Aufsichtsbehörde
                SectionHeader(title: "Aufsichtsbehörde")
                Text("Zuständige Aufsichtsbehörde: Berlin Office")

                // Section: Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV
                SectionHeader(title: "Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV")
                Text("""
                    Verantwortlicher: Nathanäl Hendrik Forlsund
                    Adresse: 123 Sports Street, Berlin, Germany
                """)

                // Section: Streitschlichtung
                SectionHeader(title: "Streitschlichtung")
                Text("""
                    Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung bereit: [Link zur OS-Plattform]
                    Unsere E-Mail-Adresse finden Sie oben im Impressum.
                    Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren teilzunehmen.
                """)
                
                // Section: Haftungsausschluss (Disclaimer)
                SectionHeader(title: "Haftungsausschluss (Disclaimer)")
                
                // Haftung für Inhalte
                SectionSubheader(title: "Haftung für Inhalte")
                Text("""
                    Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten verantwortlich.
                    Nach §§ 8 bis 10 TMG sind wir jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen.
                """)
                
                // Haftung für Links
                SectionSubheader(title: "Haftung für Links")
                Text("""
                    Unser Angebot enthält Links zu externen Websites Dritter, auf deren Inhalte wir keinen Einfluss haben.
                    Für die Inhalte der verlinkten Seiten ist stets der jeweilige Anbieter verantwortlich.
                """)
            }
            .padding()
        }
        .navigationBarTitle("Impressum", displayMode: .inline)
    }
}

struct SectionHeader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top)
    }
}

struct SectionSubheader: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.top, 5)
    }
}
