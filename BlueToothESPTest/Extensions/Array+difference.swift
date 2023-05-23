//
//  Array+difference.swift
//  BlueToothESPTest
//
//  Created by Paul Dommer on 21.09.22.
//

import Foundation

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}
