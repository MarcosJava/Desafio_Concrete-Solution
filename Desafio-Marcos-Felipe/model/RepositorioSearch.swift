//
//  RepositorioSearch.swift
//  Desafio-Marcos-Felipe
//
//  Created by Marcos Felipe Souza on 22/09/16.
//  Copyright © 2016 Marcos. All rights reserved.
//

import UIKit
import Foundation


class RepositorioSearch {
    
    let host = "https://api.500px.com/"
    let apiMethod = "v1/photos/search"
    let key: String
    
    fileprivate static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    init(key: String) {
        self.key = key
    }
    
    // Find photos that match the supplied query, results are returned asynchronously
    // via the supplied callback
    
    func buscarRepositorios(_ query:RepositorioQuery, callback: @escaping (Resultado<RepositorioArray>) -> ())  {
        
        // convert the PhotoQuery into querystring parameters
        let parametros = [
            "consumer_key": key,
            "image_size": "4",
            "term": query.texto,
            "license_type": "0"
        ];
        
        let querystring = parametros.map { key, value in "\(key)=\(value)" }
            .joined(separator: "&");
        

        guard let url = URL(string: "\(host)\(apiMethod)?\(querystring)") else {
            callback(.erro(RepositorioMensagemErro.requisicaoMalConstruida))
            return
        }
        
        

        let thread = URLSession.shared.dataTask(with: url, completionHandler: {
            (data, response, error) in
            
            
            DispatchQueue.main.async {
            
                if data == nil || error != nil {
                    callback(Resultado.erro(RepositorioMensagemErro.requisicao))
                    return
                }
                
                do {
                    // parse the results, then filter based on date
                    let resultado = try self.passaJSONparaObjeto(data!)
                    callback(Resultado.sucesso(resultado))
                } catch {
                    callback(Resultado.erro(RepositorioMensagemErro.converterJSONObjeto))
                }
            }
        }) 
        
        thread.resume()
    }
    
    // parses the JSON data returned by the 50px API
    fileprivate func passaJSONparaObjeto(_ data: Data) throws -> RepositorioArray {
        
        guard let jsonDict =
            try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary,
            
            let repositorios = jsonDict["photos"] as? [NSDictionary] else {
                throw RepositorioMensagemErro.converterJSONObjeto
            }
        
        let object = repositorios.map {
            object -> Repositorio? in
            
            guard let imageUrl = object["image_url"] as? String,
                let nomeRequest = object["name"] as? String,
                let url = URL(string: imageUrl) else {
                    return nil
                }
            
            let rep = Repositorio(nome: nomeRequest, foto: url)
            return rep
            }
            .flatMap { return $0! }
        
        return object;
    }
    

}
