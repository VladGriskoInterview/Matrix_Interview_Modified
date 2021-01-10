//
//  Protocols.swift
//  Matrix_Interview_Main
//
//  Created by hyperactive on 10/01/2021.
//

import Foundation

protocol DataManagerDelegate {
    var countries: [Country] { get set }
    
    func errorHandler(with massage: String, retry: Bool)
    
    func reload()
    
    func setCountries(data: [Country])
    
    func appendToCountries(country: Country) 
}
