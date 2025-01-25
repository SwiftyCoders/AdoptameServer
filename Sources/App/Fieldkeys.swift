//
//  File.swift
//  Rescatame
//
//  Created by Alberto Alegre Bravo on 25/1/25.
//

import Vapor
import Fluent

extension FieldKey {
    static let name = FieldKey("name")
    static let accessKey = FieldKey("accessKey")
    static let age = FieldKey("age")
    static let breed = FieldKey("breed")
    static let summary = FieldKey("summary")
    static let type = FieldKey("type")
    static let size = FieldKey("size")
    static let status = FieldKey("status")
    static let color = FieldKey("color")
    static let rescueDate = FieldKey("rescueDate")
}
