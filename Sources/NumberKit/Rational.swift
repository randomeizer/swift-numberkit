//
//  Rational.swift
//  NumberKit
//
//  Created by Matthias Zenger on 04/08/2015.
//  Copyright © 2015-2020 Matthias Zenger. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,x either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

// There are many places in this package where overflow can cause incorrect
// results. TODO: Eliminate these bugs!

/// The `RationalNumber` protocol defines an interface for rational numbers. A rational
/// number is a signed number that can be expressed as the quotient of two integers
/// a and b: a / b. a is called the numerator, b is called the denominator. b must
/// not be zero.
public protocol RationalNumber: SignedNumeric,
                                  Comparable,
                                  Hashable,
                                  CustomStringConvertible {
  
  /// The integer type on which this rational number is based.
    associatedtype Integer: IntegerNumber

    /// The numerator of this rational number.
    var numerator: Integer { get }

    /// The denominator of this rational number.
    var denominator: Integer { get }

    /// Returns the `Rational` as a value of type `Integer` if this is possible. If the number
    /// cannot be expressed as a `Integer`, this property returns `nil`.
    var intValue: Integer? { get }

    /// Returns the `Rational` value as a float value
    var floatValue: Float { get }

    /// Returns the `Rational` value as a double value
    var doubleValue: Double { get }

    /// Is true if the rational value is negative.
    var isNegative: Bool { get }

    /// Is true if the rational value is zero.
    var isZero: Bool { get }

    /// The normalized/simplfied form of the rational value. For example, the normalized form
    /// of 2/4 is 1/2.
    var normalized: Self { get }

    /// The absolute rational value (without sign).
    var abs: Self { get }

    /// The negated rational value.
    var negate: Self { get }

    /// Returns -1 if `self` is less than `rhs`,
    ///          0 if `self` is equals to `rhs`,
    ///         +1 if `self` is greater than `rhs`
    func compare(to rhs: Self) -> Int

    /// Returns the sum of this rational value and `rhs`.
    func plus(_ rhs: Self) -> Self

    /// Returns the difference between this rational value and `rhs`.
    func minus(_ rhs: Self) -> Self

    /// Multiplies this rational value with `rhs` and returns the result.
    func times(_ rhs: Self) -> Self

    /// Divides this rational value by `rhs` and returns the result.
    func divided(by rhs: Self) -> Self

    /// Calculate the remainder of dividing `self` by `rhs` and return the result.
    func remainder(dividingBy rhs: Self) -> Self

    /// Calculate the quotient and remainder of dividing `self` by `rhs` and return a tupple
    /// consisting of the quotient (as an `Integer`) and remainder (as `Self`).
    func quotientAndRemainder(dividingBy rhs: Self) -> (quotient: Integer, remainder: Self)

    /// Raises this rational value to the power of `exp`.
    func toPower(of exp: Integer) -> Self

    /// Normalizes/simplifies the rational value and reports the result together with a boolean indicating an overflow.
    func normalizedReportingOverflow() -> (partialValue: Self, overflow: Bool)

    /// Adds `rhs` to `self` and reports the result together with a boolean indicating an overflow.
    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool)

    /// Subtracts `rhs` from `self` and reports the result together with a boolean indicating
    /// an overflow.
    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool)

    /// Multiplies `rhs` with `self` and reports the result together with a boolean indicating
    /// an overflow.
    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool)

    /// Divides `self` by `rhs` and reports the result together with a boolean indicating
    /// an overflow.
    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool)

    /// Calculates the remainder of dividing `self` by `rhs` and reports the result together
    /// with a boolean indicating an overflow.
    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool)

    /// Calculate the quotient and remainder of dividing `self` by `rhs` and return a tuple consisting
    /// of the quotient, the remainder, and a boolean which indicates whether there was an overflow.
    func quotientAndRemainderReportingOverflow(dividingBy rhs: Self)
        -> (quotient: Integer, remainder: Self, overflow: Bool)

    /// Returns the greatest common denominator for `self` and `y` and a boolean which indicates
    /// whether there was an overflow.
    func gcdReportingOverflow(with y: Self) -> (partialValue: Self, overflow: Bool)

    /// Returns the least common multiplier for `self` and `y` and a boolean which indicates
    /// whether there was an overflow.
    func lcmReportingOverflow(with y: Self) -> (partialValue: Self, overflow: Bool)

    /// Initializes the rational number with the given numerator and denominator.
    init(_ numerator: Integer, _ denominator: Integer)

    /// Initializes the rational number with a whole number, resulting in a denominator of `1`.
    init(_ value: Integer)
}

