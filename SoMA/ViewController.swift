/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

//
//  ViewController.swift
//  SoMA
//
//  Created by asdf on 4/8/17.
//  Copyright © 2017 asdf. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import SQLite
import Foundation
//import Gloss
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    // Create an outlet for the map
    @IBOutlet var mapView: MKMapView!

    // An array to put our locations in
    fileprivate var locations = [CLLocation]()
    fileprivate var annotations = [CLLocation]()
//    fileprivate var myLocations = [Location]()
    
//    struct Location: Glossy {
//        let latitude: Double?
//        let longitude: Double?
//        let timestamp: Date?
//        
//        // MARK: - Deserialization
//        
//        init?(json: JSON) {
//            self.latitude = "latitude" <~~ json
//            self.longitude = "longitude" <~~ json
//            self.timestamp = "timestamp" <~~ json
//        }
//        
//        // MARK: - Serialization
//        
//        func toJSON() -> JSON? {
//            return jsonify([
//                "latitude" ~~> self.latitude,
//                "longitude" ~~> self.longitude,
//                "timestamp" ~~> self.timestamp
//            ])
//        }
//    }
    
    // When the app opens up and the view has been loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocation()
        //initDatabase()
    }

    func initLocation() {
        print("DEBUG: Initialize location")
        let initialLocation = CLLocation(latitude: 50.3569, longitude: 7.5890)
        centerMapOnLocation(location: initialLocation)
        locationManager.startUpdatingLocation()
        updateLocationCounter.textAlignment = .center
    }
    
    func initDatabase() {
        print("TODO: Initialize database")
    }
    
    let regionRadius: CLLocationDistance = 1500

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.pausesLocationUpdatesAutomatically = false
        return manager
    }()

    @IBOutlet weak var updateLocationCounter: UILabel!

    @IBAction func enabledChanged(_ sender: UISwitch) {
        if sender.isOn {
            locationManager.startUpdatingLocation()
            print("start")
        } else {
            locationManager.stopUpdatingLocation()
            print("stop")
        }
    }

    // MARK: Actions
    
    @IBAction func uploadLocations(_ sender: UIButton) {
        let device_id: String = UIDevice.current.identifierForVendor!.uuidString;
        
        //var myLocations = [Location]()
//        var myLocations = [Location]()

//        var myJSONLocations: JSON = [String:Any]
//        
//        let json = JSON(data: myLocations)
        
//        let list: Array<JSON> = self.locations["coordinates"].arrayValue

        var parameters: [String:Any] = [
            "androidId": device_id,
            "uuid": UUID().uuidString,
            "locationData": []
        ]
        
        print("parameters", parameters)

//        var list: Array<JSON> = []
//
//        print("list", list)

        for location in self.locations {
//            print("location coords:", location.coordinate)
            
            do {
                
                var locationJSON: JSON = [
                    "longitude": location.coordinate.longitude,
                    "latitude": location.coordinate.latitude,
                    "timemstamp": location.timestamp
                ]
                print("locationJSON", locationJSON.arrayValue)
//                let json = JSON(locationJSON)
//                print(json)


//                parameters.locationData.add([
//                    "longitude": location.coordinate.longitude,
//                    "latitude": location.coordinate.latitude,
//                    "timemstamp": location.timestamp
//                    ])
//                list.append(JSON(locationJSON))
//                myLocations.append(Location.init(json: locationJSON)!)
//                myJSONLocations.
                //a.append(location.coordinate)
//                print(location.coordinate)
                
                
//                let jsonData = try JSONSerialization.data(withJSONObject: locationJSON, options: .prettyPrinted)
//                let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
//                if let dictFromJSON = decoded as? [String:Any] {
//                    print("dictFromJSON", dictFromJSON)
//                }
//                parameters.locationData.append(jsonData)

//                print("list111", list)

            } catch {
                print("error!")
            }

        }
        
//        do {
//            
//        }
        

        
//        let jsonError: NSError?
//        let jsonData = try JSONSerialization.data(withJSONObject: self.locations, options: .prettyPrinted)
//        if (jsonError) {
//            print(jsonData)
//        }

        
//
//        print("Parameters: ", parameters)
//        guard let parameters = myLocations.toJSONArray() else {
//            print("oops")
//        }
        
        
//        Alamofire.request(
//            "https://soma.uni-koblenz.de/api",
//            method: .post,
//            parameters: parameters,
//            encoding: JSONEncoding.default
//            ).responseJSON { response in
//                debugPrint(response)
//                if let JSON = response.result.value {
//                    print("JSON: \(JSON)")
//                }
//        }
    
    }
    
    
    @IBAction func accuracyChanged(_ sender: UISegmentedControl) {
        let accuracyValues = [
            kCLLocationAccuracyBestForNavigation,
            kCLLocationAccuracyBest,
            kCLLocationAccuracyNearestTenMeters,
            kCLLocationAccuracyHundredMeters,
            kCLLocationAccuracyKilometer,
            kCLLocationAccuracyThreeKilometers
        ]

        locationManager.desiredAccuracy = accuracyValues[sender.selectedSegmentIndex];
    }

    func getLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled on your device. In order to use this app, go to " +
                "Settings → Privacy → Location Services and turn location services on.")
            return
        }

        let authStatus = CLLocationManager.authorizationStatus()

        guard authStatus == .authorizedWhenInUse else {
            switch authStatus {
            case .denied, .restricted:
                print("This app is not authorized to use your location. In order to use this app, " +
                    "go to Settings → GeoExample → Location and select the \"While Using " +
                    "the App\" setting.")

            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()

            default:
                print("Oops! Shouldn't have come this far.")
            }

            return
        }

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

