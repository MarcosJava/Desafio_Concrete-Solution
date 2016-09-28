//
//  Resultado.swift
//  Desafio-Marcos-Felipe
//
//  Created by Marcos Felipe Souza on 22/09/16.
//  Copyright © 2016 Marcos. All rights reserved.
//


import Foundation

//Serve para o resultado assincrono
enum Resultado<T> {
    case sucesso(T)
    case erro(Error)
}
