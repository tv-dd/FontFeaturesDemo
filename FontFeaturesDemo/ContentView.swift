//
//  ContentView.swift
//  Copyright © 2026 DoorDash. All rights reserved.
//

import SwiftUI
import UIKit
import CoreText

// MARK: - OpenType Feature Testing

struct OpenTypeFeatureTester {
    let fontName: String
    let fontSize: CGFloat
    let isSystemFont: Bool
    let systemFontDesign: UIFontDescriptor.SystemDesign?

    // CoreText feature type identifiers
    static let kVerticalPositionType: Int = 10
    static let kSuperiorsSelector: Int = 1
    static let kInferiorsSelector: Int = 2
    static let kOrdinalsSelector: Int = 3
    static let kScientificInferiorsSelector: Int = 4

    // Number spacing
    static let kNumberSpacingType: Int = 6
    static let kProportionalNumbersSelector: Int = 1
    static let kTabularNumbersSelector: Int = 0

    // Number case
    static let kNumberCaseType: Int = 21
    static let kLowerCaseNumbersSelector: Int = 0
    static let kUpperCaseNumbersSelector: Int = 1

    // Stylistic alternatives
    static let kStylisticAlternativesType: Int = 35

    init(fontName: String, fontSize: CGFloat) {
        self.fontName = fontName
        self.fontSize = fontSize
        self.isSystemFont = false
        self.systemFontDesign = nil
    }

    init(fontConfig: FontConfig, fontSize: CGFloat) {
        self.fontName = fontConfig.postScriptName
        self.fontSize = fontSize
        self.isSystemFont = fontConfig.isSystemFont

        if fontConfig.isSystemFont {
            switch fontConfig.postScriptName {
            case "system-rounded":
                self.systemFontDesign = .rounded
            case "system-mono":
                self.systemFontDesign = .monospaced
            case "system-serif":
                self.systemFontDesign = .serif
            default:
                self.systemFontDesign = .default
            }
        } else {
            self.systemFontDesign = nil
        }
    }

    func loadFont() -> UIFont? {
        if isSystemFont {
            let systemFont = UIFont.systemFont(ofSize: fontSize)
            if let design = systemFontDesign,
               let descriptor = systemFont.fontDescriptor.withDesign(design) {
                return UIFont(descriptor: descriptor, size: fontSize)
            }
            return systemFont
        }

        if let font = UIFont(name: fontName, size: fontSize) {
            return font
        }

        // List available fonts for debugging
        print("Font '\(fontName)' not found. Available fonts:")
        for family in UIFont.familyNames.sorted() {
            print("  Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("    - \(name)")
            }
        }

        return nil
    }

    func queryAvailableFeatures() -> [(type: Int, typeString: String, selectors: [(id: Int, name: String)])] {
        guard let font = loadFont() else {
            return []
        }

        let ctFont = font as CTFont
        guard let features = CTFontCopyFeatures(ctFont) as? [[String: Any]] else {
            return []
        }

        var result: [(type: Int, typeString: String, selectors: [(id: Int, name: String)])] = []

        for feature in features {
            guard let typeID = feature[kCTFontFeatureTypeIdentifierKey as String] as? Int,
                  let typeName = feature[kCTFontFeatureTypeNameKey as String] as? String,
                  let selectors = feature[kCTFontFeatureTypeSelectorsKey as String] as? [[String: Any]] else {
                continue
            }

            var selectorList: [(id: Int, name: String)] = []
            for selector in selectors {
                if let selectorID = selector[kCTFontFeatureSelectorIdentifierKey as String] as? Int,
                   let selectorName = selector[kCTFontFeatureSelectorNameKey as String] as? String {
                    selectorList.append((id: selectorID, name: selectorName))
                }
            }

            result.append((type: typeID, typeString: typeName, selectors: selectorList))
        }

        return result
    }

    func createAttributedString(text: String, featureType: Int, featureSelector: Int) -> NSAttributedString {
        guard let font = loadFont() else {
            return NSAttributedString(string: text)
        }

        let featureSettings: [[UIFontDescriptor.FeatureKey: Any]] = [
            [
                .type: featureType,
                .selector: featureSelector,
            ]
        ]

        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: featureSettings
        ])

        let modifiedFont = UIFont(descriptor: descriptor, size: fontSize)

        return NSAttributedString(
            string: text,
            attributes: [.font: modifiedFont]
        )
    }

    func hasFeature(type: Int, selector: Int) -> Bool {
        let features = queryAvailableFeatures()
        for feature in features {
            if feature.type == type {
                for sel in feature.selectors {
                    if sel.id == selector {
                        return true
                    }
                }
            }
        }
        return false
    }
}

