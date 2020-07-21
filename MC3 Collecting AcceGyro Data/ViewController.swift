//
//  ViewController.swift
//  MC3 Collecting AcceGyro Data
//
//  Created by Eki Rifaldi on 19/07/20.
//  Copyright © 2020 Eki Rifaldi. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet weak var button: UIButton!
    
    var wcSession : WCSession! = nil
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
    }
    
    func createCsv(csvStr: String){
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("CSVRecAcceGyro.csv")
            print(fileURL)
            try csvStr.write(to: fileURL, atomically: true, encoding: .utf8)
            let items = [fileURL]
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            DispatchQueue.main.async {
                self.present(ac, animated: true)
            }
        } catch {
            print("error creating file")
        }
    }
    
    @IBAction func btnStartPressed(_ sender: UIButton) {
//        isRecording = !isRecording
        
        var instruction = "empty"
        if isRecording {
            instruction = "STOP"
            button.setTitle("START", for: .normal)
        } else {
            instruction = "START"
            button.setTitle("STOP", for: .normal)
        }
        
        print("\(isRecording) - \(instruction)")
        
        let message = ["messageFromIos":instruction]
        
        isRecording = !isRecording
        
        wcSession.sendMessage(message, replyHandler: nil) { (error) in
            
            print(error.localizedDescription)
            
        }
    }
    
//    MARK: - WCSession

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // Code
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        let text = message["messageFromWatch"] as! String
        
        createCsv(csvStr: text)
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
        // Code
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
        // Code
        
    }

}

