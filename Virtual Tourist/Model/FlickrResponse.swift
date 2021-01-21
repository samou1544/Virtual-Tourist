//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/20/21.
//

import Foundation

struct FlickrResponse:Decodable {
    let photos:FlickrPhoto
}
struct FlickrPhoto:Decodable {
    let photo:[Photo]
    
}
struct Photo:Decodable {
    let url_n:String
    
}
