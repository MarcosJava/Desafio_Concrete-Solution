//
//  RepositorioViewModel.swift
//  Desafio-Marcos-Felipe
//
//  Created by Marcos Felipe Souza on 22/09/16.
//  Copyright © 2016 Marcos. All rights reserved.
//

import Foundation
import Bond

class RepositorioViewModel {
    
    let textoProcurado = Observable<String?>("")
    let validandoProcuraText = Observable<Bool>(false)
    let lstRepositorios = ObservableArray<Repositorio>()
    let progress = Observable<Bool>(false)
    let errosInexperado = EventProducer<String>()
    
    
    init() {
        //Coloca o valor Bond
        // searchString.value = "Bond"
        
        //Adiciona um map com condicoes maior que 3 para pintar
        textoProcurado
            .map { $0!.characters.count > 3 }
            .bindTo(validandoProcuraText)
        
        //Pega e imprime o valor no bidirectional
        textoProcurado.observeNew {
            text in
            print(text)
        }
        
        //Quando tiver mais de 4 caracteres executa a busca por imagem
        textoProcurado
            .filter { $0!.characters.count > 4 }
            .throttle(0.5, queue: Queue.Main)
            .observe {
                [unowned self] text in
                self.executandoSearch(text!)
        }
        
    }
    
    fileprivate let searchRepositorio: RepositorioSearch = {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "apiKey") as! String
        return RepositorioSearch(key: apiKey)
    }()
    
    
    func executandoSearch(_ valor: String) {
        print("Texto buscado : " + valor)
        var repQuery = RepositorioQuery()
        repQuery.texto = textoProcurado.value ?? ""
        
        progress.value = true
        
        searchRepositorio.buscarRepositorios(repQuery) {
            [unowned self] resultado in
            
            self.progress.value = false
            switch resultado
            {
            case .sucesso(let go):
                self.lstRepositorios.removeAll()
                self.lstRepositorios.insertContentsOf(go, atIndex: 0)
            case .erro:
                self.errosInexperado
                    .next("Verifique sua internet, ou digite outra palavra")
            }
        }

    }

}
