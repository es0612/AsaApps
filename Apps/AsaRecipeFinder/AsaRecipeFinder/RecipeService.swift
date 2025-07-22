//
//  RecipeService.swift
//  AsaRecipeFinder
//  
//  Created on 2025/07/22
//

import Foundation

// MARK: - Recipe Service Errors

enum RecipeServiceError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case noRecipesFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが見つかりませんでした"
        case .decodingError(let error):
            return "データの解析に失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .noRecipesFound:
            return "レシピが見つかりませんでした"
        }
    }
}

// MARK: - Recipe Service Protocol

protocol RecipeServiceProtocol: Sendable {
    func searchRecipesByIngredient(_ ingredient: String) async throws -> [Recipe]
    func searchRecipesByName(_ name: String) async throws -> [Recipe]
    func getRecipeDetails(by id: String) async throws -> Recipe
    func getRandomRecipes(count: Int) async throws -> [Recipe]
    func getCategories() async throws -> [String]
    func getRecipesByCategory(_ category: String) async throws -> [Recipe]
}

// MARK: - Recipe Service Implementation

final class RecipeService: RecipeServiceProtocol {
    nonisolated static let shared = RecipeService()
    
    private let baseURL = "https://www.themealdb.com/api/json/v1/1"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Search by Ingredient
    
    func searchRecipesByIngredient(_ ingredient: String) async throws -> [Recipe] {
        let encodedIngredient = ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ingredient
        let urlString = "\(baseURL)/filter.php?i=\(encodedIngredient)"
        
        guard let url = URL(string: urlString) else {
            throw RecipeServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            guard let meals = response.meals else {
                throw RecipeServiceError.noRecipesFound
            }
            
            // 詳細情報を取得するために各レシピIDで詳細APIを呼び出し
            var recipes: [Recipe] = []
            for meal in meals.prefix(10) { // 最初の10件に制限
                do {
                    let detailedRecipe = try await getRecipeDetails(by: meal.idMeal)
                    recipes.append(detailedRecipe)
                } catch {
                    // 詳細取得に失敗した場合は基本情報のみでレシピを作成
                    recipes.append(meal.toRecipe())
                }
            }
            
            return recipes
        } catch let error as DecodingError {
            throw RecipeServiceError.decodingError(error)
        } catch {
            throw RecipeServiceError.networkError(error)
        }
    }
    
    // MARK: - Search by Name
    
    func searchRecipesByName(_ name: String) async throws -> [Recipe] {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "\(baseURL)/search.php?s=\(encodedName)"
        
        guard let url = URL(string: urlString) else {
            throw RecipeServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(MealResponse.self, from: data)
            
            guard let meals = response.meals else {
                throw RecipeServiceError.noRecipesFound
            }
            
            return meals.map { $0.toRecipe() }
        } catch let error as DecodingError {
            throw RecipeServiceError.decodingError(error)
        } catch {
            throw RecipeServiceError.networkError(error)
        }
    }
    
    // MARK: - Get Recipe Details
    
    func getRecipeDetails(by id: String) async throws -> Recipe {
        let urlString = "\(baseURL)/lookup.php?i=\(id)"
        
        guard let url = URL(string: urlString) else {
            throw RecipeServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(MealResponse.self, from: data)
            
            guard let meal = response.meals?.first else {
                throw RecipeServiceError.noRecipesFound
            }
            
            return meal.toRecipe()
        } catch let error as DecodingError {
            throw RecipeServiceError.decodingError(error)
        } catch {
            throw RecipeServiceError.networkError(error)
        }
    }
    
    // MARK: - Get Random Recipes
    
    func getRandomRecipes(count: Int = 5) async throws -> [Recipe] {
        var recipes: [Recipe] = []
        
        for _ in 0..<count {
            let urlString = "\(baseURL)/random.php"
            
            guard let url = URL(string: urlString) else {
                throw RecipeServiceError.invalidURL
            }
            
            do {
                let (data, _) = try await session.data(from: url)
                let response = try JSONDecoder().decode(MealResponse.self, from: data)
                
                if let meal = response.meals?.first {
                    recipes.append(meal.toRecipe())
                }
            } catch {
                // ランダムレシピの一部取得に失敗しても続行
                continue
            }
        }
        
        if recipes.isEmpty {
            throw RecipeServiceError.noRecipesFound
        }
        
        return recipes
    }
    
    // MARK: - Get Categories
    
    func getCategories() async throws -> [String] {
        let urlString = "\(baseURL)/categories.php"
        
        guard let url = URL(string: urlString) else {
            throw RecipeServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(CategoryResponse.self, from: data)
            
            guard let categories = response.meals else {
                throw RecipeServiceError.noData
            }
            
            return categories.map { $0.strCategory }
        } catch let error as DecodingError {
            throw RecipeServiceError.decodingError(error)
        } catch {
            throw RecipeServiceError.networkError(error)
        }
    }
    
    // MARK: - Get Recipes by Category
    
    func getRecipesByCategory(_ category: String) async throws -> [Recipe] {
        let encodedCategory = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        let urlString = "\(baseURL)/filter.php?c=\(encodedCategory)"
        
        guard let url = URL(string: urlString) else {
            throw RecipeServiceError.invalidURL
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            
            guard let meals = response.meals else {
                throw RecipeServiceError.noRecipesFound
            }
            
            return meals.map { $0.toRecipe() }
        } catch let error as DecodingError {
            throw RecipeServiceError.decodingError(error)
        } catch {
            throw RecipeServiceError.networkError(error)
        }
    }
}