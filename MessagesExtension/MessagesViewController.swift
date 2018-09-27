//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Morten Bertz on 9/14/16.
//  Copyright © 2016 telethon k.k. All rights reserved.
//

import UIKit
import Messages

//project setup according to https://developer.apple.com/library/content/qa/qa1936/_index.html


class MessagesViewController: MSMessagesAppViewController,UISearchBarDelegate {
    var stickerBrowser:StickerBrowserController?
    
    var shouldActivateSearchbar:Bool = false
    var shouldBecomeFirstResponer:Bool = true
    let maxCallouts=10
    
    lazy var queue: OperationQueue = {
        let q=OperationQueue()
        q.name="APNG Render Queue"
        q.qualityOfService = .userInitiated
        return q
    }()
    
    var urls:[URL]=[URL](){
        didSet{
            self.stickerBrowser?.stickerPaths=urls
        }
    }
    lazy var imageURLS: [URL] = {
        let temp=URL(fileURLWithPath: NSTemporaryDirectory())
        if let urls=try? FileManager.default.contentsOfDirectory(at: temp, includingPropertiesForKeys: [.addedToDirectoryDateKey,.isDirectoryKey], options: [.skipsHiddenFiles]){
            let sorted=urls.sorted(by: {url1, url2 in
                if  let values1 = try? url1.resourceValues(forKeys: Set([.addedToDirectoryDateKey])),
                    let values2 = try? url2.resourceValues(forKeys: Set([.addedToDirectoryDateKey])),
                    let date1=values1.addedToDirectoryDate,
                    let date2=values2.addedToDirectoryDate
                {
                   return date1>date2
                    
                }
                
                return true
            })
            let filtered=sorted.filter({url in
                if  let value = try? url.resourceValues(forKeys: Set([.isDirectoryKey])),
                    let isDirectory=value.isDirectory{
                    
                    return !isDirectory
                }
                return false
            })
             return filtered
        }
       return [URL]()
    }()
    
    
    @IBOutlet var searchBar:UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.searchBar.tintColor=UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor=UIColor.white
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        if let child=self.children.first as? StickerBrowserController  {
            self.stickerBrowser=child
        }
        if self.imageURLS.count == 0{
            let renderOP=CalloutRenderOperation(text: NSLocalizedString("Please Enter Text!", comment: "Prompt"), completion: {outURL in
                if let url=outURL{
                    DispatchQueue.main.async {
                        self.urls.append(url)
                    }
                }
            })
            self.queue.addOperation(renderOP)
        }
        else if self.imageURLS.count>maxCallouts{
            self.urls=Array(self.imageURLS[0..<maxCallouts])
            let URLSToDelete=self.imageURLS[maxCallouts..<self.imageURLS.indices.last!]
            
            DispatchQueue.global(qos: .background).async {
                do{
                    try URLSToDelete.forEach{try FileManager.default.removeItem(at: $0)}
                }catch let error{
                    print(error)
                }
            }
            
        }
        else{
            self.urls=self.imageURLS
        }
        self.searchBar.returnKeyType = .done

    }
    
    override func didResignActive(with conversation: MSConversation) {
        
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        switch presentationStyle {
        case .compact:
            _=self.searchBar!.resignFirstResponder()
            
        case .expanded:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+DispatchTimeInterval.milliseconds(50), execute:{
                _=self.searchBar?.becomeFirstResponder()
            })
        default:
            break
           
        
        }
    
        
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if self.presentationStyle != .expanded{
             self.requestPresentationStyle(.expanded)
            return false
            
        }
        else{
            return true
        }        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
//        if let characters=searchBar.text!.kanjiCharacterLiterals().array as? [String]{
//            self.updateDisplay(kanji: characters)
//        }
        self.shouldActivateSearchbar=false
        if let text=searchBar.text, text.count>0{
            let renderOP=CalloutRenderOperation(text: text, completion: {outURL in
                if let url=outURL{
                    DispatchQueue.main.async {
                        self.urls.insert(url, at: self.urls.indices.first!)
                    }
                }
            })
            self.queue.addOperation(renderOP)
        }
       
        
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        self.shouldBecomeFirstResponer=true
        return true
    }



}
