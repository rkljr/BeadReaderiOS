//
//  PatternLoade.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/28/25.
//

import Foundation
import SwiftUI

final class PatternLoader: NSObject, XMLParserDelegate {

    private var currentElement = ""
    
    private var patternName: String = ""
    private var rows: Int = 0
    private var columns: Int = 0
    private var beads: [Bead] = []
    
    private var currentBeadColor: String = ""
    private var currentBeadCount: Int = 0

    private var completion: ((Pattern?) -> Void)?
    
    func loadPattern(from url: URL, completion: @escaping (Pattern?) -> Void) {
        self.completion = completion
        let parser = XMLParser(contentsOf: url)
        parser?.delegate = self
        parser?.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "bead" {
            currentBeadColor = ""
            currentBeadCount = 0
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let value = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        
        switch currentElement {
        case "patternName": patternName += value
        case "rows": rows = Int(value) ?? 0
        case "columns": columns = Int(value) ?? 0
        case "color": currentBeadColor += value.lowercased()
        case "count": currentBeadCount = Int(value) ?? 0
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "bead" {
            let bead = Bead(id: beads.count, colorName: currentBeadColor, count: currentBeadCount)
            beads.append(bead)
        }
        
        if elementName == "pattern" {
            let pattern = Pattern(name: patternName, columns: columns, rows: rows, beads: beads)
            completion?(pattern)
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("XML parse error: \(parseError)")
        completion?(nil)
    }
}
