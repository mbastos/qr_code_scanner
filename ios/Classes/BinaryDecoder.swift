//
//  Mode.swift
//  qr_code_scanner
//
//  Created by Matheus Bastos on 01/08/21.
//

import Foundation

class BinaryDecoder {
    private let supportedModes: [Mode] = [.structuredAppend, .byte, .endOfMessage]
    private let symbolVersion: Int
    var bytes: [UInt8] = []
    
    init(symbolVersion: Int) {
        self.symbolVersion = symbolVersion
    }
  
    func decode(_ binary: inout Binary) {
        let modeBitsLength = 4
        guard binary.bitsWithInternalOffsetAvailable(modeBitsLength) else { return }

        let modeBits = binary.next(bits: modeBitsLength)
        guard let mode = Mode(rawValue: modeBits),
            supportedModes.contains(mode) else {
            return
        }

        guard mode != .endOfMessage else { return }

        if case .byte = mode {
            guard let numberOfBitsInLengthFiled = mode.numberOfBitsInLengthFiled(for: symbolVersion),
                let numberOfBitsPerCharacter = mode.numberOfBitsPerCharacter else { return }
            let totalCharacterCount = binary.next(bits: numberOfBitsInLengthFiled)
            for _ in 0..<totalCharacterCount {
                let byte = binary.next(bits: numberOfBitsPerCharacter)
                bytes.append(UInt8(byte))
            }
            
        }

        decode(&binary)
    }
}

enum SymbolType {
    case small
    case medium
    case large

    init?(version: Int) {
        if 1 <= version, version <= 9 {
            self = .small
        } else if 10 <= version, version <= 26 {
            self = .medium
        } else if 27 <= version, version <= 40 {
            self = .large
        } else {
            return nil
        }
    }
}

enum Mode: Int {
    case numeric              = 1
    case alphanumeric         = 2
    case byte                 = 4
    case kanji                = 8
    case structuredAppend     = 3
    case eci                  = 7
    case fnc1InFirstPosition  = 5
    case fnc1InSecondPosition = 9
    case endOfMessage         = 0
    var description: String {
        switch self {
        case .numeric:              return "0001"
        case .alphanumeric:         return "0010"
        case .byte:                 return "0100"
        case .kanji:                return "1000"
        case .structuredAppend:     return "0011"
        case .eci:                  return "0111"
        case .fnc1InFirstPosition:  return "0101"
        case .fnc1InSecondPosition: return "1001"
        case .endOfMessage:         return "0000"
        }
    }

    var hasNumberOfBitsInLengthFiled: Bool {
        switch self {
        case .numeric, .alphanumeric, .byte, .kanji:
            return true
        default:
            return false
        }
    }

    var numberOfBitsPerCharacter: Int? {
        switch self {
        case .numeric: return 10
        case .alphanumeric: return 11
        case .byte: return 8
        case .kanji: return 13
        default: return nil
        }
    }

    func numberOfBitsInLengthFiled(for symbolVersion: Int) -> Int? {
        guard let symbolType = SymbolType(version: symbolVersion) else { return nil }
        switch self {
        case .numeric:
            switch symbolType {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }

        case .alphanumeric:
            switch symbolType {
            case .small: return 9
            case .medium: return 11
            case .large: return 13
            }

        case .byte:
            switch symbolType {
            case .small: return 8
            case .medium: return 16
            case .large: return 16
            }

        case .kanji:
            switch symbolType {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }

        default:
            return nil
        }
    }
}
