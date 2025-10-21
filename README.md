# H3S PDF UI SDK

A lightweight wrapper that wires licensing and logging to present the H3S PDF UI in your app. It exposes simple SwiftUI and UIKit entry points and a clean set of PDF actions for adding signature placeholders, wet signatures, annotations, watermarks, and applying digital signatures.

Public entry point for presenting the H3S PDF UI in SwiftUI or UIKit, with licensing and logging wired in.

- Module: `h3s_pdf_ui_sdk`
- Author: Satish Singh
- © 2025 H3S Ventures. All rights reserved.

## Overview

`h3s_pdf_ui_sdk` provides:
- A SwiftUI content view hosting the H3S PDF UI.
- A UIKit view controller hosting the H3S PDF UI.
- A set of PDF actions (signing, watermarking, annotations) via `PDFActionsProtocol`.
- Configuration types for UI behavior, including draggable signature placeholders.
- Built-in licensing validation using an embedded public key PEM (`h3s-pdf-ui-sdk.pem`).
- Optional logging with configurable subsystem and level.

## Requirements

- iOS 16.0+ / iPadOS 16.0+
- Xcode 15+
- Swift 5.9+

## Installation

### Swift Package Manager (recommended)

Add the package to your project:

1. In Xcode: File → Add Package Dependencies…
2. Enter the URL of your package index or the binary release: `https://github.com/h3sventures/h3s-pdf-ui-sdk`
3. Select the product `h3s_pdf_ui_sdk`.

Your `Package.swift` might look like:

```swift
.dependencies([
    .package(url: "https://github.com/h3sventures/h3s-pdf-ui-sdk", from: "0.1.0")
])

.targets([
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "h3s_pdf_ui_sdk", package: "h3s-pdf-ui-sdk")
        ]
    )
])
```

## Initialization

Use the initializer to configure the SDK with your license, UI configuration, and logging preferences.

```swift
let sdk = H3SPDFUISDK(
    licenseKey: "<YOUR-LICENSE-KEY>",
    config: .default,
    logLevel: .none,
    logSubsystem: nil // or your bundle identifier
)
```
- licenseKey: `String` Your H3S license key string.
- config: `H3SPDFUIConfig` controlling visible features and UI behavior. Defaults to .default.
- logLevel: `LogLevel` logging level. Defaults to `.none`.
- logSubsystem: `String` Optional custom log subsystem (e.g., your bundle ID). Defaults to the SDK’s subsystem.

## Presenting the UI

### SwiftUI

Use `getH3SPDFContentView` to embed the PDF UI. The content closure gives you a `PDFActionsProtocol` to trigger actions.

```swift
struct PDFHostView: View {
    @State private var pdfView: AnyView?

    var body: some View {
        Group {
            if let pdfView {
                pdfView
            } else {
                ProgressView("Loading PDF UI…")
                    .task {
                        let view = await sdk.getH3SPDFContentView(placement: .top) { actions in
                            // Your overlay UI using actions
                            VStack {
                                Button("Add Sign Placeholder") {
                                    Task {
                                        _ = try? await actions.addSignaturePlaceholder()
                                    }
                                }
                                Button("Add Watermark") {
                                    Task {
                                        _ = try? await actions.addWatermark(with: "CONFIDENTIAL")
                                    }
                                }
                            }
                        }
                        pdfView = AnyView(view)
                    }
            }
        }
    }
}
```
- placement: `PDFActionButtonPlacement` for fixed action buttons (.top or .bottom). Defaults to .top.
- content: Closure receives `PDFActionsProtocol` for triggering actions. Return your overlay content.

### UIKit

Use `getH3SPDFViewController` to obtain a configured `UIViewController`.

```swift
@MainActor
func presentPDF(from presentingVC: UIViewController) async {
    let vc = await sdk.getH3SPDFViewController(placement: .top)
    presentingVC.present(vc, animated: true)
}
```
- placement: `.top` or `.bottom`. Defaults to `.top`.

### Button Placement

`PDFActionButtonPlacement` controls where fixed action buttons appear:

- .top
- .bottom

