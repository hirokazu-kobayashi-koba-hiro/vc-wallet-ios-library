//
//  HttpClient.swift
//  vc-wallet-library
//
//  Created by 小林弘和 on 2024/09/06.
//

import Foundation


public class HttpClient {
    
    let urlSession: URLSession
    
    public init(sessionConfiguration: URLSessionConfiguration) {
        urlSession = URLSession.init(configuration: sessionConfiguration)
    }
    
    
    
    public func get(url: String, headers: [String: String]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers?.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        let responseBody = try handleResponse(response: response, data: data)
        
        return responseBody
    }
    
    
    public func post(url: String, headers: [String: String]? = nil, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headers?.forEach { header in
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        
        if let body = body {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = jsonData
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        let responseBody = try handleResponse(response: response, data: data)
        
        
        return responseBody
    }
    
    private func handleResponse(response: URLResponse, data: Data) throws -> [String: Any] {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        let statusCode = httpResponse.statusCode
        print("HTTP response with status code: \(statusCode)")
        let response = try parse(data)
        switch statusCode {
        case 200...299:
            return response
        case 429:
            throw HttpError.tooManyRequestsError(statusCode: statusCode, response: response)
        case 400...499:
            throw HttpError.clientError(statusCode: statusCode, response: response)
        case 503:
            throw HttpError.serverMentenanceError(statusCode: statusCode, response: response)
        case 500...599:
            throw HttpError.serverError(statusCode: statusCode, response: response)
        default:
            throw HttpError.networkError(statusCode: statusCode, response: response)
        }
    }
    
    private func parse(_ data: Data) throws -> [String: Any] {
        guard !data.isEmpty else {
            return [:]
        }
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        Logger.shared.debug("Response: \(jsonObject)")
        guard let dictionary = jsonObject as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return dictionary
        
    }
}