/// Struct `Rational<T>` implements the `RationalNumber` interface on top of the
/// integer type `T`. `Rational<T>` always represents rational numbers in normalized
/// form such that the greatest common divisor of the numerator and the denominator
/// is always 1. In addition, the sign of the rational number is defined by the
/// numerator. The denominator is always positive.
public struct Rational<T: IntegerNumber>: RationalNumber, CustomStringConvertible {
  /// The numerator of this rational number. This is a signed integer.
  public let numerator: T

    /// The denominator of this rational number. This integer is always positive.
    public let denominator: T

    /// Sets numerator and denominator without normalization. This function must not be called
    /// outside of the NumberKit framework.
    private init(numerator: T, denominator: T) {
        self.numerator = numerator
        self.denominator = denominator
    }

    /// Creates a rational number from a given numerator and denominator, ignoring overflow;
    /// it creates an incorrect result if the correct result is not expressible in the given type.
    public init(_ numerator: T, _ denominator: T) {
        precondition(denominator != 0, "rational with zero denominator")
        self = Rational.rationalWithOverflow(numerator, denominator).0 // Ignore overflow
    }

    /// Creates a `Rational` from the given integer value of type `T`
    public init(_ value: T) {
        self.init(numerator: value, denominator: T.one)
    }

    /// Creates a rational number by rationalizing a `Double` value.
    public init(_ value: Double, precision: Double = 1.0e-8) {
        var x = value
        var a = Foundation.floor(x)
        var (h1, k1, h, k) = (T.one, T.zero, T(a), T.one)
        while x - a > precision * k.doubleValue * k.doubleValue {
            x = 1.0 / (x - a)
            a = Foundation.floor(x)
            (h1, k1, h, k) = (h, k, h1 + T(a) * h, k1 + T(a) * k)
        }
        self.init(numerator: h, denominator: k)
    }

    /// Create an instance initialized to `value`.
    public init(integerLiteral value: Int64) {
        self.init(T(value))
    }

    public init?<S: BinaryInteger>(exactly source: S) {
        if let numerator = T(exactly: source) {
            self.init(numerator)
        } else {
            return nil
        }
    }

    /// Creates a `Rational` from a string containing a rational number using the base
    /// defined by parameter `radix`. The syntax of the rational number is defined as follows:
    ///
    ///    Rational    = Numerator '/' Denominator
    ///                | SignedInteger
    ///    Numerator   = SignedInteger
    ///    Denominator = SignedInteger
    public init?(from str: String, radix: Int = 10) {
        precondition(radix >= 2, "radix >= 2 required")
        if let idx = str.firstIndex(of: rationalSeparator) {
            if let numVal = Int64(str[..<idx], radix: radix),
               let denomVal = Int64(str[str.index(after: idx)...], radix: radix) {
                self.init(T(numVal), T(denomVal))
            } else {
                return nil
            }
        } else if let value = Int64(str, radix: radix) {
            self.init(T(value))
        } else {
            return nil
        }
    }

    /// Returns the `Rational` as a value of type `T` if this is possible. If the number
    /// cannot be expressed as a `T`, this property returns `nil`.
    public var intValue: T? {
        let normalized = self.normalized
        guard normalized.denominator == T.one else {
            return nil
        }
        return normalized.numerator
    }

