//
//  ViewController.swift
//  UXVideoPlayerView
//
//  Created by Deepak Goyal on 01/04/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func btnShowVideo(_ sender: Any) {
        
        let viewController = UXPlayerViewController(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!)
        self.present(viewController, animated: true)
    }
    
}

