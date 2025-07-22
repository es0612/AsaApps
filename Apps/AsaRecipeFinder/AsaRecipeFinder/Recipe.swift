//
//  Recipe.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//


import Foundation
import SwiftData

@Model
final class Recipe: @unchecked Sendable {
    var id: String
    var title: String
    var image: String?
    var readyInMinutes: Int?
    var servings: Int?
    var instructions: String
    var ingredients: [Ingredient]
    var isFavorite: Bool = false
    var dateAdded: Date = Date()
    var category: String?
    var sourceURL: String?
    
    init(id: String, title: String, image: String? = nil, 
         readyInMinutes: Int? = nil, servings: Int? = nil,
         instructions: String = "", ingredients: [Ingredient] = [],
         category: String? = nil, sourceURL: String? = nil) {
        self.id = id
        self.title = title
        self.image = image
        self.readyInMinutes = readyInMinutes
        self.servings = servings
        self.instructions = instructions
        self.ingredients = ingredients
        self.category = category
        self.sourceURL = sourceURL
    }
}

@Model
final class Ingredient: @unchecked Sendable {
    var name: String
    var amount: String?
    var unit: String?
    
    init(name: String, amount: String? = nil, unit: String? = nil) {
        self.name = name
        self.amount = amount
        self.unit = unit
    }
}