    /// Returns the `Rational` value as a float value
    public var floatValue: Float {
        return Float(doubleValue)
    }

    /// Returns the `Rational` value as a double value
    public var doubleValue: Double {
        return numerator.doubleValue / denominator.doubleValue
    }

    /// Returns a string representation of this `Rational<T>` number using base 10.
    public var description: String {
        return denominator == 1 || numerator == 0
            ? numerator.description
            : numerator.description + String(rationalSeparator) + denominator.description
    }

    /// Returns the (non-negative) Greatest Common Divisor (GCD) of two `T: IntegerNumber`
    /// values `x` and `y`. Any overflow occurring during the gcd( is ignored.
    @available(*, deprecated, message: "moved to IntegerNumber.gcd")
    public static func gcd(_ x: T, _ y: T) -> T { T.gcd(x, y) }

    /// Compute the (non-negative) Least Common Multiple (LCM) of two `T: IntegerNumber`
    /// values `x` and `y`. Any overflow during the computation is ignored.
    @available(*, deprecated, message: "moved to IntegerNumber.lcm")
    public static func lcm(_ x: T, _ y: T) -> T { T.lcm(x, y) }

    /// Given two rational values `this` and `that`, return the two equivalent (but possibly
    /// not normalized) values `num0 / denom` and `num1 / denom`, where `denom` is the LCM of
    /// the two denominators. In case of overflow, the wrong result may be returned.
    private func commonDenomWith(_ other: Rational<T>) -> (num0: T, num1: T, denom: T) {
        let (num0, num1, denom, _) = Rational.commonDenomWithOverflow(self, other) // Ignore overflow.
        return (num0, num1, denom)
    }

