//
//  ViewController.swift
//  Desafio-Marcos-Felipe
//
//  Created by Marcos Felipe Souza on 22/09/16.
//  Copyright © 2016 Marcos. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    @IBOutlet weak var pesquisa: UITextField!
    @IBOutlet weak var pogress: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    
    fileprivate let viewModel = RepositorioViewModel()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.textoProcurado.bidirectionalBindTo(pesquisa.bnd_text)
        
        colocaVermelho()
        
        adicionaLoadingDownload()
        
        populandoTableView()
        erros()
        load()
    }
    
    func erros(){
        //Adiciona um erro
        viewModel.errosInexperado.observe {
            [unowned self] error in
            
            let alertController = UIAlertController(title: "Deu errado :-(",
                message: error, preferredStyle: .alert)
            
            self.present(alertController, animated: true, completion: nil)
            
            let actionOk = UIAlertAction(title: "OK", style: .default,
                handler: { action in alertController.dismiss(animated: true, completion: nil) })
            
            alertController.addAction(actionOk)
        }

    }
    
    
    func populandoTableView(){
        
        //Realiza insercoes na tabela.
        viewModel.lstRepositorios.lift().bindTo(tableView) { indexPath, dataSource, tableView in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "celula", for: indexPath) as! RepositorioTableViewCell
            let repositorio = dataSource[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
            cell.titulo.text = repositorio.nome
            cell.imagem.image = nil
            
            
            let fila = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
            fila.async {
                
                if let imagem = try? Data(contentsOf: repositorio.foto) {
                    DispatchQueue.main.async {
                         cell.imagem.image = UIImage(data: imagem)
                    }
                }
            }
            
            return cell
        }

    }
    
    func adicionaLoadingDownload(){
        viewModel.progress
            .map { !$0 }
            .bindTo(pogress.bnd_hidden)
        
        viewModel.progress
            .map { $0 ? CGFloat(0.5) : CGFloat(1.0) }
            .bindTo(tableView.bnd_alpha)

    }
    
    func colocaVermelho() {
        viewModel.validandoProcuraText
            .map { $0 ? UIColor.black : UIColor.red }
            .bindTo(pesquisa.bnd_textColor)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func load() {
        Alamofire.request(.GET, "https://api.github.com/search/repositories?q=language:Java&sort=stars&page=1").response { (req, res, data, error) -> Void in
           // print(res)
            let outputString = NSString(data: data!, encoding:String.Encoding.utf8)
            print(outputString)
            
            
        }
    }


}

