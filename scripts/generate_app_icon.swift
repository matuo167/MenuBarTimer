import AppKit
import Foundation

struct IconSlot {
    let pointSize: Int
    let scale: Int

    var pixelSize: Int {
        pointSize * scale
    }

    var fileName: String {
        scale == 1 ? "icon_\(pointSize)x\(pointSize).png" : "icon_\(pointSize)x\(pointSize)@2x.png"
    }
}

let slots = [
    IconSlot(pointSize: 16, scale: 1),
    IconSlot(pointSize: 16, scale: 2),
    IconSlot(pointSize: 32, scale: 1),
    IconSlot(pointSize: 32, scale: 2),
    IconSlot(pointSize: 128, scale: 1),
    IconSlot(pointSize: 128, scale: 2),
    IconSlot(pointSize: 256, scale: 1),
    IconSlot(pointSize: 256, scale: 2),
    IconSlot(pointSize: 512, scale: 1),
    IconSlot(pointSize: 512, scale: 2)
]

let fileManager = FileManager.default
let projectURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let assetsURL = projectURL.appendingPathComponent("assets", isDirectory: true)
let iconsetURL = assetsURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = assetsURL.appendingPathComponent("AppIcon.icns")

try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for slot in slots {
    let image = drawIcon(pixelSize: slot.pixelSize)
    let destinationURL = iconsetURL.appendingPathComponent(slot.fileName)
    try writePNG(image, to: destinationURL)
}

if fileManager.fileExists(atPath: icnsURL.path) {
    try fileManager.removeItem(at: icnsURL)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    throw NSError(
        domain: "MenuBarTimer.IconGeneration",
        code: Int(process.terminationStatus),
        userInfo: [NSLocalizedDescriptionKey: "iconutil failed with status \(process.terminationStatus)"]
    )
}

print("Generated \(icnsURL.path)")

func drawIcon(pixelSize: Int) -> NSImage {
    let size = CGFloat(pixelSize)
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high

    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let backgroundPath = NSBezierPath(roundedRect: canvas.insetBy(dx: size * 0.035, dy: size * 0.035), xRadius: cornerRadius, yRadius: cornerRadius)

    let shadow = NSShadow()
    shadow.shadowBlurRadius = size * 0.06
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.02)
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.set()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.08, green: 0.72, blue: 0.88, alpha: 1.0),
        NSColor(calibratedRed: 0.18, green: 0.30, blue: 0.86, alpha: 1.0)
    ])
    gradient?.draw(in: backgroundPath, angle: -35)

    NSShadow().set()

    NSColor.white.withAlphaComponent(0.28).setStroke()
    backgroundPath.lineWidth = max(1.0, size * 0.012)
    backgroundPath.stroke()

    let faceInset = size * 0.22
    let faceRect = canvas.insetBy(dx: faceInset, dy: faceInset)
    let facePath = NSBezierPath(ovalIn: faceRect)

    NSColor.white.withAlphaComponent(0.88).setFill()
    facePath.fill()

    NSColor(calibratedRed: 0.07, green: 0.22, blue: 0.46, alpha: 0.68).setStroke()
    facePath.lineWidth = max(1.2, size * 0.018)
    facePath.stroke()

    let center = NSPoint(x: size * 0.5, y: size * 0.5)
    let tickRadius = size * 0.225
    let tickLength = size * 0.032

    NSColor(calibratedRed: 0.06, green: 0.18, blue: 0.36, alpha: 0.72).setStroke()
    for index in 0..<12 {
        let angle = (CGFloat(index) / 12.0) * .pi * 2.0
        let outer = NSPoint(
            x: center.x + sin(angle) * tickRadius,
            y: center.y + cos(angle) * tickRadius
        )
        let inner = NSPoint(
            x: center.x + sin(angle) * (tickRadius - tickLength),
            y: center.y + cos(angle) * (tickRadius - tickLength)
        )
        let tickPath = NSBezierPath()
        tickPath.move(to: inner)
        tickPath.line(to: outer)
        tickPath.lineWidth = index % 3 == 0 ? max(1.5, size * 0.012) : max(1.0, size * 0.007)
        tickPath.stroke()
    }

    let hourHand = NSBezierPath()
    hourHand.move(to: center)
    hourHand.line(to: NSPoint(x: center.x - size * 0.07, y: center.y + size * 0.105))
    hourHand.lineCapStyle = .round
    hourHand.lineWidth = max(2.2, size * 0.028)
    NSColor(calibratedRed: 0.05, green: 0.16, blue: 0.35, alpha: 1.0).setStroke()
    hourHand.stroke()

    let minuteHand = NSBezierPath()
    minuteHand.move(to: center)
    minuteHand.line(to: NSPoint(x: center.x + size * 0.13, y: center.y + size * 0.02))
    minuteHand.lineCapStyle = .round
    minuteHand.lineWidth = max(2.0, size * 0.022)
    minuteHand.stroke()

    NSColor(calibratedRed: 0.0, green: 0.58, blue: 0.78, alpha: 1.0).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - size * 0.035, y: center.y - size * 0.035, width: size * 0.07, height: size * 0.07)).fill()

    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(
            domain: "MenuBarTimer.IconGeneration",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG for \(url.lastPathComponent)"]
        )
    }

    try pngData.write(to: url)
}