    /// For hashing values.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(numerator)
        hasher.combine(denominator)
    }

    /// The normalized/simplfied form of the rational value.
    public var normalized: Rational<T> {
        let anum = numerator < 0 ? -numerator : numerator
        let div = T.gcd(anum, denominator)
        return Rational<T>(numerator / div, denominator / div)
    }

    /// The absolute rational value (without sign).
    public var abs: Rational<T> {
        return magnitude
    }

    /// The magnitude of the rational value.
    public var magnitude: Rational<T> {
        return Rational(numerator < 0 ? -numerator : numerator, denominator)
    }

    /// The negated rational value.
    public var negate: Rational<T> {
        return Rational(-numerator, denominator)
    }

    /// Is true if the rational value is negative.
    public var isNegative: Bool {
        return numerator < 0
    }

    /// Is true if the rational value is zero.
    public var isZero: Bool {
        return numerator == 0
    }

    /// Returns -1 if `self` is less than `rhs`,
    ///          0 if `self` is equals to `rhs`,
    ///         +1 if `self` is greater than `rhs`
    public func compare(to rhs: Rational<T>) -> Int {
        let (n1, n2, _) = commonDenomWith(rhs)
        return n1 == n2 ? 0 : (n1 < n2 ? -1 : 1)
    }

    /// Returns the sum of this rational value and `rhs`.
    public func plus(_ rhs: Rational<T>) -> Rational<T> {
        let (n1, n2, denom) = commonDenomWith(rhs)
        return Rational(n1 + n2, denom)
    }

    /// Returns the difference between this rational value and `rhs`.
    public func minus(_ rhs: Rational<T>) -> Rational<T> {
        let (n1, n2, denom) = commonDenomWith(rhs)
        return Rational(n1 - n2, denom)
    }

    /// Multiplies this rational value with `rhs` and returns the result.
    public func times(_ rhs: Rational<T>) -> Rational<T> {
        let lhs = normalized
        let rhs = rhs.normalized

        let gcd1 = T.gcd(lhs.numerator, rhs.denominator)
        let gcd2 = T.gcd(rhs.numerator, lhs.denominator)

        let newNumerator = (lhs.numerator / gcd1) * (rhs.numerator / gcd2)
        let newDenominator = (lhs.denominator / gcd2) * (rhs.denominator / gcd1)

        return Rational(newNumerator, newDenominator).normalized
    }

    /// Divides this rational value by `rhs` and returns the result.
    public func divided(by rhs: Rational<T>) -> Rational<T> {
        let lhs = normalized
        let rhs = rhs.normalized

        let gcd1 = T.gcd(lhs.numerator, rhs.numerator)
        let gcd2 = T.gcd(rhs.denominator, lhs.denominator)

        let newNumerator = (lhs.numerator / gcd1) * (rhs.denominator / gcd2)
        let newDenominator = (lhs.denominator / gcd2) * (rhs.numerator / gcd1)

        return Rational(newNumerator, newDenominator).normalized
    }

    /// Calculate the remainder of dividing `self` by `rhs` and return the result.
    public func remainder(dividingBy rhs: Rational<T>) -> Rational<T> {
        let (n1, n2, denom) = commonDenomWith(rhs)
        return Rational(n1 % n2, denom)
    }

    /// Calculate the quotient and remainder of dividing `self` by `rhs` and return a tupple
    /// consisting of the quotient (as an `Integer`) and remainder (as `Self`).
    public func quotientAndRemainder(dividingBy rhs: Rational<T>) -> (
        quotient: T, remainder: Rational<T>
    ) {
        let (n1, n2, denom) = commonDenomWith(rhs)
        // The quotient should be the result of the division of the numerators
        let quotient = n1 / n2
        // The remainder should be the result of the modulo operation of the numerators
        let remainder = Rational(n1 % n2, denom)
        return (quotient, remainder)
    }

    /// Raises this rational value to the power of `exp`.
    public func toPower(of exp: T) -> Rational<T> {
        if exp < 0 {
            return Rational(denominator.toPower(of: -exp), numerator.toPower(of: -exp))
        } else {
            return Rational(numerator.toPower(of: exp), denominator.toPower(of: exp))
        }
    }

    /// Returns the greatest common denominator (GCD) of the two given rational numbers, ignoring
    /// overflow; it may return an incorrect result if overflow occurs during the computation.
    public static func gcd(_ x: Rational<T>, _ y: Rational<T>) -> Rational<T> {
        return Rational(T.gcd(x.numerator, y.numerator), T.lcm(x.denominator, y.denominator))
    }

    /// Returns the least common multiple (LCM) of the two given rational numbers, ignoring
    /// overflow; it may return an incorrect result if overflow occurs during the computation.
    public static func lcm(_ x: Rational<T>, _ y: Rational<T>) -> Rational<T> {
        let (xn, yn, denom) = x.commonDenomWith(y)
        return Rational(T.lcm(xn, yn), denom)
    }
}

