//
//  FlickrResponse.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/20/21.
//

import Foundation

struct FlickrResponse:Decodable {
    let photos:FlickrPhotos
}
struct FlickrPhotos:Decodable {
    let photo:[FlickrPhoto]
    
}
struct FlickrPhoto:Decodable {
    let url_n:String
    
}