### Draggable Signature Overlay Configuration

`H3SDraggableViewConfig` configures the draggable overlay used to position signature placeholders.

**Properties:**
- position: `CGPoint` — starting position in the PDF view’s coordinate space.
- overlaySize: `CGSize` — overlay rectangle size.
- cornerRadius: `CGFloat` — overlay corner radius.
- backgroundColor: `Color` — overlay background color.
- text: `String` — label text inside the overlay.
- font: `Font` — label font.
- textColor: `Color` — label text color.
- textPadding: `CGFloat` — padding around the label text.

Default configuration:

```swift
let draggableConfig = H3SDraggableViewConfig.default
```

Custom example:

```swift
let customDraggable = H3SDraggableViewConfig(
    position: CGPoint(x: 50, y: 50),
    overlaySize: CGSize(width: 200, height: 60),
    cornerRadius: 12,
    backgroundColor: .blue.opacity(0.2),
    text: "Sign Here",
    font: .headline,
    textColor: .blue,
    textPadding: 8
)
```

### UI Configuration

`H3SPDFUIConfig` controls available features and UI affordances. Some features may be hidden depending on your license.

**Key properties:**
- showDragAndDropSignPosition: `Bool` — enable drag-and-drop sign positioning.
- draggableViewConfig: `H3SDraggableViewConfig` — draggable overlay configuration.
- hideDragAndDropOnSuccess: `Bool` — hide the draggable overlay after success.
- showToolbarWithAction: `Bool` — show toolbar with actions.
- showFloatingActionButtons: `Bool` — enable draggable FABs.
- showFixedActionButtons: `Bool` — show fixed action buttons at the chosen placement.
- showShareAction: Bool` — show share action button.
- showSignPlaceholderButton: `Bool` — show Sign Placeholder action.
- showWatermarkButton: `Bool` — show Watermark action.
- showWetSignButton: `Bool` — show Wet Sign action.
- showReloadPDFButton: `Bool` — show Reload PDF action.
- showSignAnnotationButton: `Bool` — show Sign Annotation action.

Defaults:
```swift
let config = H3SPDFUIConfig.default
```

Custom example:

```swift
let config = H3SPDFUIConfig.default.with {
    $0.showToolbarWithAction = true
    $0.showFixedActionButtons = true
    $0.showShareAction = true
    $0.draggableViewConfig = customDraggable
}
```

Note: The .with mutating helper is just illustrative. If you don’t have such a helper, mutate a var copy directly.

## PDF Actions

Use PDFActionsProtocol to modify the currently presented PDF. All methods return updated PDF data.

### 1) Add Signature Placeholder

Adds a cryptographic signature placeholder at a given location.

```swift
let updatedPDF = try await actions.addSignaturePlaceholder(
    at: .init(page: .lastPage, position: .bottomLeft),
    placeholderLength: 8192,
    signatureBoxSize: .init(width: 200, height: 50),
    signatureImage: nil, // or a PDFImage
    additionalInfo: []   // [PDFAdditionalInfo]
)
```

Convenience overload with defaults:

```swift
let updatedPDF = try await actions.addSignaturePlaceholder()
```
**Parameters:**
- location: `PDFObjectLocation` — where to place the placeholder.
- placeholderLength: `Int` — reserved byte length for signature container.
- signatureBoxSize: `PDFSize` — visual size of the signature box.
- signatureImage: `PDFImage?` — optional image to display in the box.
- additionalInfo: `[PDFAdditionalInfo]` — extra metadata to embed.

### 2) Add Wet (Drawn) Signature

Embeds a wet signature image at a given location.

```swift
let updatedPDF = try await actions.addWetSignature(
    at: .init(page: .lastPage, position: .bottomLeft),
    image: mySignatureImage,
    signatureBoxSize: .init(width: 100, height: 50)
)
```

Convenience overload with defaults:

```swift
let updatedPDF = try await actions.addWetSignature(image: mySignatureImage)
```

### 3) Apply Digital Signature

Applies digital signature bytes to a reserved placeholder.

```swift
let updatedPDF = try await actions.signDocument(signatureData: signatureBytes)
```

### 4) Add Sign Annotation

Adds a sign-here annotation at a given location.

```swift
let updatedPDF = try await actions.addSignAnnotation(
    at: .init(page: .lastPage, position: .bottomLeft)
)
```

### 5) Add Text Watermark

Adds a text watermark to specified pages.

```swift
let updatedPDF = try await actions.addWatermark(
    with: "CONFIDENTIAL",
    on: [1, 2, 3],
    fontSize: 80,
    color: .default
)
```

Convenience overload with defaults:

```swift
let updatedPDF = try await actions.addWatermark(with: "CONFIDENTIAL")
```
Parameters:
- text: `String` — watermark text.
- pages: `[Int]` — 1-based page indices.
- fontSize: `Int` — font size.
- color: `PDFColor` — text color.

## Types Referenced

- `PDFObjectLocation`: Describes page and position for placements.
- `PDFSize`: Width/height for boxes and overlays.
- `PDFImage`: Image wrapper for PDF embedding.
- `PDFAdditionalInfo`: Key-value metadata for placeholders.
- `PDFColor`: Color type used by the PDF engine.

These types are provided by h3s_pdf / h3s_pdf_ui.

> **Notes:**
- Methods are async and may throw; handle errors accordingly.
- Some features may be restricted by your license.
- The SDK uses an internal logger and license verifier.

### Example: Full Setup

```swift
import SwiftUI
import h3s_pdf_ui_sdk

