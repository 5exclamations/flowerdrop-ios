import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// Убирает альфа-канал: иконка приложения обязана быть непрозрачной,
// иначе App Store отклонит сборку. rsvg-convert всегда пишет RGBA.

guard CommandLine.arguments.count > 1 else {
    FileHandle.standardError.write(Data("usage: flatten_png.swift <png>\n".utf8))
    exit(2)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path) as CFURL

guard
    let source = CGImageSourceCreateWithURL(url, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
else {
    FileHandle.standardError.write(Data("не читается: \(path)\n".utf8))
    exit(1)
}

guard
    let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )
else {
    FileHandle.standardError.write(Data("не создать контекст\n".utf8))
    exit(1)
}

// Подложка на случай полупрозрачных краёв — тот же кремовый фон плитки.
context.setFillColor(
    red: 0xFA / 255, green: 0xF7 / 255, blue: 0xF2 / 255, alpha: 1
)
context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

guard
    let flattened = context.makeImage(),
    let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
else {
    FileHandle.standardError.write(Data("не записать: \(path)\n".utf8))
    exit(1)
}

CGImageDestinationAddImage(destination, flattened, nil)
guard CGImageDestinationFinalize(destination) else { exit(1) }
