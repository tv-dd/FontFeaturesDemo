# Font Features Demo

An iOS SwiftUI application for testing and visualizing OpenType font features across multiple typefaces.

## Overview

Font Features Demo is a developer tool that helps designers and engineers explore OpenType typographic features in various fonts. The app provides an interactive interface to test features like superscripts, subscripts, tabular numbers, and more, making it easy to verify font support before implementing typography in production apps.

## Features

- **Multiple Font Support**: Test System Fonts (SF Pro, SF Rounded, SF Mono, SF Serif) and custom fonts (DD Norms, TT Norms, Omnes, SQ Market, Inter)
- **OpenType Feature Testing**: Visualize how fonts render with different OpenType features enabled
- **Character Coverage**: View comprehensive character-by-character coverage for specific features
- **Feature Availability Detection**: Automatically detects which OpenType features each font supports
- **Side-by-Side Comparison**: Compare normal text rendering against feature-enabled rendering

## Tested OpenType Features

The app tests the following OpenType features:

- **Superscripts (sups)**: Raised glyphs for superior characters
- **Subscripts (subs)**: Lowered glyphs for inferior characters
- **Ordinals (ordn)**: Specialized glyphs for ordinal indicators (1st, 2nd, 3rd)
- **Scientific Inferiors (sinf)**: Optimized subscripts for scientific notation
- **Tabular Numbers (tnum)**: Fixed-width numbers for tables and alignment
- **Proportional Numbers (pnum)**: Variable-width numbers for body text

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd FontFeaturesDemo
   ```

2. Open the project in Xcode:
   ```bash
   open FontFeaturesDemo.xcodeproj
   ```

3. Build and run on simulator or device

## Included Fonts

The project includes several custom fonts for testing:

- **DD Norms** (DoorDash brand font)
- **TT Norms** (Medium, Bold)
- **Omnes** (SemiBold, Bold)
- **SQ Market** (Regular, Medium, Bold)
- **Inter** (Regular, SemiBold)

Fonts are embedded in the app bundle and registered via `Info.plist`.

## Usage

1. Launch the app to see a list of available fonts
2. Use the search bar to filter fonts by name
3. Tap any font to view its OpenType feature support
4. Each feature shows:
   - Availability status (green = available, red = unavailable)
   - Normal rendering
   - Feature-enabled rendering
5. Tap "View All Characters" to see character-by-character coverage for specific features

## Technical Implementation

The app uses Apple's CoreText framework to:

- Query available OpenType features via `CTFontCopyFeatures`
- Apply features using `UIFontDescriptor.FeatureKey`
- Test feature support by feature type and selector identifiers

Key components:

- `OpenTypeFeatureTester`: Core engine for loading fonts and applying features
- `FontDemoView`: Main demonstration interface with feature tests
- `CharacterCoverageView`: Character-by-character feature coverage viewer

## License

Copyright 2026 DoorDash. All rights reserved.

## Contributing

This is an internal tool for font feature testing. For issues or feature requests, please contact the design systems team.
