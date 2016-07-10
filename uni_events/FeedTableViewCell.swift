//
//  FeedTableViewCell.swift
//  uni_events
//
//  Created by Gladwin Dosunmu on 21/06/2016.
//  Copyright © 2016 Gladwin Dosunmu. All rights reserved.
//

import UIKit

class FeedTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var location: UILabel!
    
    @IBOutlet weak var poster: UIImageView!
    
    @IBOutlet weak var cellImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    var imageCache = NSCache()
    
    func updateUI(indexPath: NSIndexPath) {
        
        
        
        let allEvents = App.Memory.sortedEvents
        
        if let eventTitle : String = allEvents![indexPath.section][indexPath.row].title {
            self.title.text = eventTitle
        }
        if let eventLocation : String? = allEvents![indexPath.section][indexPath.row].venue_name {
            self.location.text = eventLocation
        }
        
        self.poster.image = nil
        self.cellImageView.image = nil
        
        if let imageUrl : String? = allEvents![indexPath.section][indexPath.row].posterUrl {
            
            if let image = imageCache.objectForKey(imageUrl!) as? UIImage {
                
                self.poster.image = image
                self.cellImageView.image = image
            } else {
                
                NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: imageUrl!)!, completionHandler: { (data, response, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    let image = UIImage(data: data!)
                    
                    self.imageCache.setObject(image!, forKey: imageUrl!)
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.poster.image = image
                        self.cellImageView.image = image
                        
                    })
                    
                    
                }).resume()
            }
        }
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        if (UIScreen.mainScreen().bounds.size.height <= 568) {
            self.frame.size.height = 125.1
        } else {
            self.frame.size.height = 147
        }
    }
    
    
}
