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
import Foundation
import Alamofire
import Firebase
import FirebaseInstanceID
import FirebaseMessaging

class ViewController: UIViewController {
  
  let uploadSchedule: Int = 1 // upload every n minutes
  
  let timeout: TimeInterval = 90 // deferred location update timeout
  let untilTraveled: CLLocationDistance = 0 // update when traveled n meters
  let distanceFilter: CLLocationDistance = 0

  let koblenz = CLLocation(latitude: 50.3569, longitude: 7.5890)
  let regionRadius: CLLocationDistance = 1500

  fileprivate var locations = [CLLocation]()
  fileprivate var annotations = [MKPointAnnotation]()
  fileprivate var lastUpload = Date()
  
  let API_URL = "https://soma.uni-koblenz.de:5000/upload"
  let TOKEN_URL = "https://soma.uni-koblenz.de:7593"

  let device_id: String = UIDevice.current.identifierForVendor!.uuidString;

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
    initLocation(homeLocation: koblenz)
    start()
  }
  
  private lazy var locationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.delegate = self
    manager.distanceFilter = self.distanceFilter
    manager.allowsBackgroundLocationUpdates = true
    manager.requestAlwaysAuthorization()
    manager.pausesLocationUpdatesAutomatically = false // keep running
    return manager
  }()
  
  // MARK: Outlets
  
  @IBOutlet var mapView: MKMapView!
  
  @IBOutlet weak var updateLocationCounter: UILabel!
  
  @IBAction func uploadLocations(_ sender: UIButton) {
    uploadLocations()
  }
  
  @IBAction func toggleLocationUpdates(_ sender: UISwitch) {
    if sender.isOn {
      start()
    } else {
      stop()
    }
  }
  
  // MARK: Actions
  
  func start() {
    print("start")
    //    locationManager.startMonitoringSignificantLocationChanges()
    locationManager.startUpdatingLocation()
    locationManager.allowDeferredLocationUpdates(untilTraveled: self.untilTraveled, timeout: self.timeout)
  }
  
  func stop() {
    print("stop")
    //    locationManager.stopMonitoringSignificantLocationChanges()
    locationManager.stopUpdatingLocation()
    locationManager.disallowDeferredLocationUpdates()
  }
  
  func initLocation(homeLocation: CLLocation) {
    centerMapOnLocation(location: homeLocation)
    updateLocationCounter.textAlignment = .center
  }
  
  func centerMapOnLocation(location: CLLocation) {
    let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
    mapView.setRegion(coordinateRegion, animated: true)
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
  
  func uploadLocations() {
    var locationData = [Location]()
    
    var parameters: [String:Any] = [
      "device_id": device_id,
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
    
    Alamofire.request(API_URL,
                      method: .post,
                      parameters: parameters,
                      encoding: JSONEncoding.default,
                      headers: nil
      ).responseString { response in
        if response.response?.statusCode == 200 {
          self.uploadSuccessHandler()
        }
    }
  }
  
  func uploadSuccessHandler() {
    self.lastUpload = Date()
    self.locations.removeAll()
    self.updateLocationCounter.text = String(self.locations.count)
    self.mapView.removeAnnotations(self.annotations)
    self.annotations.removeAll()
    self.centerMapOnLocation(location: koblenz)
    print("OK")
  }
  
  
  func writeLocationstoFile() {
    
    // TODO: Write out all data to file/sqlite b/c background
    // uploads must get their JSON from a file.
    
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
}


// MARK: - CLLocationManagerDelegate methods
extension ViewController: CLLocationManagerDelegate {
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Return if there are no recent locations
    guard let lastLocation = locations.last else {
      return
    }
    storeLocation(location: lastLocation)
    makeAnnotation(location: lastLocation)
    checkUploadSchedule(timeSinceUpdate: lastUpdate())
    updateUI(timeSinceUpdate: lastUpdate(), location: lastLocation)
  }
  
  func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
    print("pause location updates")
  }
  
  func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
    print("resume location updates")
  }
  
  func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
    if (error == nil) {
      print("REQUESTING LOCATION")
      manager.requestLocation()
    } else {
      print("Error: \(error ?? "NOERR" as! Error)")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Error: NOLOCATIONERROR \(error)")
  }
  
  func lastUpdate() -> DateComponents {
    return Calendar.current.dateComponents([.second, .minute], from: lastUpload, to: Date())
  }
  
  // Add the latest location to our collected locations
  func storeLocation(location: CLLocation) {
    self.locations.append(location)
  }
  
  // Add annotations to the map
  func makeAnnotation(location: CLLocation) {
    let annotation = MKPointAnnotation()
    annotation.coordinate = location.coordinate
    self.annotations.append(annotation)
  }
  
  // Check time since last upload and maybe upload
  func checkUploadSchedule(timeSinceUpdate: DateComponents) {
    if timeSinceUpdate.minute! >= uploadSchedule {
      uploadLocations()
    }
  }
  
  func updateUI(timeSinceUpdate: DateComponents, location: CLLocation) {
    let locationInfo = String(format: "%03d %02d:%02d",
                              self.locations.count,
                              timeSinceUpdate.minute!,
                              timeSinceUpdate.second! % 60)
    
    updateLocationCounter.text = locationInfo
    print(locationInfo, location)
    
    // Add marker to map only if app is in foreground
    if UIApplication.shared.applicationState == .active {
      mapView.showAnnotations(self.annotations, animated: true)
    }
  }
}
