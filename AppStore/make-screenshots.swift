import AppKit
import Foundation

// Composites App Store marketing screenshots: a headline over the real device capture on a
// near-black background, so the app's orange reads as the accent it is.
// Output is 1320 x 2868 — the required 6.9" size, no scaling afterwards.

let W = 1320, H = 2868
let source = CommandLine.arguments[1]
let outDir = CommandLine.arguments[2]

struct Shot {
    let file: String
    let line1: String
    let line2: String
}

// Ordered for the store: the promise first, then how it feels, then the breadth.
let shots = [
    Shot(file: "1-home.png",            line1: "Your whole workout,",  line2: "one number"),
    Shot(file: "6-active-workout.png",  line1: "Log a set",            line2: "in two taps"),
    Shot(file: "2-new-record.png",      line1: "Beat it, and",         line2: "you'll know"),
    Shot(file: "3-summary.png",         line1: "See how much",         line2: "you beat it by"),
    Shot(file: "4-records.png",         line1: "Every record",         line2: "you've ever set"),
    Shot(file: "5-calendar.png",        line1: "Every session,",       line2: "all in one place"),
]

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    guard let d = base.fontDescriptor.withDesign(.rounded) else { return base }
    return NSFont(descriptor: d, size: size) ?? base
}

let orange = NSColor(srgbRed: 1.0, green: 0.42, blue: 0.10, alpha: 1)
let bg = NSColor(srgbRed: 0x0B/255, green: 0x0B/255, blue: 0x0C/255, alpha: 1)

for (index, shot) in shots.enumerated() {
    guard let src = NSImage(contentsOfFile: "\(source)/\(shot.file)") else {
        print("missing \(shot.file)"); continue
    }

    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                               isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)!

    bg.setFill()
    NSRect(x: 0, y: 0, width: W, height: H).fill()

    // Warm wash behind the headline. Linear, not radial: a radial leaves the end colour at
    // the rect corners and produces a visible horizontal seam where the rect stops.
    // Ending at alpha 0 means the fade resolves into the background with no edge at all.
    let glow = NSGradient(starting: orange.withAlphaComponent(0.20),
                          ending: orange.withAlphaComponent(0.0))!
    glow.draw(in: NSRect(x: 0, y: CGFloat(H) - 1600, width: CGFloat(W), height: 1600), angle: -90)

    // Device capture, whole screen visible, sitting on the lower two-thirds.
    let shotW: CGFloat = 1080
    let scale = shotW / CGFloat(W)
    let shotH = CGFloat(H) * scale
    let shotRect = NSRect(x: (CGFloat(W) - shotW) / 2, y: 70, width: shotW, height: shotH)

    NSGraphicsContext.current?.saveGraphicsState()
    let clip = NSBezierPath(roundedRect: shotRect, xRadius: 46, yRadius: 46)
    clip.addClip()
    src.draw(in: shotRect)
    NSGraphicsContext.current?.restoreGraphicsState()

    // A brighter rim than you'd normally want, because dark screenshots on a dark canvas
    // otherwise lose their edge entirely and stop reading as a phone screen.
    NSColor.white.withAlphaComponent(0.30).setStroke()
    clip.lineWidth = 3
    clip.stroke()

    // Headline
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    para.lineSpacing = -14

    let text = NSMutableAttributedString()
    text.append(NSAttributedString(string: shot.line1 + "\n", attributes: [
        .font: roundedFont(104, .black),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para,
        .kern: -2.0,
    ]))
    text.append(NSAttributedString(string: shot.line2, attributes: [
        .font: roundedFont(104, .black),
        .foregroundColor: orange,
        .paragraphStyle: para,
        .kern: -2.0,
    ]))

    // Sits directly above the device with a deliberate but modest gap — the earlier layout
    // left a dead band of black between headline and phone.
    let textRect = NSRect(x: 70, y: shotRect.maxY + 34, width: CGFloat(W) - 140,
                          height: CGFloat(H) - shotRect.maxY - 130)
    text.draw(in: textRect)

    NSGraphicsContext.restoreGraphicsState()

    let name = String(format: "%d-%@", index + 1,
                      shot.file.replacingOccurrences(of: #"^\d+-"#, with: "",
                                                     options: .regularExpression))
    let data = rep.representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("  \(name)  \(shot.line1) \(shot.line2)")
}