//    func initDatabase() {
//        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
//
//        do {
//            let db = try Connection("\(path)/db.sqlite3")
//            let locations = Table("locations")
//            let id = Expression<Int64>("id")
//            let latitude = Expression<Double>("latitude")
//            let longitude = Expression<Double>("longitude")
//            try db.run(locations.create(ifNotExists: true) { t in
//                t.column(id, primaryKey: .autoincrement)
//                t.column(latitude)
//                t.column(longitude)
//            })
//            print("init database success")
//        } catch {
//            print("init database error")
//
//        }
//
//
//
//
//    }
}

// MARK: - CLLocationManagerDelegate methods
extension ViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        // Return if there are no recent locations.
        guard let mostRecentLocation = locations.last else {
            return
        }
        
        let mostRecentLocationJSON: JSON = [
            "longitude": mostRecentLocation.coordinate.longitude,
            "latitude": mostRecentLocation.coordinate.latitude,
            "timestamp": mostRecentLocation.timestamp
        ]
        
        print("mostRecentLocationJSON", type(of: mostRecentLocationJSON))
        print("mostRecentLocationJSON", mostRecentLocationJSON)

        // Add the latest location to our collected locations
        self.locations.append(mostRecentLocation)
        
        // Add another annotation to the map.
        //let annotation = MKPointAnnotation()
        //annotation.coordinate = mostRecentLocation.coordinate
        
        // Also add to our map so we can remove old values later
        //self.locations.append(annotation)
        
        // DEBUG OUTPUT
        print(self.locations.count,
              mostRecentLocation.coordinate.latitude,
              mostRecentLocation.coordinate.longitude)
        
        print("type of mostRecentLocation", type(of: mostRecentLocation))
        print("type of locations", type(of: locations))
        
        // Update UI
        updateLocationCounter.text = String(self.locations.count)
        
//        for location in self.locations {
//            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
//        }
        

        
//        let myLocation = SomeLocation(
//            latitude: mostRecentLocation.coordinate.latitude,
//            longitude: mostRecentLocation.coordinate.longitude,
//            date: mostRecentLocation.timestamp
//        )