// MARK: - SwiftUI Views

struct AttributedText: UIViewRepresentable {
    let attributedString: NSAttributedString

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }
}

struct FeatureTestRow: View {
    let title: String
    let isAvailable: Bool
    let normalText: NSAttributedString
    let featureText: NSAttributedString

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(isAvailable ? "Available" : "Not Available")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(isAvailable ? .green : .red)
                    .cornerRadius(4)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Normal:").font(.caption).foregroundColor(.secondary)
                    AttributedText(attributedString: normalText)
                }

                VStack(alignment: .leading) {
                    Text("With Feature:").font(.caption).foregroundColor(.secondary)
                    AttributedText(attributedString: featureText)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Font Configuration

struct FontConfig: Identifiable, Hashable {
    let id = UUID()
    let displayName: String
    let postScriptName: String
    let isSystemFont: Bool

    init(displayName: String, postScriptName: String, isSystemFont: Bool = false) {
        self.displayName = displayName
        self.postScriptName = postScriptName
        self.isSystemFont = isSystemFont
    }

    static let allFonts: [FontConfig] = [
        // System Fonts
        FontConfig(displayName: "System Font (SF Pro)", postScriptName: "system", isSystemFont: true),
        FontConfig(displayName: "System Font Rounded", postScriptName: "system-rounded", isSystemFont: true),
        FontConfig(displayName: "System Font Monospaced", postScriptName: "system-mono", isSystemFont: true),
        FontConfig(displayName: "System Font Serif", postScriptName: "system-serif", isSystemFont: true),
        // DD Norms
        FontConfig(displayName: "DD Norms Regular", postScriptName: "DDNorms-Rg"),
        // TT Norms
        FontConfig(displayName: "TT Norms Medium", postScriptName: "TTNorms-Medium"),
        FontConfig(displayName: "TT Norms Bold", postScriptName: "TTNorms-Bold"),
        // Omnes
        FontConfig(displayName: "Omnes Bold", postScriptName: "Omnes-Bold"),
        FontConfig(displayName: "Omnes SemiBold", postScriptName: "OmnesSemiBold"),
        // SQ Market
        FontConfig(displayName: "SQ Market Regular", postScriptName: "SQMarket-Regular"),
        FontConfig(displayName: "SQ Market Medium", postScriptName: "SQMarket-Medium"),
        FontConfig(displayName: "SQ Market Bold", postScriptName: "SQMarket-Bold"),
        // Inter
        FontConfig(displayName: "Inter Regular", postScriptName: "Inter-Regular"),
        FontConfig(displayName: "Inter SemiBold", postScriptName: "Inter-SemiBold"),
    ]
}

// MARK: - Main Navigation View

struct ContentView: View {
    @State private var searchText = ""

    private var filteredFonts: [FontConfig] {
        if searchText.isEmpty {
            return FontConfig.allFonts
        }
        return FontConfig.allFonts.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.postScriptName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredFonts) { font in
                NavigationLink(value: font) {
                    FontListRow(fontConfig: font)
                }
            }
            .navigationTitle("Font Feature Demos")
            .searchable(text: $searchText, prompt: "Search fonts")
            .navigationDestination(for: FontConfig.self) { font in
                FontDemoView(fontConfig: font)
            }
        }
    }
}

struct FontListRow: View {
    let fontConfig: FontConfig

    private var displayFont: UIFont {
        let tester = OpenTypeFeatureTester(fontConfig: fontConfig, fontSize: 20)
        return tester.loadFont() ?? UIFont.systemFont(ofSize: 20)
    }