/// This extension implements the boilerplate to make `Rational` compatible
/// to the applicable Swift 4 protocols. `Rational` is convertible from Strings and
/// implements basic arithmetic operations which keep track of overflows.
extension Rational: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if let rat = Rational(from: value) {
            self.init(numerator: rat.numerator, denominator: rat.denominator)
        } else {
            self.init(0)
        }
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }

    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }

    /// Creates the normalized/simplified form of the rational value, reporting the result and a boolean indicating overflow.
    public func normalizedReportingOverflow() -> (partialValue: Self, overflow: Bool) {
        let (anum, overflow1) = Rational.absWithOverflow(numerator)
        let (div, overflow2) = T.gcdWithOverflow(anum, denominator)
        let (num, overflow3) = numerator.dividedReportingOverflow(by: div)
        let (denom, overflow4) = denominator.dividedReportingOverflow(by: div)
        return (Rational<T>(num, denom), overflow1 || overflow2 || overflow3 || overflow4)
    }

    /// Compute absolute number of `num` and return a tuple consisting of the result and a
    /// boolean indicating whether there was an overflow.
    private static func absWithOverflow(_ num: T) -> (value: T, overflow: Bool) {
        return num < 0 ? T.zero.subtractingReportingOverflow(num) : (num, false)
    }

    /// Creates a normalized rational number from a given numerator and denominator, along with a Boolean
    /// indicating whether overflow occurred in the operation, if the correct value is not
    /// representable in the given type.
    public static func normalizedWithOverflow(_ numerator: T, _ denominator: T) -> (
        value: Rational<T>, overflow: Bool
    ) {
        guard denominator != 0 else {
            return (0, true)
        }
        // Eliminate special cases early that might otherwise report overflow.
        if denominator == 1 {
            return (Rational(numerator), false)
        } else if numerator == 0 {
            return (0, false)
        } else if numerator == denominator {
            return (1, false)
        }
        // Numerator and denominator are now both non-zero.
        let (gcd, gcdOverflow) = T.gcdWithOverflow(numerator, denominator) // Safe: numerator != denominator.
        let normalizedNumerator = numerator / gcd // Safe: gcd is positive and divides numerator.
        let normalizedDenominator = denominator / gcd // Safe: gcd is positive and divides denominator.
        // Overflows if numerator == T.min and denominator is odd.
        let (absNumerator, numeratorOverflow) = T.absWithOverflow(normalizedNumerator)
        // Overflows if denominator == T.min and numerator is odd.
        let (absDenominator, denominatorOverflow) = T.absWithOverflow(normalizedDenominator)
        // The rational value `absNumerator / absDenominator` is already normalized.
        let resultNumerator = (numerator > 0) == (denominator > 0) ? absNumerator : -absNumerator
        let resultOverflow = gcdOverflow || numeratorOverflow || denominatorOverflow
        return (Rational(numerator: resultNumerator, denominator: absDenominator), resultOverflow)
    }

    /// Creates a rational number from a given numerator and denominator, along with a Boolean
    /// indicating whether overflow occurred in the operation, if the correct value is not
    /// representable in the given type.
    /// - Parameters:
    ///   - numerator: The numerator.
    ///   - denominator: The denominator.
    /// - Returns: a `value` and a `overflow` boolean, indicating whether overflow occurred.
    /// - Note: The result is not normalized. Use `normalizedWithOverflow` to get a normalized result.
    public static func rationalWithOverflow(_ numerator: T, _ denominator: T) -> (
        value: Rational<T>, overflow: Bool
    ) {
        guard denominator != 0 else {
            return (0, true)
        }
        // Eliminate special cases early that might otherwise report overflow.
        if denominator == 1 {
            return (Rational(numerator), false)
        } else if numerator == 0 {
            return (0, false)
        } else if numerator == denominator {
            return (1, false)
        }
        // Numerator and denominator are now both non-zero.
        // Overflows if numerator == T.min and denominator is odd.
        let (absNumerator, numeratorOverflow) = T.absWithOverflow(numerator)
        // Overflows if denominator == T.min and numerator is odd.
        let (absDenominator, denominatorOverflow) = T.absWithOverflow(denominator)
        let resultNumerator = (numerator > 0) == (denominator > 0) ? absNumerator : -absNumerator
        let resultOverflow = numeratorOverflow || denominatorOverflow
        return (Rational(numerator: resultNumerator, denominator: absDenominator), resultOverflow)
    }

    /// Given two rational values `this` and `that`, return the two equivalent (but possibly not
    /// normalized) values `num0 / denom` and `num1 / denom`, where `denom` is the LCM is the two
    /// denominators, together with a Boolean indicating whether overflow occurred during the
    /// computation, if the result cannot be represented in this type.
    private static func commonDenomWithOverflow(_ this: Rational<T>, _ that: Rational<T>) -> (
        num0: T, num1: T, denom: T, overflow: Bool
    ) {
        let this = this.normalized, that = that.normalized
        
        let (lcmOfDenominators, lcmOverflow) = T.lcmWithOverflow(this.denominator, that.denominator)
        if lcmOverflow {
            return (0, 0, 0, true) // Early return on LCM overflow
        }

        // Calculate num0 safely
        let gcdThis = T.gcd(this.denominator, lcmOfDenominators)
        let scaledDenomThis = lcmOfDenominators / gcdThis
        let (scaledNumeratorThis, scaleNumThisOverflow) = this.numerator.multipliedReportingOverflow(by: scaledDenomThis)
        let (num0, num0Overflow) = scaledNumeratorThis.dividedReportingOverflow(by: this.denominator / gcdThis)

        // Calculate num1 safely
        let gcdThat = T.gcd(that.denominator, lcmOfDenominators)
        let scaledDenomThat = lcmOfDenominators / gcdThat
        let (scaledNumeratorThat, scaleNumThatOverflow) = that.numerator.multipliedReportingOverflow(by: scaledDenomThat)
        let (num1, num1Overflow) = scaledNumeratorThat.dividedReportingOverflow(by: that.denominator / gcdThat)

        // Final overflow check
        let totalOverflow = lcmOverflow || num0Overflow || num1Overflow || scaleNumThisOverflow || scaleNumThatOverflow

        return (num0, num1, lcmOfDenominators, totalOverflow)
    }


    /// Returns the (non-negative) Greatest Common Divisor (GCD) of two `T: IntegerNumber`
    /// values `x` and `y`, together with a Boolean indicating whether overflow occurred
    /// during the computation, in which case the result may be wrong.
    @available(*, deprecated, message: "moved to IntegerNumber.gcdWithOverflow")
    public static func gcdWithOverflow(_ x: T, _ y: T) -> (T, Bool) {
        return T.gcdWithOverflow(x, y)
    }

    /// Returns the (non-negative) Least Common Multiple (LCM) of two `T: IntegerNumber`
    /// values `x` and `y`, together with a Boolean indicating whether overflow occurred
    /// during the computation, in which case the result may be wrong.
    @available(*, deprecated, message: "moved to IntegerNumber.lcmWithOverflow")
    public static func lcmWithOverflow(_ x: T, _ y: T) -> (T, Bool) {
        return T.lcmWithOverflow(x, y)
    }

    /// Add `self` and `rhs` and return a tuple consisting of the result and a boolean which
    /// indicates whether there was an overflow.
    public func addingReportingOverflow(_ rhs: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        let (n1, n2, denom, overflow1) = Rational.commonDenomWithOverflow(self, rhs)
        let (numer, overflow2) = n1.addingReportingOverflow(n2)
        let (res, overflow3) = Rational.rationalWithOverflow(numer, denom)
        return (res, overflow1 || overflow2 || overflow3)
    }

    /// Subtract `rhs` from `self` and return a tuple consisting of the result and a boolean which
    /// indicates whether there was an overflow.
    public func subtractingReportingOverflow(_ rhs: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        let (n1, n2, denom, overflow1) = Rational.commonDenomWithOverflow(self, rhs)
        let (numer, overflow2) = n1.subtractingReportingOverflow(n2)
        let (res, overflow3) = Rational.rationalWithOverflow(numer, denom)
        return (res, overflow1 || overflow2 || overflow3)
    }

    /// Multiply `self` and `rhs` and return a tuple consisting of the result and a boolean which
    /// indicates whether there was an overflow.
    public func multipliedReportingOverflow(by rhs: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        // Normalize both values first, then multiply the numerators and denominators.
        let selfNormalized = normalized
        let rhsNormalized = rhs.normalized
        let (numer, overflow1) = selfNormalized.numerator.multipliedReportingOverflow(
            by: rhsNormalized.numerator)
        let (denom, overflow2) = selfNormalized.denominator.multipliedReportingOverflow(
            by: rhsNormalized.denominator)
        let (res, overflow3) = Rational.rationalWithOverflow(numer, denom)
        return (res, overflow1 || overflow2 || overflow3)
    }

    /// Divide `lhs` by `rhs` and return a tuple consisting of the result and a boolean which
    /// indicates whether there was an overflow.
    public func dividedReportingOverflow(by rhs: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        // Normalize both values first, then multiply the numerators and denominators.
        let selfNormalized = normalized
        let rhsNormalized = rhs.normalized

        let (numer, overflow1) = selfNormalized.numerator.multipliedReportingOverflow(
            by: rhsNormalized.denominator)
        let (denom, overflow2) = selfNormalized.denominator.multipliedReportingOverflow(
            by: rhsNormalized.numerator)
        let (res, overflow3) = Rational.rationalWithOverflow(numer, denom)
        return (res, overflow1 || overflow2 || overflow3)
    }

    /// Calculate the remainder of dividing `self` by `rhs` and return a tuple consisting of the result
    /// and a boolean which indicates whether there was an overflow.
    public func remainderReportingOverflow(dividingBy rhs: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        // Bring both Rational numbers to a common denominator and check for overflow
        let (n1, n2, denom, overflow1) = Rational.commonDenomWithOverflow(self, rhs)

        // Calculate the remainder of the numerators and check for overflow
        let (numer, overflow2) = n1.remainderReportingOverflow(dividingBy: n2)

        // Create a new Rational number with the remainder and check for overflow
        let (res, overflow3) = Rational.rationalWithOverflow(numer, denom)

        // Return the result and the overflow status
        return (res, overflow1 || overflow2 || overflow3)
    }

    /// Calculate the quotient and remainder of dividing `self` by `rhs` and return a tuple consisting
    /// of the quotient, the remainder, and a boolean which indicates whether there was an overflow.
    public func quotientAndRemainderReportingOverflow(dividingBy rhs: Rational<T>)
        -> (quotient: T, remainder: Rational<T>, overflow: Bool) {
        // Bring both Rational numbers to a common denominator and check for overflow
        let (n1, n2, denom, overflow1) = Rational.commonDenomWithOverflow(self, rhs)

        // Calculate the quotient of the numerators and check for overflow
        let (quotient, overflow2) = n1.dividedReportingOverflow(by: n2)

        // Calculate the remainder of the numerators and check for overflow
        let (numerRemainder, overflow3) = n1.remainderReportingOverflow(dividingBy: n2)

        // Create a new Rational number with the remainder and check for overflow
        let (remainderRational, overflow4) = Rational.rationalWithOverflow(numerRemainder, denom)

        // Return the quotient, remainder, and the overflow status
        return (
            quotient: quotient, remainder: remainderRational,
            overflow: overflow1 || overflow2 || overflow3 || overflow4
        )
    }

    /// Returns the greatest common denominator for `self` and `y` and a boolean which indicates
    /// whether there was an overflow.
    public func gcdReportingOverflow(with y: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        let (numer, overflow1) = T.gcdWithOverflow(numerator, y.numerator)
        let (denom, overflow2) = T.lcmWithOverflow(denominator, y.denominator)
        return (Rational(numer, denom), overflow1 || overflow2)
    }

    /// Returns the least common multiplier for `self` and `y` and a boolean which indicates
    /// whether there was an overflow.
    public func lcmReportingOverflow(with y: Rational<T>)
        -> (partialValue: Rational<T>, overflow: Bool) {
        let (xn, yn, denom, overflow1) = Rational.commonDenomWithOverflow(self, y)
        let (numer, overflow2) = T.lcmWithOverflow(xn, yn)
        return (Rational(numer, denom), overflow1 || overflow2)
    }
}

