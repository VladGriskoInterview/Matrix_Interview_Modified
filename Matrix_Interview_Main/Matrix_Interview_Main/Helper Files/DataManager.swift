//
//  DataManager.swift
//  Matrix_Interview_Main
//
//  Created by hyperactive on 10/01/2021.
//

import Foundation

open class DataManager {
    
    static let shared = DataManager()
    var delegate: DataManagerDelegate? {
        didSet {
            DispatchQueue.global().async { [weak self] in
                self?.checkNetworkConnection { (success) in
                    if success {
                        self?.getData()
                        //stop monitoring connection after we got the data
                        NetStatus.shared.stopMonitoring()
                    }
                }
            }
        }
    }
    
    private init () {}
    
    func checkNetworkConnection(completion: @escaping (_ success: Bool) -> Void) {
        
        NetStatus.shared.startMonitoring()
        
        NetStatus.shared.netStatusChangeHandler = {
            
            if !NetStatus.shared.isConnected {
                // if the user is not connected check if he already has the data cached, if yes we treat it as already connected because getData handles that.
                
                if Cache.shared.fileExists(Constants.cacheDirName, in: .caches) {
                    completion(true)
                } else {
                    // if we dont have a connection and the data is not cached, show error to check for connection. the data will be fetched automatically whenever the connection gets back
                    DispatchQueue.main.async { [weak self] in
                        guard let delegate = self?.delegate else { return }
                        
                        delegate.errorHandler(with: Constants.ErrorMassages.connectionFailed, retry: false)
                    }
                }
                
                // gets invoked if we have a stable internet connection
            } else {
                completion(true)
            }
        }
    }
    
    func getData() {
        guard let delegate = self.delegate else { return }
        
        //fetch data asynchronously not on main thread
        DispatchQueue.global().async { [weak self] in
            
            // if the data already exists no need to fetch json
            if !Cache.shared.fileExists(Constants.cacheDirName, in: .caches) {
                self?.fetchJSON { (countries) in
                    
                    Cache.shared.store(countries, to: .caches, as: Constants.cacheDirName)
                    
                    delegate.setCountries(data: countries)
                    
                    DispatchQueue.main.async {
                        delegate.reload()
                    }
                }
            } else {
                let cached = Cache.shared.retrieve(Constants.cacheDirName, from: .caches, as: [Country].self)
                
                delegate.setCountries(data: cached)
                
                DispatchQueue.main.async {
                    delegate.reload()
                }
            }
        }
    }
    
    func fetchJSON(completion: @escaping(_ countries: [Country]) -> Void) {
        
        // in a project i would use alamofire but for simplicity purposes i chose to use URLSession to avoid installing unnecessary pods
        guard let delegate = self.delegate else { return }
        
        let str = Constants.url
        
        guard let url = URL(string: str) else { return }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { [weak self] (data, response, error) in
            
            guard let data = data, error == nil else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                var countries: [Country] = []
                
                if let arrayJson = json as? NSArray {
                    for item in arrayJson {
                        if let dict = item as? NSDictionary {
                            countries.append(self?.makeCountry(from:  dict) ?? Country(name: "", nativeName: "", area: 0, alphaCode: "", borders: []))
                        }
                    }
                }
                
                completion(countries)
            } catch {
                //show alert of failure on main thread
                DispatchQueue.main.async {
                    delegate.errorHandler(with: error.localizedDescription, retry: true)
                }
            }
        }
        
        task.resume()
    }
    
    func makeCountry(from json: NSDictionary) -> Country {
        
        let name = json[Constants.Keys.name] as? String ?? "undefined"
        let nativeName = json[Constants.Keys.nativeName] as? String ?? "undefined"
        let area = json[Constants.Keys.area] as? Double ?? 0.0
        let alphaCode = json[Constants.Keys.alphaCode] as? String ?? "undefined"
        let borders = json[Constants.Keys.borders] as? [String] ?? []
        
        return Country.init(name: name, nativeName: nativeName, area: area, alphaCode: alphaCode, borders: borders)
    }
}
