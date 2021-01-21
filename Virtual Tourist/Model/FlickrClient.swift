//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Asma  on 1/20/21.
//

import Foundation
class FlickrClient {
    
    static let apiKey="67070e493e0b76ac7944a23c624f97af"
    static let apiSecret="abc32ba9d808b6b5"
    static let baseURL="https://www.flickr.com/services/rest/?method=flickr.photos.search&"
    
    class func getPhotos(lat:Double, long:Double, completion: @escaping (FlickrResponse?, Error?) -> Void) {
        var composedUrlString=baseURL+"api_key="+apiKey+"&format=json&nojsoncallback=1&extras=url_n&safe_search=1&page=1&per_page=30"
        composedUrlString+="&lat="+String(lat)+"&lon="+String(long)
        let url=URL(string: composedUrlString)!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(FlickrResponse.self, from: data)
                
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                /*do {
                    print(String(data: data, encoding: .utf8)!)
                    let errorResponse = try decoder.decode(UdacityResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }*/
            }
        }
        task.resume()
    }
    
    class func getPhotoFromURL(url:URL,completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            completion(data, nil)
            
        }
        task.resume()
    }
    
}
