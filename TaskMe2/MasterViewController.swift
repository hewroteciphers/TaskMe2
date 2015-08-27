//
//  MasterViewController.swift
//  TaskMe2
//
//  Created by Chris Wee on 7/23/15.
//  Copyright (c) 2015 Weetopia. All rights reserved.
//

import UIKit
import SwiftyDropbox


class MasterViewController: UITableViewController {

    var objects = [AnyObject]()
    var viewModel = ELLPowerLogDownloadService.init()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        //
        //        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        //        self.navigationItem.rightBarButtonItem = addButton
        
        viewModel.startPowerLogDownload()       //Load private framework and get access to SQL diagnostics.
        
        println("viewDidLoad")
    }
    

    //When user presses Link to Dropbox button
    @IBAction func linkToDropbox(sender: UIButton) {
    
        if (Dropbox.authorizedClient == nil) {
            Dropbox.authorizeFromController(self)
        } else {
            println("User is already authorized!")
        }
    }

    //When user shares compressed sql file
    @IBAction func shareLogFile(sender: UIBarButtonItem) {
        
        //NSLog("SQL file is %s", viewModel.compressSqlFiles)
  
        
        
        // Verify user is logged into Dropbox
        if let client = Dropbox.authorizedClient {
            
            // Get the current user's Dropbox account info
            client.usersGetCurrentAccount().response { response, error in
                if let account = response {
                    println("Hello \(account.name.givenName)")
                } else {
                    println(error!)
                }
            }
        

            
            // Upload a file
            let now_text = "From ShareLogFile"
            let fileData = now_text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            client.filesUpload(path: "/TaskMe2.txt", autorename: false, body: fileData!).response { response, error in
                if let metadata = response {
                    println("Uploaded file name: \(metadata.name)")
                    println("Uploaded file revision: \(metadata.rev)")
                } else {
                    println(error!)
                }
            }
        }
        
    }
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        
        let now = NSDate()
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = .ShortStyle
        let now_text = formatter.stringFromDate(now)
        
        objects.insert(now, atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let object = objects[indexPath.row] as! NSDate
            (segue.destinationViewController as! DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        let object = objects[indexPath.row] as! NSDate
        cell.textLabel!.text = object.description
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