/// Negates `num`.
public prefix func - <R: RationalNumber>(num: R) -> R {
    return num.negate
}

/// Returns the sum of `lhs` and `rhs`.
public func + <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.plus(rhs)
}

/// Returns the difference between `lhs` and `rhs`.
public func - <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.minus(rhs)
}

/// Multiplies `lhs` with `rhs` and returns the result.
public func * <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.times(rhs)
}

/// Divides `lhs` by `rhs` and returns the result.
public func / <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.divided(by: rhs)
}

/// Divides `lhs` by `rhs` and returns the result.
public func / <T: SignedInteger>(lhs: T, rhs: T) -> Rational<T> {
    return Rational(lhs, rhs)
}

/// Returns the remainder of dividing `lhs` by `rhs`.
public func % <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.remainder(dividingBy: rhs)
}

/// Raises rational value `lhs` to the power of `exp`.
public func ** <R: RationalNumber>(lhs: R, exp: R.Integer) -> R {
    return lhs.toPower(of: exp)
}

/// Assigns `lhs` the sum of `lhs` and `rhs`.
public func += <R: RationalNumber>(lhs: inout R, rhs: R) {
    lhs = lhs.plus(rhs)
}

/// Assigns `lhs` the difference between `lhs` and `rhs`.
public func -= <R: RationalNumber>(lhs: inout R, rhs: R) {
    lhs = lhs.minus(rhs)
}

