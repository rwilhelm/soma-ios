//
//  LocationDelegate.swift
//  SoMA
//
//  Created by asdf on 5/20/17.
//  Copyright © 2017 asdf. All rights reserved.
//

import Foundation


// MARK: - CLLocationManagerDelegate methods
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Return if there are no recent locations.
        guard let lastLocation = locations.last else {
            return
        }
        
        storeLocation(location: lastLocation)
        makeAnnotation(location: lastLocation)
        checkUploadSchedule(timeSinceUpdate: lastUpdate())
        updateUI(timeSinceUpdate: lastUpdate(), location: lastLocation)
    }
    
    // This is called if:
    // - the location manager is updating, and
    // - it WASN'T able to get the user's location.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
}

