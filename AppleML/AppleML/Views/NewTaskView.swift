import SwiftUI

enum MLFeature: String, CaseIterable, Identifiable {
    case transcribe
    case ocr

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transcribe: return "Transcribe"
        case .ocr: return "OCR"
        }
    }

    var subtitle: String {
        switch self {
        case .transcribe: return "Audio to text"
        case .ocr: return "Image to text"
        }
    }

    var icon: String {
        switch self {
        case .transcribe: return "waveform"
        case .ocr: return "doc.text.viewfinder"
        }
    }

    var color: Color {
        switch self {
        case .transcribe: return .blue
        case .ocr: return .orange
        }
    }
}

struct NewTaskView: View {
    @State private var selectedFeature: MLFeature?

    var body: some View {
        VStack(spacing: 0) {
            if let feature = selectedFeature {
                // Show the selected feature's workspace
                HStack(spacing: 0) {
                    // Feature selector strip (compact, horizontal)
                    featureStrip
                    Divider()
                    // Workspace
                    featureWorkspace(feature)
                }
            } else {
                // Feature selection grid
                featureGrid
            }
        }
    }

    // MARK: - Feature Grid (initial selection)

    private var featureGrid: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What would you like to do?")
                .font(.title2)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(MLFeature.allCases) { feature in
                    FeatureCard(feature: feature) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFeature = feature
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Feature Strip (after selection)

    private var featureStrip: some View {
        VStack(spacing: 8) {
            ForEach(MLFeature.allCases) { feature in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFeature = feature
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18))
                        Text(feature.title)
                            .font(.caption2)
                    }
                    .frame(width: 56, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedFeature == feature ? feature.color.opacity(0.15) : Color.clear)
                    )
                    .foregroundStyle(selectedFeature == feature ? feature.color : .secondary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(width: 64)
    }

    // MARK: - Workspace

    @ViewBuilder
    private func featureWorkspace(_ feature: MLFeature) -> some View {
        switch feature {
        case .transcribe:
            TranscribeView()
        case .ocr:
            OCRView()
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: MLFeature
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: feature.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(feature.color)

                VStack(spacing: 4) {
                    Text(feature.title)
                        .font(.headline)
                    Text(feature.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovering ? feature.color.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isHovering ? feature.color.opacity(0.4) : Color.secondary.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
