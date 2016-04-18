//
//  ViewController.swift
//  FFJLoadButton
//
//  Created by Vito on 01/19/2016.
//  Copyright (c) 2016 Vito. All rights reserved.
//

import UIKit
import FFJLoadButton

class ViewController: UIViewController {

    @IBOutlet weak var succeedButton: FFJLoadButton!
    @IBOutlet weak var failedButton: FFJLoadButton!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        succeedButton.readyTitle = "Button Will Succeed"
        failedButton.readyTitle = "Button Will Fail"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func succeed(sender: AnyObject) {
        self.succeedButton.startLoad()
        
        let string: String = self.randomString()
        let imageURL = NSURL.init(string: "https://placeholdit.imgix.net/~text?txtsize=42&txt=\(string)&w=500&h=500")
        NSURLSession.sharedSession().dataTaskWithURL(imageURL!) { (imageData, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let _ = error {
                    self.imageView.image = nil
                    self.succeedButton.endLoad(false)
                    return
                }
                self.imageView.image = UIImage.init(data: imageData!)
                self.succeedButton.endLoad(true)
            })
        }.resume()
    }
    
    @IBAction func failed(sender: AnyObject) {
        self.failedButton.startLoad()
        
        let urlconfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        urlconfig.timeoutIntervalForRequest = 5
        urlconfig.timeoutIntervalForResource = 5
        let imageURL = NSURL.init(string: "https://fakeurl.com")
        let session = NSURLSession(configuration: urlconfig, delegate: nil, delegateQueue: nil)
        session.dataTaskWithURL(imageURL!) { (imageData, response, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let _ = error {
                    self.imageView.image = nil
                    self.failedButton.endLoad(false)
                }
            })
        }.resume()
    }
    
    func randomString() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        let n = UInt32(letters.characters.count)
        var string = ""
        for _ in 0..<12 {
            let index = letters.startIndex.advancedBy(Int(arc4random_uniform(n)))
            string.append(letters[index])
        }
        return string
    }
}

