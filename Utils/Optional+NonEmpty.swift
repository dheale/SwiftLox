//
//  Optional+NonEmpty.swift
//  LoxInterpreter
//
//  Created by Dominic Heale on 22/01/2019.
//

extension Optional where Wrapped: Collection {
    var nonEmpty: Wrapped? {
        return self?.isEmpty == true ? nil : self
    }
}
