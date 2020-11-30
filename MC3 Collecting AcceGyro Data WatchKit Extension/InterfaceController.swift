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
import HealthKit


class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var labelInfo: WKInterfaceLabel!
    @IBOutlet weak var labelHeart: WKInterfaceLabel!
    @IBOutlet weak var button: WKInterfaceButton!
    
    var wcSession : WCSession!
    var motion = CMMotionManager()
    var dataMotionArray:[Dictionary<String, AnyObject>] =  Array()
    
    //For workout session
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var currentQuery: HKQuery?
    
    var isRecording = false
    
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
        
        //Check HealthStore
        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("Health Data Not Avaliable")
            return
        }
        
        //        locationManager.allowsBackgroundLocationUpdates = true
        
        //        print(motion.isDeviceMotionAvailable ? "Motion available" : "Motion NOT available")
        //        print(motion.isGyroAvailable ? "Gyro available" : "Gyro NOT available")
        //        print(motion.isAccelerometerAvailable ? "Accel available" : "Accel NOT available")
        //        print(motion.isMagnetometerAvailable ? "Mag available" : "Mag NOT available")
    }
    
    override func didDeactivate() {
        super.didDeactivate()
//        DispatchQueue.global().async {
//            self.wcSession.activate()
//        }
    }
    
    @IBAction func btnPressed() {
        if(!isRecording){
            let stopTitle = NSMutableAttributedString(string: "Stop Recording")
            stopTitle.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], range: NSMakeRange(0, stopTitle.length))
            button.setAttributedTitle(stopTitle)
            isRecording = true
            startWorkout() //Start workout session/healthkit streaming
        }else{
            let exitTitle = NSMutableAttributedString(string: "Start Recording")
            exitTitle.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.green], range: NSMakeRange(0, exitTitle.length))
            button.setAttributedTitle(exitTitle)
            isRecording = false
            //            healthStore.end(session!)
            session?.stopActivity(with: Date())
            labelHeart.setText("Heart Rate")
            
        }
        
    }
    
}

//    MARK: - WCSession
extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        let instruction = message["messageFromIos"] as! String
        switch instruction {
        case "START":
            labelInfo.setText("Recording data...")
            dataMotionArray.removeAll()
            startDeviceMotion()
            break
        case "STOP":
            labelInfo.setText("Stopping...")
            stopUpdates()
            let csvStr = generateCsvFormat(motionArray: dataMotionArray)
            sendMessage(strMsg: csvStr)
            dataMotionArray.removeAll()
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
    
    func startDeviceMotion(){
        motion.deviceMotionUpdateInterval  = 1.0 / 75.0 //75 Hz
        motion.startDeviceMotionUpdates(to: OperationQueue.current!) {
            (data, error) in
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
//                self.wcSession.activate()
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

//MARK: - WorkoutSession
extension InterfaceController: HKWorkoutSessionDelegate{
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print(date)
            if let query = heartRateQuery(date){
                self.currentQuery = query
                healthStore.execute(query)
            }
        //Execute Query
        case .stopped: //sebelumnya .ended
            //Stop Query
            healthStore.stop(self.currentQuery!)
            session?.end()
            session = nil
        default:
            print("Unexpected state: \(toState.rawValue)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        //Do Nothing
    }
    
    func startWorkout(){
        // If a workout has already been started, do nothing.
        if (session != nil) {
            return
        }
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .badminton
        workoutConfiguration.locationType = .indoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
            fatalError("Unable to create workout session")
        }
        
        
        session?.startActivity(with: Date())
    }
    
    func heartRateQuery(_ startDate: Date) -> HKQuery? {
        let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictEndDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType!, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //Do nothing
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            guard let samples = samples as? [HKQuantitySample] else {return}
            DispatchQueue.main.async {
                guard let sample = samples.first else { return }
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.labelHeart.setText(String(UInt16(value))) //Update label
            }
            
        }
        
        return heartRateQuery
    }
    
}
