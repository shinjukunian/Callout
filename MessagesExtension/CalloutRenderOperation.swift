//
//  CalloutRenderOperation.swift
//  Callout
//
//  Created by Morten Bertz on 9/14/16.
//  Copyright © 2016 telethon k.k. All rights reserved.
//

import UIKit
import APNG

class CalloutRenderOperation: Operation {

    var text:String
    lazy var path: URL = {
        let temp=URL(fileURLWithPath: NSTemporaryDirectory())
        let name=NSUUID().uuidString
        let path=temp.appendingPathComponent(name, isDirectory: false).appendingPathExtension("png")
        return path
    }()
    let size=CGSize(width: 206, height: 206)
    var fontSize:CGFloat=40
    lazy var attributes:[String:AnyObject] = {
        let font=UIFont.init(name: "AmericanTypewriter-Bold", size: self.fontSize)
        let style=NSMutableParagraphStyle()
        style.alignment=NSTextAlignment.center
        let at:[String:AnyObject]=[NSFontAttributeName:font!,
                NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                NSStrokeColorAttributeName:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
                NSStrokeWidthAttributeName:-4.0 as AnyObject,
                NSParagraphStyleAttributeName:style,
                ]
        return at
    }()
    var completion:((URL?)->Void)
    let delay=0.5
    
    
    
    init(text:String,completion:@escaping ((URL?)->Void)) {
        self.text=text
        self.completion=completion
        super.init()
    }
    
    override func main() {
        let att=NSAttributedString(string: self.text, attributes: self.attributes)
        let stringSize=att.boundingRect(with: self.size, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil)
//        var scale:CGFloat=1.0
//        if stringSize.height > self.size.height{
//            scale=stringSize.height/self.size.height
//        }
        var ranges=[(Range<String.Index>,String)]()
        let range:Range<String.Index>=self.text.characters.startIndex..<self.text.characters.endIndex
        self.text.enumerateSubstrings(in: range, options: [.byWords], {subString, range1, range2,_ in
            ranges.append((range2,subString!))
        })
        if ranges.count == 1{
            self.text.enumerateSubstrings(in: range, options: [.byComposedCharacterSequences], {subString, range1, range2,_ in
                ranges.append((range2
                    ,subString!))
            })
        }
        
        let apngRenderer=APNGEncoder.init(url: self.path, count: UInt(ranges.count))
        let rect=CGRect(x: 0, y: 0, width: stringSize.width, height: stringSize.height)
        for item in ranges{
            let renderer=UIGraphicsImageRenderer.init(bounds: rect)
            if let image=renderer.image(actions: {c in
                let substtring=self.text.substring(to: item.0.upperBound)
                let att=NSAttributedString(string: substtring, attributes: self.attributes)
                let bounding=att.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil)
                att.draw(in: bounding)
            }).cgImage
                
            {
              apngRenderer?.add(image, withDelay: self.delay)
            }
        }
        apngRenderer?.finalize(completion: {out, error in
            if let url=out{
                self.completion(url)
            }
            
        })
        
        
        
    }
    
    
    
    
}