//        let myLocation = SomeLocation(data: mostRecentLocation)
        
        
        
        
        
        
//        let center = CLLocationCoordinate2D(
//            latitude: mostRecentLocation.coordinate.latitude,
//            longitude: mostRecentLocation.coordinate.longitude
//        )
//        
//        let region = MKCoordinateRegion(
//            center: center,
//            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//        )
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        //self.mapView.setRegion(region, animated: true)

//        latitude.text = String(format: "%.4f",
//          latestLocation.coordinate.latitude)
//
//        longitude.text = String(format: "%.4f",
//          latestLocation.coordinate.longitude)
//
//        horizontalAccuracy.text = String(format: "%.4f",
//          latestLocation.horizontalAccuracy)
//
//        altitude.text = String(format: "%.4f",
//          latestLocation.altitude)
//
//        verticalAccuracy.text = String(format: "%.4f",
//          latestLocation.verticalAccuracy)


//        let json = ["uuid": self.device_uuid]

        
        //        let data: NSData = ...some data loaded...
//        let jsonError: NSError?
//        let decodedJson = JSONSerialization.JSONObjectWithData(locations., options: nil) as Dictionary<String, AnyObject>
//        if !jsonError {
//            print(decodedJson["title"])
//        }

//        var username = "xcode"
//        var password = "pass"
//        let json = ["username":username, "password":password]
        
        
//                let json = [
//          myLocation
//        ]
        

        
//        let jsonError: NSError?
//        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
//        if (jsonError) {
//            print(jsonData)
//        }
        
//        guard let json1 = try? JSONSerialization.jsonObject(with: myLocation) as? [String: Any] else {
//            //PlaygroundPage.current.finishExecution()
//            print("error!:(")
//            return
//        }
        
//        guard let json2 = try? JSONSerialization.data(withJSONObject: myLocation, options: []) else {
//            print("error!:(")
//            return
//        }

//        do {
//            var request = URLRequest(url: URL(string: "http://soma.uni-koblenz.de/api/")!)
//            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
//            request.httpMethod = "POST"
//            request.httpBody = try JSONSerialization.data(withJSONObject: json2, options: [])
//        } catch {
//            print("error!:(")
//            return
//        }
        


//        let url:NSURL = NSURL(string: "https://soma.uni-koblenz.de/api")!
        //

//        let request:NSMutableURLRequest = NSMutableURLRequest(URL:url)
//        request.httpMethod = "POST"

//        var httpRequestBody = "uuid=" + self.device_uuid
        
//        if let array = locations as? [Any] {
//            if let firstObject = array.first {
//                print(firstObject)
//            }
//            
////            for object in array {
////                
////            }
////            
////            for case let string as String in array {
////                
////            }
//        }
        
//        let json = try? JSONSerialization.jsonObject(with: mostRecentLocation, options: [String: Any]);
//        print(json);


        
        
        
        
        
        
//        do {
//            let jsonData = try JSONSerialization.data(
//                withJSONObject: [myLocation],
//                options: JSONSerialization.WritingOptions.prettyPrinted
//            )
//            
//            if let JSONString = String(data: jsonData, encoding: String.Encoding.utf8) {
//                print(JSONString)
//            }
//            
//            var json = try JSONSerialization.jsonObject(
//                with: jsonData,
//                options: JSONSerialization.ReadingOptions.mutableContainers
//            ) as? [String: AnyObject]
//            
//        } catch {
//            print(error.localizedDescription)
//        }
        
        
        
        
        
        // Center map on the most recent location
        //centerMapOnLocation(location: mostRecentLocation)

        // Remove values if the array is too big
        //        while locations.count > 100 {
        //            let annotationToRemove = self.locations.first!
        //            self.locations.remove(at: 0)
        //
        //            // Also remove from the map
        //            mapView.removeAnnotation(annotationToRemove)
        //        }

        if UIApplication.shared.applicationState == .active {
            //mapView.showAnnotations(self.locations, animated: true)
        } else {
            print("App is backgrounded. New location is %@", mostRecentLocation)
        }
    }

    // This is called if:
    // - the location manager is updating, and
    // - it WASN'T able to get the user's location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
}
