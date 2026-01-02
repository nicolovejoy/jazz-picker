//
//  InstrumentPickerContent.swift
//  JazzPicker
//

import SwiftUI

/// Shared instrument picker form content. Used by both Settings and PDF viewer.
struct InstrumentPickerContent: View {
    @Binding var selectedInstrument: Instrument

    var body: some View {
        ForEach(Instrument.groups) { group in
            Section(group.label) {
                ForEach(group.instruments) { instrument in
                    instrumentRow(instrument)
                }
            }
        }
    }

    @ViewBuilder
    private func instrumentRow(_ instrument: Instrument) -> some View {
        Button {
            selectedInstrument = instrument
        } label: {
            HStack {
                Text(instrument.label)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedInstrument == instrument {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

#Preview {
    Form {
        InstrumentPickerContent(selectedInstrument: .constant(.trumpet))
    }
}
