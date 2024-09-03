//
//  GeminiService.swift
//  PlantIdentifyApp
//
//  Created by AlexX on 2024-09-02.
//
import Foundation
import UIKit


enum GeminiError: Error {
    case invalidImage
    case networkError
    case decodingError
    case apiError(String)
}

class GeminiService {
    private let apiKey: String = ""
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    

    func identifyPlant(image: UIImage, completion: @escaping (Result<Plant, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(GeminiError.invalidImage))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Identify this plant. Provide its name and a brief description in two separate lines."],
                        ["inlineData": ["mimeType": "image/jpeg", "data": base64Image]]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 256,
                "stopSequences": []
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"]
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            completion(.failure(GeminiError.networkError))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(GeminiError.networkError))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    
                    // Parse the text to extract plant name and description
                    let lines = text.components(separatedBy: .newlines)
                    let name = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown Plant"
                    let description = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let plant = Plant(name: name, description: description)
                    completion(.success(plant))
                } else if let error = json?["error"] as? [String: Any],
                          let message = error["message"] as? String {
                    completion(.failure(GeminiError.apiError(message)))
                } else {
                    completion(.failure(GeminiError.decodingError))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
