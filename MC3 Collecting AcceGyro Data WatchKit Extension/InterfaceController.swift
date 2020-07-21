//
//  InterfaceController.swift
//  MC3 Collecting AcceGyro Data WatchKit Extension
//
//  Created by Eki Rifaldi on 19/07/20.
//  Copyright © 2020 Eki Rifaldi. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var labelInfo: WKInterfaceLabel!
    
    var wcSession : WCSession!
    var motion = CMMotionManager()
    var dataAcceArray:[Dictionary<String, AnyObject>] =  Array()
    var dataGyroArray:[Dictionary<String, AnyObject>] =  Array()
    var dataMotionArray:[Dictionary<String, AnyObject>] =  Array()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
//        print(motion.isDeviceMotionAvailable ? "Motion available" : "Motion NOT available")
//        print(motion.isGyroAvailable ? "Gyro available" : "Gyro NOT available")
//        print(motion.isAccelerometerAvailable ? "Accel available" : "Accel NOT available")
//        print(motion.isMagnetometerAvailable ? "Mag available" : "Mag NOT available")
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
}

//    MARK: - WCSession
extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        let instruction = message["messageFromIos"] as! String
        
        print(instruction)
        
        switch instruction {
        case "START":
            labelInfo.setText("Recording data...")
//            startGyroscope()
//            startAccelerometer()
            startDeviceMotion()
            break
        case "STOP":
            labelInfo.setText("Stopping...")
            stopUpdates()
//            print("SIZE: \(dataAcceArray.count) ===== \(dataGyroArray.count)")
//            let csvStr = generateCsvFormat(acceArray: dataAcceArray, gyroArray: dataGyroArray)
            print("SIZE: \(dataMotionArray.count)")
            let csvStr = generateCsvFormat(motionArray: dataMotionArray)
            sendMessage(strMsg: csvStr)
            break
        default:
            labelInfo.setText("Instruksi naon iyee...")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // Code.
        
    }
}

//MARK: - CoreMotion
extension InterfaceController {
    
    func startGyroscope(){
        print("Start Gyroscope")
        motion.gyroUpdateInterval = 0.5
        motion.startGyroUpdates(to: OperationQueue.current!) {
            (data, error) in
            print("Gyro")
            print(data as Any)
            if let trueData =  data {
                
                var dct = Dictionary<String, AnyObject>()
                dct.updateValue(self.getNowTime() as AnyObject, forKey: "GyroTime")
                dct.updateValue(trueData.rotationRate.x as AnyObject, forKey: "GyroX")
                dct.updateValue(trueData.rotationRate.y as AnyObject, forKey: "GyroY")
                dct.updateValue(trueData.rotationRate.z as AnyObject, forKey: "GyroZ")
                self.dataGyroArray.append(dct)
            }
        }
        return
    }
    
    
    func startAccelerometer() {
        print("Start Accelerometer")
        motion.accelerometerUpdateInterval = 0.5
        motion.startAccelerometerUpdates(to: OperationQueue.current!) {
            (data, error) in
            print("Acce")
            print(data as Any)
            if let trueData =  data {
                
                var dct = Dictionary<String, AnyObject>()
                dct.updateValue(self.getNowTime() as AnyObject, forKey: "AcceTime")
                dct.updateValue(trueData.acceleration.x as AnyObject, forKey: "AcceX")
                dct.updateValue(trueData.acceleration.y as AnyObject, forKey: "AcceY")
                dct.updateValue(trueData.acceleration.z as AnyObject, forKey: "AcceZ")
                self.dataAcceArray.append(dct)
            }
        }
        
        return
    }
    
    func startDeviceMotion(){
        print("Start DeviceMotion")
        motion.deviceMotionUpdateInterval  = 1.0 / 50.0
        motion.startDeviceMotionUpdates(to: OperationQueue.current!) {
            (data, error) in
            print("Motion")
            print(data as Any)
            if let trueData =  data {
                
                var dct = Dictionary<String, AnyObject>()
                dct.updateValue(self.getNowTime() as AnyObject, forKey: "Time")
                dct.updateValue(trueData.userAcceleration.x as AnyObject, forKey: "AcceX")
                dct.updateValue(trueData.userAcceleration.y as AnyObject, forKey: "AcceY")
                dct.updateValue(trueData.userAcceleration.z as AnyObject, forKey: "AcceZ")
                dct.updateValue(trueData.rotationRate.x as AnyObject, forKey: "GyroX")
                dct.updateValue(trueData.rotationRate.y as AnyObject, forKey: "GyroY")
                dct.updateValue(trueData.rotationRate.z as AnyObject, forKey: "GyroZ")
                self.dataMotionArray.append(dct)
                
            }
        }
        return
    }
    
    func stopUpdates() {
        if motion.isDeviceMotionAvailable {
//            motion.stopGyroUpdates()
            motion.stopDeviceMotionUpdates()
//            motion.stopAccelerometerUpdates()
        }
    }
    
    func generateCsvFormat(acceArray:[Dictionary<String, AnyObject>], gyroArray:[Dictionary<String, AnyObject>]) -> String {
        var csvString = "\("Time"),\("Accelerometer X"),\("Accelerometer Y"),\("Accelerometer Z")\n"
        for dct in acceArray {
            csvString = csvString.appending("\(String(describing: dct["AcceTime"]!)),\(String(describing: dct["AcceX"]!)),\(String(describing: dct["AcceY"]!)),\(String(describing: dct["AcceZ"]!))\n")
        }
        
        csvString = "\(csvString)\n\n\("TimeDMotion"),\("Gyroscope X"),\("Gyroscope Y"),\("Gyroscope Z")\n"
        for dct2 in gyroArray {
            csvString = csvString.appending("\(String(describing: dct2["GyroTime"]!)),\(String(describing: dct2["GyroX"]!)),\(String(describing: dct2["GyroY"]!)),\(String(describing: dct2["GyroZ"]!))\n")
        }
        
        return csvString
    }
    
    func generateCsvFormat(motionArray:[Dictionary<String, AnyObject>]) -> String {
        var csvString = "\("Time"),\("Accelerometer X"),\("Accelerometer Y"),\("Accelerometer Z"),\("Gyroscope X"),\("Gyroscope Y"),\("Gyroscope Z")\n"
        for dct in motionArray {
            csvString = csvString.appending("\(String(describing: dct["Time"]!)),\(String(describing: dct["AcceX"]!)),\(String(describing: dct["AcceY"]!)),\(String(describing: dct["AcceZ"]!)),\(String(describing: dct["GyroX"]!)),\(String(describing: dct["GyroY"]!)),\(String(describing: dct["GyroZ"]!))\n")
        }
        
        return csvString
    }
    
    func sendMessage(strMsg: String){
        let message = ["messageFromWatch":strMsg]
        wcSession.sendMessage(message, replyHandler: nil) { (error) in
            
            print(error.localizedDescription)
            
        }
        print("Sent")
        labelInfo.setText("Waiting...")
    }
    
    func getNowTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        let strDate = "\(hour):\(minutes):\(seconds).\(nanoseconds)"
        return strDate
    }
}
