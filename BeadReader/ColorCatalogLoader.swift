//
//  ColorCatalogLoader.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/26/25.
//

import Foundation
import SwiftUI

final class ColorCatalogLoader: NSObject, XMLParserDelegate {

    private var colors: [String: UIColor] = [:]

    private var currentElement: String = ""
    private var currentName: String = ""
    private var currentValue: String = ""

    func loadColors(from filename: String) -> [String: UIColor] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "xml"),
              let parser = XMLParser(contentsOf: url) else {
            print("❌ Failed to load \(filename).xml")
            return [:]
        }

        parser.delegate = self
        parser.parse()

        return colors
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        currentElement = elementName
        if elementName == "color" {
            currentName = ""
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "name":
            currentName += trimmed
//            print("loaded color: \(currentName)")
        case "value":
            currentValue += trimmed
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "color" {
            if let color = UIColor(hex: currentValue) {
                colors[currentName.lowercased()] = color
//                print("loaded color: \(currentName)")
//                print("colors.count: \(colors.count)")
            }
        }
        currentElement = ""
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexColor = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if hexColor.hasPrefix("#") {
            hexColor.removeFirst()
        }

        var hexNumber: UInt64 = 0
        guard Scanner(string: hexColor).scanHexInt64(&hexNumber) else {
            return nil
        }

        let r, g, b, a: CGFloat

        switch hexColor.count {
        case 6: // RRGGBB
            r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00FF00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000FF) / 255
            a = 1.0

        case 8: // RRGGBBAA
            r = CGFloat((hexNumber & 0xFF000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00FF0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000FF00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000FF) / 255

        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}


@MainActor
final class ColorCatalog: ObservableObject {
    static let shared = ColorCatalog()

    @Published private(set) var colors: [String: UIColor] = [:]

    private init() {
        load()
    }

    private func load() {
        let loader = ColorCatalogLoader()
        colors = loader.loadColors(from: "beadColors")
//        print("Loaded colors:", colors.keys)
    }
    
    func color(for name: String) -> Color {
        Color(colors[name.lowercased()] ?? .gray)
    }

}

