// Generates AppIcon.icns and assets/logo.png for ClipStack.
// Run: swift make-icon.swift
// Design: indigo→violet rounded square, a stack of three clipboard sheets.
import AppKit

let canvas = 1024.0

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

let indigo = color(0x6B66F5)
let violet = color(0x7A29D6)
let clipTab = color(0x4338CA)

func rounded(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func render(_ px: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    cg.scaleBy(x: CGFloat(px) / canvas, y: CGFloat(px) / canvas)

    // Background: Apple icon grid — 824×824 rounded square centered on a 1024 canvas.
    let bg = rounded(CGRect(x: 100, y: 100, width: 824, height: 824), 185)
    cg.addPath(bg)
    cg.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: [indigo, violet] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(gradient, start: CGPoint(x: 180, y: 924),
                          end: CGPoint(x: 844, y: 100), options: [])

    // Sheet stack: two offset sheets behind, solid front sheet.
    let front = CGRect(x: 358, y: 200, width: 380, height: 470)
    for (offset, alpha) in [(72.0, 0.30), (36.0, 0.55)] {
        cg.setFillColor(color(0xFFFFFF, alpha))
        cg.addPath(rounded(front.offsetBy(dx: -offset, dy: offset), 48))
        cg.fillPath()
    }
    cg.setShadow(offset: CGSize(width: 0, height: -14), blur: 36, color: color(0x1E1B4B, 0.35))
    cg.setFillColor(color(0xFFFFFF))
    cg.addPath(rounded(front, 48))
    cg.fillPath()
    cg.setShadow(offset: .zero, blur: 0, color: nil)

    // Clipboard tab on the front sheet.
    cg.setFillColor(clipTab)
    cg.addPath(rounded(CGRect(x: front.midX - 75, y: front.maxY - 34, width: 150, height: 64), 22))
    cg.fillPath()

    // Three "text" bars.
    cg.setFillColor(color(0x7A29D6, 0.55))
    for (i, width) in [268.0, 268.0, 160.0].enumerated() {
        let y = front.maxY - 136 - CGFloat(i) * 86
        cg.addPath(rounded(CGRect(x: front.minX + 56, y: y, width: width, height: 38), 19))
        cg.fillPath()
    }

    ctx.flushGraphics()
    NSGraphicsContext.current = nil
    return rep
}

func writePNG(_ rep: NSBitmapImageRep, _ path: String) {
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

// Iconset (each size rendered natively, not downscaled), then icns.
let iconset = "AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    writePNG(render(size), "\(iconset)/icon_\(size)x\(size).png")
    writePNG(render(size * 2), "\(iconset)/icon_\(size)x\(size)@2x.png")
}
try! FileManager.default.createDirectory(atPath: "assets", withIntermediateDirectories: true)
writePNG(render(512), "assets/logo.png")

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset, "-o", "AppIcon.icns"]
try! iconutil.run()
iconutil.waitUntilExit()
guard iconutil.terminationStatus == 0 else { fatalError("iconutil failed") }
print("Wrote AppIcon.icns and assets/logo.png")