/// Assigns `lhs` the result of multiplying `lhs` with `rhs`.
public func *= <R: RationalNumber>(lhs: inout R, rhs: R) {
    lhs = lhs.times(rhs)
}

/// Assigns `lhs` the result of dividing `lhs` by `rhs`.
public func /= <R: RationalNumber>(lhs: inout R, rhs: R) {
    lhs = lhs.divided(by: rhs)
}

/// Assigns `lhs` the result of raising rational value `lhs` to the power of `exp`.
public func **= <R: RationalNumber>(lhs: inout R, exp: R.Integer) {
    lhs = lhs.toPower(of: exp)
}

/// Returns the sum of `lhs` and `rhs`.
public func &+ <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.addingReportingOverflow(rhs).partialValue
}

/// Returns the difference between `lhs` and `rhs`.
public func &- <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.subtractingReportingOverflow(rhs).partialValue
}

/// Multiplies `lhs` with `rhs` and returns the result.
public func &* <R: RationalNumber>(lhs: R, rhs: R) -> R {
    return lhs.multipliedReportingOverflow(by: rhs).partialValue
}

/// Returns true if `lhs` is less than `rhs`, false otherwise.
public func < <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) < 0
}

/// Returns true if `lhs` is less than or equals `rhs`, false otherwise.
public func <= <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) <= 0
}

