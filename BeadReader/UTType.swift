//
//  UTType.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/29/25.
//

import UniformTypeIdentifiers

extension UTType {
    static let beadPattern = UTType(
        exportedAs: "Apricity.BeadReader.pattern",
        conformingTo: .xml
    )
}
