// Renders Design/AppIcon.svg into the PNG sizes the asset catalog needs.
// Usage: swift Scripts/render-app-icon.swift Design/AppIcon.svg Doppio/Assets.xcassets/AppIcon.appiconset
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    FileHandle.standardError.write(Data("usage: render-app-icon.swift <svg> <appiconset directory>\n".utf8))
    exit(1)
}
let outputDirectory = URL(fileURLWithPath: arguments[2])
guard let image = NSImage(contentsOf: URL(fileURLWithPath: arguments[1])) else {
    FileHandle.standardError.write(Data("could not read \(arguments[1])\n".utf8))
    exit(1)
}

for pixels in [16, 32, 64, 128, 256, 512, 1024] {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { exit(1) }
    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
    try png.write(to: outputDirectory.appendingPathComponent("icon_\(pixels).png"))
}
