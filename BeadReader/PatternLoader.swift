//
//  PatternLoade.swift
//  BeadReader
//
//  Created by Richard Lincoln on 12/28/25.
//

import Foundation
import SwiftUI
import Compression

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
    
    func loadPNGPattern(from url: URL, completion: @escaping (Pattern?) -> Void) {
        self.completion = completion
        
        do {
            //print("reading pattern from PNG...")
            let xml = try readITXtChunk(from: url, keyword: "xbp")
            
            let parser = XMLParser(data: xml.data(using: .utf8)!)
            parser.delegate = self
            parser.parse()
            
        }
        catch {
            
        }
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
    
    //MARK: - Get Encoded XML from PNG file
    enum PNGMetadataError: Error {
        case invalidPNG
        case chunkNotFound
        case invalidUTF8
        case failedBaseAddressAssignment
        case decompressionFailed
        case invalidITXt
    }

    func readITXtChunk(from url: URL, keyword: String) throws -> String {
        let data = try Data(contentsOf: url)
        let bytes = [UInt8](data)

        // Validate PNG signature
        let signature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        guard bytes.starts(with: signature) else {
            throw PNGMetadataError.invalidPNG
        }

        var pos = 8 // after signature

        while pos + 8 <= bytes.count {
            // Read chunk length (big endian)
            let length = UInt32(bytes[pos]) << 24 |
                         UInt32(bytes[pos+1]) << 16 |
                         UInt32(bytes[pos+2]) << 8  |
                         UInt32(bytes[pos+3])

            let type = String(bytes: bytes[(pos+4)..<(pos+8)], encoding: .ascii) ?? ""

            if type == "iTXt" {
                let chunkStart = pos + 8
                let chunkEnd = chunkStart + Int(length)
                if chunkEnd > bytes.count { throw PNGMetadataError.invalidPNG }

                let chunkData = bytes[chunkStart..<chunkEnd]

                // Parse iTXt structure
                var index = 0

                // keyword (null-terminated)
                guard let keywordEnd = chunkData.firstIndex(of: 0) else {
                    throw PNGMetadataError.invalidITXt
                }
                
                let foundKeyword = String(bytes: chunkData[chunkData.startIndex..<keywordEnd], encoding: .ascii) ?? ""
                if foundKeyword == keyword {
                    index = keywordEnd + 1

                    let compressionFlag = chunkData[index]
                    index += 1

                    let compressionMethod = chunkData[index]
                    index += 1

                    // language tag (null-terminated)
                    guard let langEnd = chunkData[index...].firstIndex(of: 0) else {
                        throw PNGMetadataError.invalidITXt
                    }
                    index = langEnd + 1

                    // translated keyword (null-terminated)
                    guard let transEnd = chunkData[index...].firstIndex(of: 0) else {
                        throw PNGMetadataError.invalidITXt
                    }
                    index = transEnd + 1

                    // Remaining bytes = compressed text
                    let compressed = Data(chunkData[index...])
                    if compressionFlag == 1 && compressionMethod == 0 {
                        do {
                            // Gzip decompress
                            let xml = try decompressData(compressed)
//                            print("Decompressed XML length: \(xml.count)")
//                            print("Decompressed XML: \(xml.suffix(30))")
                            return xml
                        }
                        catch {
//                            print("Decompression failed: \(error)")
                            throw PNGMetadataError.decompressionFailed
                        }
                    } else {
                        throw PNGMetadataError.invalidITXt
                    }
                }
            }

            // Move to next chunk: length + type + data + crc
            pos += 8 + Int(length) + 4
        }

        throw PNGMetadataError.chunkNotFound
    }

    enum DecompressionError: Error {
        case failed
        case invalidUTF8
    }

    func decompressData(_ data: Data) throws -> String {

        // Detect gzip header
        let isGzip = data.prefix(2) == Data([0x1f, 0x8b])

        let srcData: Data
        if isGzip {
            guard data.count > 10 else { throw DecompressionError.failed }
            srcData = data.dropFirst(10)   // strip gzip header
        } else {
            srcData = data
        }

        // Allocate dummy pointers (required by API)
        let dummyDst = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        let dummySrc = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)

        var stream = compression_stream(
            dst_ptr: dummyDst,
            dst_size: 0,
            src_ptr: dummySrc,
            src_size: 0,
            state: nil
        )

        defer {
            dummyDst.deallocate()
            dummySrc.deallocate()
        }

        let status = compression_stream_init(&stream,
                                             COMPRESSION_STREAM_DECODE,
                                             COMPRESSION_ZLIB)
        guard status != COMPRESSION_STATUS_ERROR else {
            throw DecompressionError.failed
        }
        defer {
            compression_stream_destroy(&stream)
        }

        let bufferSize = 32_768
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            dstBuffer.deallocate()
        }

        var output = Data()

        try srcData.withUnsafeBytes { (srcPtr: UnsafeRawBufferPointer) in
            guard let srcBase = srcPtr.bindMemory(to: UInt8.self).baseAddress else {
                throw DecompressionError.failed
            }

            stream.src_ptr = srcBase
            stream.src_size = srcData.count
            stream.dst_ptr = dstBuffer
            stream.dst_size = bufferSize

            while true {
                let status = compression_stream_process(&stream, 0)

                let produced = bufferSize - stream.dst_size
                if produced > 0 {
                    output.append(dstBuffer, count: produced)
                }

                if status == COMPRESSION_STATUS_END {
                    break
                }

                if status == COMPRESSION_STATUS_ERROR {
                    throw DecompressionError.failed
                }

                stream.dst_ptr = dstBuffer
                stream.dst_size = bufferSize
            }
        }

        guard let result = String(data: output, encoding: .utf8) else {
            throw DecompressionError.invalidUTF8
        }

        return result
    }

}
