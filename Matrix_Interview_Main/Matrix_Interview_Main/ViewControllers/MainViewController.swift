//
//  MainViewController.swift
//  Matrix_Interview_Main
//
//  Created by hyperactive on 06/01/2021.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DataManagerDelegate {
    
    var filterStackView: UIStackView!
    var countries: [Country] = []
    var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //for testing the fetch of json if it is already cached uncomment line bellow
        Cache.shared.remove("countries", from: .caches)
        
        // when the delegate to DataManager is set it automatically checks for network problems and fetches data
        DataManager.shared.delegate = self
        
        setTableView()

        setFilterStackView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if filterStackView != nil && filterStackView.alpha == 0 {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.filterStackView.alpha = 1.0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: Constants.cellIdentifier)
        }
       
        cell!.textLabel?.text = countries[indexPath.row].name
        cell!.detailTextLabel?.text = countries[indexPath.row].nativeName
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedCountry = countries[indexPath.row]
        var borderingCountries: [Country] = []
        
        //getting all countries that have borders with selectedCountry
        for country in countries {
            if selectedCountry.borders.contains(where: { $0 == country.alphaCode}) {
                borderingCountries.append(country)
            }
        }
        
        let countryVC = CountryDetailViewController()
        countryVC.borderingCountries = borderingCountries
        countryVC.selectedCountry = selectedCountry
        
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.filterStackView.alpha = 0.0
        }
        
        navigationController?.show(countryVC, sender: nil)
    }
    
    func makeFilters() -> [UIButton] {
        var buttons: [UIButton] = []
        
        for i in 0...3 {
            let button = UIButton()
            
            switch i {
            case 0:
                button.addTarget(self, action: #selector(orderAscendingAlphabetically), for: .touchUpInside)
                button.setTitle(Constants.ButtonTitles.aToZ, for: .normal)
            case 1:
                button.addTarget(self, action: #selector(orderDescendingAlphabetically), for: .touchUpInside)
                button.setTitle(Constants.ButtonTitles.zToA, for: .normal)
            case 2:
                button.addTarget(self, action: #selector(orderAscendingByArea), for: .touchUpInside)
                button.setTitle(Constants.ButtonTitles.areaAsc, for: .normal)
            case 3:
                button.addTarget(self, action: #selector(orderDescendingByArea), for: .touchUpInside)
                button.setTitle(Constants.ButtonTitles.areaDesc, for: .normal)
            default: break
            }
            
            button.layer.cornerRadius = 10
            button.layer.masksToBounds = true
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.backgroundColor = UIColor(red: 255/255, green: 127/255, blue: 80/255, alpha: 0.8)
            
            buttons.append(button)
        }
        
        return buttons
    }
    
    func setFilterStackView() {
        let buttons = makeFilters()
        
        filterStackView = UIStackView(arrangedSubviews: buttons)
        filterStackView.translatesAutoresizingMaskIntoConstraints = false
        filterStackView.alignment = .fill
        filterStackView.distribution = .fillEqually
        filterStackView.spacing = 10.0
        filterStackView.axis = .horizontal
        
        guard let bar = navigationController?.navigationBar else { return }
        bar.pin(view: filterStackView, with: .zero)
    }
    
    func setTableView() {
        view.pin(view: tableView, with: .zero)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func appendToCountries(country: Country) {
        self.countries.append(country)
    }
    
    func setCountries(data: [Country]) {
        self.countries = data
    }
    
    func reload() {
        self.tableView.reloadData()
    }
    
    func errorHandler(with massage: String, retry: Bool) {
        let ac = UIAlertController(title: "Error", message: massage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        //error can be shown after it was determined the user is not connected and there is no point in retrying the connection before he stabelized it
        if retry {
            ac.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { [weak self] (action) in
                DataManager.shared.fetchJSON { (countries) in
                    self?.countries = countries
                    DispatchQueue.main.async {
                        self?.reload()
                    }
                }
              
            }))
        } else { //means the we dont have a connection and we show the user the option to open settings and connect to network
            
            ac.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:]) { (success) in
                        // nothing is done here only transition to settings
                    }
                }
            }))
        }
        
        present(ac, animated: true, completion: nil)
    }
    
    @objc func orderAscendingAlphabetically() {
        countries = countries.sorted { $0.name < $1.name }
        tableView.reloadData()
    }
    
    @objc func orderDescendingAlphabetically() {
        countries = countries.sorted { $0.name > $1.name }
        tableView.reloadData()
    }
    
    @objc func orderAscendingByArea() {
        countries = countries.sorted { $0.area < $1.area }
        tableView.reloadData()
    }
    
    @objc func orderDescendingByArea() {
        countries = countries.sorted { $0.area > $1.area }
        tableView.reloadData()
    }
}