@MainActor
final class PDFDemoViewModel: ObservableObject {
    let sdk: H3SPDFUISDK

    init() {
        var config = H3SPDFUIConfig.default
        config.showToolbarWithAction = true
        config.showFixedActionButtons = true
        config.draggableViewConfig = H3SDraggableViewConfig.default

        sdk = H3SPDFUISDK(
            licenseKey: "<YOUR-LICENSE-KEY>",
            config: config,
            logLevel: .info,
            logSubsystem: Bundle.main.bundleIdentifier
        )
    }

    func makeView() async -> some View {
        await sdk.getH3SPDFContentView(placement: .top) { actions in
            VStack {
                Button("Sign Placeholder") {
                    Task { _ = try? await actions.addSignaturePlaceholder() }
                }
                Button("Watermark") {
                    Task { _ = try? await actions.addWatermark(with: "CONFIDENTIAL") }
                }
                Button("Sign Annotation") {
                    Task { _ = try? await actions.addSignAnnotation() }
                }
            }
            .padding()
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = PDFDemoViewModel()
    @State private var hosted: AnyView?

    var body: some View {
        Group {
            if let hosted {
                hosted
            } else {
                ProgressView("Loading…")
                    .task {
                        hosted = AnyView(await vm.makeView())
                    }
            }
        }
    }
}
```

### Demo License key:
```swift
eyJ1c3IiOiJIM1MgVmVudHVyZXMiLCJleHAiOjE5MjQ4MzcyMDAsImF1ZCI6bnVsbCwiZGVtbyI6dHJ1ZSwiZmVhdCI6WyJkaWdpIiwid2V0Iiwic2FubiIsIndtcmsiLCJzcG9zIiwiZml4ZCIsImFubm8iLCJzaHJlIl19.PXganw6xq5dX3dX8bM2CB4/782+Vi/eWHytTcw5u4Tma+8Ok6i3mUKFG9kkeNricB+PXoalRELL/K/9Zp62sRr5nljjrB7E92743a4smR4q9exIsjZLzEPNaEgfL3JW2x/WEbczVFysXmadHkTyUqKcMy2JD0mIIT1lzrkAtSDCn9sQ42yuNvPOIxFBdAtx6vfJ5lA3iIUDH8tcKq3em00Tqm6DnEtlsKaa+z9V3Xyw+fOseN1S7Y+bpwbBIDt8H8/OsV3+AkI+yd3/D4NO+OfOyWHYkheVS5+3BbFw1XIcDKM2U/ni+e7cFgL8nW3yEAaR2Cgc8I8RzcZpfB08LMA==

```
