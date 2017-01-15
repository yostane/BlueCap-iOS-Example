//
//  ViewController.swift
//  BlueCap-iOS-Example
//
//  Created by yassine benabbas on 15/01/2017.
//  Copyright © 2017 yassine benabbas. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth
import Dispatch

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var peripherals:Array<Peripheral> = []
    @IBOutlet var tableView: UITableView!
    
    public enum AppError : Error {
        case invalidState
        case resetting
        case poweredOff
        case unknown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "central-manager" as NSString])
        
        let stateChangeFuture = manager.whenStateChanges()
        
        let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
            switch state {
            case .poweredOn:
                return manager.startScanning()
            case .poweredOff:
                throw AppError.poweredOff
            case .unauthorized, .unsupported:
                throw AppError.invalidState
            case .resetting:
                throw AppError.resetting
            case .unknown:
                throw AppError.unknown
            }
        }
        
        scanFuture.onFailure { error in
            guard let appError = error as? AppError else {
                return
            }
            switch appError {
            case .invalidState:
                break
            case .resetting:
                manager.reset()
            case .poweredOff:
                break
            case .unknown:
                break
            }
        }
        
        scanFuture.onSuccess { peripheral in
            var found = false
            for (p) in self.peripherals{
                if p.identifier.uuidString == peripheral.identifier.uuidString {
                    found = true
                    break;
                }
            }
            if(found == false){
                self.peripherals.append(peripheral)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "peripheral_cell")! as UITableViewCell
        
        cell.textLabel?.text = self.peripherals[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

