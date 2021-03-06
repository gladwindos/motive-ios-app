//
//  DetailViewController.swift
//  uni_events
//
//  Created by Gladwin Dosunmu on 30/06/2016.
//  Copyright © 2016 Gladwin Dosunmu. All rights reserved.
//

import UIKit
import Lock
import SimpleKeychain
import Auth0
import Alamofire
import Toast_Swift

class DetailViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var date: UILabel!
    
    @IBOutlet weak var poster: UIImageView!
    
    @IBOutlet weak var main_description: UILabel!
    
    @IBOutlet weak var venue: UILabel!
    
    
    @IBOutlet weak var findTickets: UIButton!
    
    func UserInEventFavourites(event: Event, user: User) -> Bool {
        if let userId =  user.profile?.userId {
            if event.favourites_ids.contains(userId) && userId.characters.count > 0 {
                
                return true
            }
        }
        return false
    }
    
    @IBAction func moreButton(sender: AnyObject) {
        
        let currentEvent = App.Memory.currentEvent
        let currentUser = App.Memory.currentUser
        
        let actionSheetController: UIAlertController = UIAlertController(title: "Options", message: "", preferredStyle: .ActionSheet)
        
        let cancelActionButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
        }
        actionSheetController.addAction(cancelActionButton)
        
        var addOrRemove = ""
        
        var toastMessage = ""
        
        if UserInEventFavourites(currentEvent, user: currentUser) {
            addOrRemove = "Remove from"
            toastMessage = "Removed from"
        } else {
            addOrRemove = "Add to"
            toastMessage = "Added to"
        }
        
        
        let FavouritesActionButton: UIAlertAction = UIAlertAction(title: "\(addOrRemove) favourites", style: .Default)
        { action -> Void in
            
            //            let url = "http://127.0.0.1:8000/api/events/\(currentEvent.id)/update-favourites/"
            
            if currentUser.loggedIn == false {
                
                self.view.makeToast("Please login to add this event to your favourites.", duration: 3.0, position: .Center)
            } else {
                
                let url = "\(App.Memory.apiUrl)api/events/\(currentEvent.id)/update-favourites/"
                
                let parameters = ["auth0_favourite_ids" : currentUser.profile!.userId]
                
                let headers = ["Accept": "application/json"]
                
                Alamofire.request(.PUT, url, parameters: parameters, encoding: .JSON, headers: headers)
                    .responseJSON { response in
                        debugPrint(response)
                        
                        self.view.makeToast("\(toastMessage) favourites", duration: 3.0, position: .Center)
                }
                
                if self.UserInEventFavourites(currentEvent, user: currentUser) {
                    // user has just been removed from favourites
                    currentEvent.favourites_ids.removeObject(currentUser.profile!.userId)
                    
                    let scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications
                    
                    for oneEvent in scheduledNotifications! {
                        let oldNotification = oneEvent as UILocalNotification
                        let userInfoCurrent = oldNotification.userInfo! as? [String:AnyObject]
                        let eventId = userInfoCurrent!["eventId"]! as? Int
                        if eventId == currentEvent.id {
                            UIApplication.sharedApplication().cancelLocalNotification(oldNotification)
                        } else {
                            
                        }
                    }
                    
                } else {
                    // User added to favourites
                    currentEvent.favourites_ids.append(currentUser.profile!.userId)
                    
                    // Add notification for this event

                    let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
                    
                    UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                    
                    let notification = UILocalNotification()
                    
                    let calender = NSCalendar.currentCalendar()
                    
                    let fireDate = calender.dateByAddingUnit(.Day, value: -1, toDate: currentEvent.start_date, options: [])
                    
                    notification.fireDate = fireDate
                    
                    notification.alertBody = "\(currentEvent.title) is tomorrow! Are you ready to turn up?"
                    
                    notification.alertAction = "view"
                    
                    notification.soundName = UILocalNotificationDefaultSoundName
                    
                    notification.userInfo = ["eventId": currentEvent.id]
                    
                    UIApplication.sharedApplication().scheduleLocalNotification(notification)
                }
            }
        }
        actionSheetController.addAction(FavouritesActionButton)
        
        let ShareActionButton: UIAlertAction = UIAlertAction(title: "Share", style: .Default)
        { action -> Void in
            let aVC = UIActivityViewController(activityItems: ["Check out \"\(App.Memory.currentEvent.title)\" on Motive!", self.poster.image!,"https://itunes.apple.com/gb/app/motive/id1141018976?ls=1&mt=8"], applicationActivities: nil)
            
            self.presentViewController(aVC, animated: true, completion: nil)
        }
        actionSheetController.addAction(ShareActionButton)
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        scrollView.delegate = self
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.viewDidLoad), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        let currentEvent = App.Memory.currentEvent
        
        if let eventTitle : String? = currentEvent.title {
            
            self.title = eventTitle
            
        }
        if let eventDate : String? = Utilities.myDateTimeFormatter(currentEvent.start_date) {
            date.text = eventDate
        }
        if let eventDescription : String? = currentEvent.main_description {
            main_description.text = eventDescription
        }
        if let eventVenue : String? = currentEvent.venue_name + "\n" + currentEvent.venue_address + "\n" + currentEvent.venue_city + "\n" + currentEvent.venue_postcode {
            venue.text = eventVenue
        }
        
        poster.image = nil
        backgroundImage.image = nil
        
        if let imageUrl : String? = currentEvent.posterUrl {
            
            NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: imageUrl!)!, completionHandler: { (data, response, error) in
                
                if error != nil {
                    print(error!)
                    return
                }
                
                let image = UIImage(data: data!)
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.poster.image = image
                    self.backgroundImage.image = image
                    
                })
                
                
            }).resume()
        }
        
        App.Memory.myNotificationCenter.sentFromNotification = false

    }
    
    override func viewDidAppear(animated: Bool) {
        
        
        if let eventTitle : String = App.Memory.currentEvent.title {
            
            var fontSize : CGFloat = 17
            
            if self.title!.characters.count >= 17 {
                
                fontSize = 14
            }
            
            self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont.systemFontOfSize(fontSize, weight: UIFontWeightSemibold),  NSForegroundColorAttributeName: UIColor.whiteColor()]
        }
    }
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        findTickets.alpha = 0.4
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        findTickets.alpha = 1.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
