import Foundation

/// Inclusive private-key interval sampled at a positive integer stride.
public struct KeySearchRange: Sendable {
    public let minimum: U256
    public let maximum: U256
    public let step: UInt64
    public let keyCount: U256

    public init(minimum: U256, maximum: U256, step: UInt64) throws {
        guard !minimum.isZero, minimum < Fn.n, !maximum.isZero, maximum < Fn.n else {
            throw KeyRangeError.outsideScalarField
        }
        guard minimum <= maximum else { throw KeyRangeError.reversedBounds }
        guard step > 0 else { throw KeyRangeError.invalidStep }
        let delta = U256.subb(maximum, minimum).0
        let (q, _) = divModSmall(delta, step)
        let (count, carry) = U256.addSmall(q, 1)
        guard carry == 0 else { throw KeyRangeError.rangeTooWide }
        self.minimum = minimum
        self.maximum = maximum
        self.step = step
        self.keyCount = count
    }

    public static func parse(minimum: String, maximum: String, step: String) throws -> KeySearchRange {
        guard let lo = U256(hex: minimum.trimmingCharacters(in: .whitespacesAndNewlines)),
              let hi = U256(hex: maximum.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw KeyRangeError.invalidHex
        }
        let raw = step.trimmingCharacters(in: .whitespacesAndNewlines)
        let radix = raw.lowercased().hasPrefix("0x") ? 16 : 10
        let digits = radix == 16 ? String(raw.dropFirst(2)) : raw
        guard !digits.isEmpty, let amount = UInt64(digits, radix: radix), amount > 0 else {
            throw KeyRangeError.invalidStep
        }
        return try KeySearchRange(minimum: lo, maximum: hi, step: amount)
    }
}

public enum KeyRangeError: LocalizedError {
    case invalidHex, invalidStep, reversedBounds, outsideScalarField, rangeTooWide
    public var errorDescription: String? {
        switch self {
        case .invalidHex: return "Enter minimum and maximum as hexadecimal private keys."
        case .invalidStep: return "Step must be a positive integer (decimal or 0x-prefixed hexadecimal)."
        case .reversedBounds: return "Minimum key must not exceed maximum key."
        case .outsideScalarField: return "Keys must be between 1 and secp256k1 order minus 1."
        case .rangeTooWide: return "The selected range is too wide to represent."
        }
    }
}