/// Returns true if `lhs` is greater or equals `rhs`, false otherwise.
public func >= <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) >= 0
}

/// Returns true if `lhs` is greater than equals `rhs`, false otherwise.
public func > <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) > 0
}

/// Returns true if `lhs` is equals `rhs`, false otherwise.
public func == <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) == 0
}

/// Returns true if `lhs` is not equals `rhs`, false otherwise.
public func != <R: RationalNumber>(lhs: R, rhs: R) -> Bool {
    return lhs.compare(to: rhs) != 0
}

/// This extension implements the logic to make `Rational<T>` codable if `T` is codable.
extension Rational: Codable where T: Codable {
    // Make coding key names explicit to avoid automatic extension.
    enum CodingKeys: String, CodingKey {
        case numerator
        case denominator
    }
}

/// This extension implements the logic to make `Rational<T>` sendable if `T` is sendable.
extension Rational: Sendable where T: Sendable {
}

// TODO: make this a static member of `Rational` once this is supported
private let rationalSeparator: Character = "/"

/// Integer casting

extension FixedWidthInteger {
    /// Casts the `Rational` number to this integer type. If the number is not
    /// a whole number, it will be rounded towards zero.
    public init<I: FixedWidthInteger>(_ value: Rational<I>) {
        let (quotient, _) = value.quotientAndRemainder(dividingBy: Rational<I>(1))
        self = Self(quotient)
    }
}
