//
//  RepositorioMensagemErro.swift
//  Desafio-Marcos-Felipe
//
//  Created by Marcos Felipe Souza on 22/09/16.
//  Copyright © 2016 Marcos. All rights reserved.
//

import UIKit

import Foundation

//Retorna o erro da requisicao ao servico 

enum RepositorioMensagemErro: Error {
    case requisicao
    case converterJSONObjeto
    case requisicaoMalConstruida
}
