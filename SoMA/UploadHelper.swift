//
//  UploadHelper.swift
//  SoMA
//
//  Created by asdf on 5/11/17.
//  Copyright © 2017 asdf. All rights reserved.
//

import Foundation
import Alamofire

class UploadHelper {
    
    static func uploadLocations(parameters: Parameters) -> [String: String] {
        Alamofire.request(
            "https://soma.uni-koblenz.de/api",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
            ).responseJSON { response in
                print(response.result)
                debugPrint(response)
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
            }

        return ["a": "1"]
    }
    
    
}