    private var attributedName: NSAttributedString {
        NSAttributedString(
            string: fontConfig.displayName,
            attributes: [.font: displayFont]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AttributedText(attributedString: attributedName)
                .frame(height: 28)
            Text(fontConfig.postScriptName)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Character Coverage View

struct CharacterCoverageView: View {
    let fontConfig: FontConfig
    let featureType: Int
    let featureSelector: Int
    let featureName: String

    private var tester: OpenTypeFeatureTester {
        OpenTypeFeatureTester(fontConfig: fontConfig, fontSize: 32)
    }

    private let digits = Array("0123456789")
    private let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    private let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private let symbols = Array("+-=()[]{}*/<>@#$%&!?.,:")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Characters that change have the \(featureName) glyph available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                CharacterGrid(
                    title: "Digits",
                    characters: digits,
                    fontConfig: fontConfig,
                    featureType: featureType,
                    featureSelector: featureSelector
                )

                CharacterGrid(
                    title: "Lowercase",
                    characters: lowercase,
                    fontConfig: fontConfig,
                    featureType: featureType,
                    featureSelector: featureSelector
                )

                CharacterGrid(
                    title: "Uppercase",
                    characters: uppercase,
                    fontConfig: fontConfig,
                    featureType: featureType,
                    featureSelector: featureSelector
                )

                CharacterGrid(
                    title: "Symbols",
                    characters: symbols,
                    fontConfig: fontConfig,
                    featureType: featureType,
                    featureSelector: featureSelector
                )
            }
            .padding()
        }
        .navigationTitle("\(featureName) Coverage")
    }
}

struct CharacterGrid: View {
    let title: String
    let characters: [Character]
    let fontConfig: FontConfig
    let featureType: Int
    let featureSelector: Int

    private let columns = [
        GridItem(.adaptive(minimum: 60), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(characters, id: \.self) { char in
                    CharacterCell(
                        character: char,
                        fontConfig: fontConfig,
                        featureType: featureType,
                        featureSelector: featureSelector
                    )
                }
            }
        }
    }
}

struct CharacterCell: View {
    let character: Character
    let fontConfig: FontConfig
    let featureType: Int
    let featureSelector: Int

    private var tester: OpenTypeFeatureTester {
        OpenTypeFeatureTester(fontConfig: fontConfig, fontSize: 32)
    }

    private var normalAttr: NSAttributedString {
        if let font = tester.loadFont() {
            return NSAttributedString(string: String(character), attributes: [.font: font])
        }
        return NSAttributedString(string: String(character))
    }

    private var featureAttr: NSAttributedString {
        tester.createAttributedString(
            text: String(character),
            featureType: featureType,
            featureSelector: featureSelector
        )
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                AttributedText(attributedString: normalAttr)
                    .frame(width: 24, height: 32)
                Text("→")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                AttributedText(attributedString: featureAttr)
                    .frame(width: 24, height: 32)
            }
            Text(String(character))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Font Demo View

struct FontDemoView: View {
    let fontConfig: FontConfig

    private var tester: OpenTypeFeatureTester {
        OpenTypeFeatureTester(fontConfig: fontConfig, fontSize: 24)
    }

    @State private var availableFeatures: [(type: Int, typeString: String, selectors: [(id: Int, name: String)])] = []
    @State private var fontLoaded = false
    @State private var debugInfo = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Font Status
                HStack {
                    Text("Font Status:")
                        .font(.headline)
                    Text(fontLoaded ? "Loaded Successfully" : "Not Loaded")
                        .foregroundColor(fontLoaded ? .green : .red)
                }

                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Superscript Section
                HStack {
                    Text("Superscript (sups)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    NavigationLink("View All Characters") {
                        CharacterCoverageView(
                            fontConfig: fontConfig,
                            featureType: OpenTypeFeatureTester.kVerticalPositionType,
                            featureSelector: OpenTypeFeatureTester.kSuperiorsSelector,
                            featureName: "Superscript"
                        )
                    }
                    .font(.caption)
                }

                FeatureTestRow(
                    title: "Superscript - Digits (sups)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kSuperiorsSelector
                    ),
                    normalText: createNormalText("H2O x2 y3"),
                    featureText: tester.createAttributedString(
                        text: "H2O x2 y3",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kSuperiorsSelector
                    )
                )

