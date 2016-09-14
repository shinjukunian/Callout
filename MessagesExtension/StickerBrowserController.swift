//
//  StickerBrowserController.swift
//  KanjiLookup
//
//  Created by Morten Bertz on 6/20/16.
//  Copyright © 2016 Morten Bertz. All rights reserved.
//

import Messages

class StickerBrowserController: MSStickerBrowserViewController {

    var stickerPaths:[URL]=[]{
        didSet {
            self.stickerBrowserView.reloadData()
            }
    }
    
    override func viewDidLoad() {
        self.stickerBrowserView.backgroundColor=nil
        
    }
    
    override func numberOfStickers(in stickerBrowserView: MSStickerBrowserView) -> Int {
        return self.stickerPaths.count
    }
    override func stickerBrowserView(_ stickerBrowserView: MSStickerBrowserView, stickerAt index: Int) -> MSSticker {

        let url=self.stickerPaths[index];
        let desc=url.deletingPathExtension().lastPathComponent
        let sticker=try? MSSticker.init(contentsOfFileURL:url, localizedDescription: desc)
        return sticker!;
    }
    
}


