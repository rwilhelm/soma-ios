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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
  
  // Create an outlet for the map
  @IBOutlet var mapView: MKMapView!
  
  fileprivate var locations = [CLLocation]()
  fileprivate var annotations = [MKPointAnnotation]()
  fileprivate var lastUpload = Date()
  
  struct Location {
    var accuracy: Double
    var altitude: Double
    var bearing: Double
    var latitude: Double
    var longitude: Double
    var timestamp: Double
    var speed: Double
    
    func toJSON() -> [String:Any] {
      return [
        "accuracy": accuracy,
        "altitude": altitude,
        "bearing": bearing,
        "latitude": latitude,
        "longitude": longitude,
        "timestamp": timestamp,
        "speed": speed
      ]
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initLocation()
    start()
  }
  
  func start() {
    print("start")
    //    locationManager.startMonitoringSignificantLocationChanges()
    //    locationManager.allowDeferredLocationUpdates(untilTraveled: 100, timeout: 30)
    locationManager.startUpdatingLocation()
  }
  
  func stop() {
    print("stop")
    //    locationManager.stopMonitoringSignificantLocationChanges()
    //    locationManager.disallowDeferredLocationUpdates()
    locationManager.stopUpdatingLocation()
  }
  
  func initLocation() {
    let initialLocation = CLLocation(latitude: 50.3569, longitude: 7.5890)
    centerMapOnLocation(location: initialLocation)
    updateLocationCounter.textAlignment = .center
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
      start()
    } else {
      stop()
    }
  }
  
  // MARK: Actions
  
  @IBAction func uploadLocations(_ sender: UIButton) {
    uploadLocations()
  }
  
  func uploadLocations() {
    let device_id: String = UIDevice.current.identifierForVendor!.uuidString;
    var locationData = [Location]()
    
    var parameters: [String:Any] = [
      "clientUUID": device_id,
      "uuid": UUID().uuidString, // goes to 'uuid' column in table 'trips'
      "locationData": []
    ]
    
    for location in self.locations {
      locationData.append(
        Location(
          accuracy: location.verticalAccuracy,
          altitude: location.altitude,
          bearing: location.course,
          latitude: location.coordinate.latitude,
          longitude: location.coordinate.longitude,
          timestamp: location.timestamp.timeIntervalSince1970,
          speed: location.speed
        )
      )
    }
    
    parameters["locationData"] = locationData.map { $0.toJSON() }
    
    debugPrint(locationData)
    
    Alamofire.request(
      "https://soma.uni-koblenz.de/api",
      method: .post,
      parameters: parameters,
      encoding: JSONEncoding.default,
      headers: nil
      ).responseString { response in
        if response.response?.statusCode == 200 {
          self.lastUpload = Date()
          self.locations.removeAll()
          self.updateLocationCounter.text = String(self.locations.count)
          self.mapView.removeAnnotations(self.annotations)
          self.annotations.removeAll()
          self.centerMapOnLocation(location: CLLocation(latitude: 50.3569, longitude: 7.5890))
          print("OK")
        }
    }
  }
  
  func writeLocationstoFile() {
    
    let filename = "somefile"
    let text = "some text"
    
    let DocumentDirURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    
    let fileURL = DocumentDirURL.appendingPathComponent(filename).appendingPathExtension("txt")
    
    print("Filepath: \(fileURL.path)")
    
    do {
      try text.write(to: fileURL, atomically: true, encoding: .utf8)
    } catch {
      print(error.localizedDescription)
    }
    
    do {
      let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      let filesize = attr[FileAttributeKey.size] as! UInt64
      print("filesize", filesize)
    } catch {
      print(error.localizedDescription)
    }
    
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
    start()
  }
}

// MARK: - CLLocationManagerDelegate methods
extension ViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    
    // Return if there are no recent locations.
    guard let mostRecentLocation = locations.last else {
      return
    }
    
    // Add the latest location to our collected locations
    self.locations.append(mostRecentLocation)
        // Add another annotation to the map.
    let annotation = MKPointAnnotation()
    annotation.coordinate = mostRecentLocation.coordinate
    
    // Also add to our map so we can remove old values later
    self.annotations.append(annotation)
    
    let timeSinceUpdate = Calendar.current.dateComponents([.second, .minute], from: lastUpload, to: Date())
    
    if timeSinceUpdate.minute! >= 30 {
      uploadLocations()
    } else {
      print(String(format: "%d %02d:%02d", self.locations.count, timeSinceUpdate.minute!, timeSinceUpdate.second! % 60))
    }
    
    // Update UI
    updateLocationCounter.text = String(format: "%02d:%02d", timeSinceUpdate.minute!, timeSinceUpdate.second! % 60) + " " + String(self.locations.count)
    
    if UIApplication.shared.applicationState == .active {
      mapView.showAnnotations(self.annotations, animated: true)
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