                // Superscript Test (letters)
                FeatureTestRow(
                    title: "Superscript - Letters (sups)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kSuperiorsSelector
                    ),
                    normalText: createNormalText("xa yb zn Mc"),
                    featureText: tester.createAttributedString(
                        text: "xa yb zn Mc",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kSuperiorsSelector
                    )
                )

                // Superscript Test (special characters)
                FeatureTestRow(
                    title: "Superscript - Special (sups)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kSuperiorsSelector
                    ),
                    normalText: createNormalText("$Xx00 c*"),
                    featureText: tester.createAttributedString(
                        text: "$Xx00 c*",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kSuperiorsSelector
                    )
                )

                Divider()

                // Subscript Section
                HStack {
                    Text("Subscript (subs)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    NavigationLink("View All Characters") {
                        CharacterCoverageView(
                            fontConfig: fontConfig,
                            featureType: OpenTypeFeatureTester.kVerticalPositionType,
                            featureSelector: OpenTypeFeatureTester.kInferiorsSelector,
                            featureName: "Subscript"
                        )
                    }
                    .font(.caption)
                }

                FeatureTestRow(
                    title: "Subscript - Digits (subs)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kInferiorsSelector
                    ),
                    normalText: createNormalText("H2O CO2 x0"),
                    featureText: tester.createAttributedString(
                        text: "H2O CO2 x0",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kInferiorsSelector
                    )
                )

                // Subscript Test (letters)
                FeatureTestRow(
                    title: "Subscript - Letters (subs)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kInferiorsSelector
                    ),
                    normalText: createNormalText("xa yb zn Mc"),
                    featureText: tester.createAttributedString(
                        text: "xa yb zn Mc",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kInferiorsSelector
                    )
                )

                // Subscript Test (special characters)
                FeatureTestRow(
                    title: "Subscript - Special (subs)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kInferiorsSelector
                    ),
                    normalText: createNormalText("$Xx00 c*"),
                    featureText: tester.createAttributedString(
                        text: "$Xx00 c*",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kInferiorsSelector
                    )
                )

                // Ordinals Test
                FeatureTestRow(
                    title: "Ordinals (ordn)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kOrdinalsSelector
                    ),
                    normalText: createNormalText("1st 2nd 3rd"),
                    featureText: tester.createAttributedString(
                        text: "1st 2nd 3rd",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kOrdinalsSelector
                    )
                )

                // Scientific Inferiors Test
                FeatureTestRow(
                    title: "Scientific Inferiors (sinf)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kVerticalPositionType,
                        selector: OpenTypeFeatureTester.kScientificInferiorsSelector
                    ),
                    normalText: createNormalText("H2SO4"),
                    featureText: tester.createAttributedString(
                        text: "H2SO4",
                        featureType: OpenTypeFeatureTester.kVerticalPositionType,
                        featureSelector: OpenTypeFeatureTester.kScientificInferiorsSelector
                    )
                )

                // Tabular Numbers Test
                FeatureTestRow(
                    title: "Tabular Numbers (tnum)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kNumberSpacingType,
                        selector: OpenTypeFeatureTester.kTabularNumbersSelector
                    ),
                    normalText: createNormalText("1111\n9999"),
                    featureText: tester.createAttributedString(
                        text: "1111\n9999",
                        featureType: OpenTypeFeatureTester.kNumberSpacingType,
                        featureSelector: OpenTypeFeatureTester.kTabularNumbersSelector
                    )
                )

                // Proportional Numbers Test
                FeatureTestRow(
                    title: "Proportional Numbers (pnum)",
                    isAvailable: tester.hasFeature(
                        type: OpenTypeFeatureTester.kNumberSpacingType,
                        selector: OpenTypeFeatureTester.kProportionalNumbersSelector
                    ),
                    normalText: createNormalText("1111\n9999"),
                    featureText: tester.createAttributedString(
                        text: "1111\n9999",
                        featureType: OpenTypeFeatureTester.kNumberSpacingType,
                        featureSelector: OpenTypeFeatureTester.kProportionalNumbersSelector
                    )
                )

                Divider()

                // All Available Features
                Text("All Available OpenType Features")
                    .font(.title2)

                ForEach(availableFeatures, id: \.type) { feature in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type \(feature.type): \(feature.typeString)")
                            .font(.headline)

                        ForEach(feature.selectors, id: \.id) { selector in
                            Text("  - Selector \(selector.id): \(selector.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if availableFeatures.isEmpty {
                    Text("No features found or font not loaded")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(fontConfig.displayName)
        .onAppear {
            loadFontAndFeatures()
        }
    }

    private func loadFontAndFeatures() {
        if let font = tester.loadFont() {
            fontLoaded = true
            debugInfo = "Font: \(font.fontName), Size: \(font.pointSize)"
        } else {
            fontLoaded = false
            debugInfo = "Could not load font '\(fontConfig.postScriptName)'. Check console for available fonts."
        }

        availableFeatures = tester.queryAvailableFeatures()
    }

    private func createNormalText(_ text: String) -> NSAttributedString {
        if let font = tester.loadFont() {
            return NSAttributedString(string: text, attributes: [.font: font])
        }
        return NSAttributedString(string: text)
    }
}

#Preview {
    ContentView()
}
