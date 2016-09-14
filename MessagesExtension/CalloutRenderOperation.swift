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
    fileprivate lazy var path: URL = {
        let temp=URL(fileURLWithPath: NSTemporaryDirectory())
        let name=NSUUID().uuidString
        let path=temp.appendingPathComponent(name, isDirectory: false).appendingPathExtension("png")
        return path
    }()
    let size=CGSize(width: 206, height: 206)
    var fontSize:CGFloat=40
    fileprivate lazy var attributes:[String:AnyObject] = {
        let font=UIFont.init(name: "AmericanTypewriter-Bold", size: self.fontSize)
        let style=NSMutableParagraphStyle()
        style.alignment=NSTextAlignment.center
        style.lineBreakMode=NSLineBreakMode.byWordWrapping
        let at:[String:AnyObject]=[NSFontAttributeName:font!,
                NSForegroundColorAttributeName:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                NSStrokeColorAttributeName:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
                NSStrokeWidthAttributeName:-4.0 as AnyObject,
                NSParagraphStyleAttributeName:style,
                ]
        return at
    }()
    var completion:((URL?)->Void)
    var delay=0.5
    var minimumScaleFactor:CGFloat=0.5
    
    
    init(text:String,completion:@escaping ((URL?)->Void)) {
        self.text=text
        self.completion=completion
        super.init()
    }
    
    override func main() {
        let att=NSAttributedString(string: self.text, attributes: self.attributes)
        let options:NSStringDrawingOptions=[.usesLineFragmentOrigin,.usesFontLeading,.truncatesLastVisibleLine]

        

        
        var stringSize=att.boundingRect(with: self.size, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil)
        let ratio=stringSize.height/self.size.height
        if ratio>1{
            
            let font=self.attributes[NSFontAttributeName] as! UIFont
            let newFontSize=font.pointSize / (ratio<1/self.minimumScaleFactor ? ratio :1/self.minimumScaleFactor)
            let newFont=font.withSize(newFontSize)
            self.attributes[NSFontAttributeName]=newFont
            stringSize=att.boundingRect(with: self.size, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil)
            
        }

        
        var ranges=[(Range<String.Index>,String)]()
        let range:Range<String.Index>=self.text.characters.startIndex..<self.text.characters.endIndex
        self.text.enumerateSubstrings(in: range, options: [.byWords], {subString, range1, range2,_ in
            ranges.append((range2,subString!))
        })
        if ranges.count == 1 || self.text.characters.count<10{
            ranges.removeAll()
            self.text.enumerateSubstrings(in: range, options: [.byComposedCharacterSequences], {subString, range1, range2,_ in
                ranges.append((range2
                    ,subString!))
            })
        }
        ranges.append((range,self.text))
        
        ranges=ranges.filter({item in
            let substtring=self.text.substring(to: item.0.upperBound)
            let att=NSAttributedString(string: substtring, attributes: self.attributes)
            let bounding=att.boundingRect(with: stringSize.size, options:[.usesLineFragmentOrigin,.usesFontLeading] , context: nil)
            return bounding.height <= self.size.height
        })
        
        
        
        guard let apngRenderer=APNGEncoder.init(url: self.path, count: UInt(ranges.count)) else{
            self.completion(nil)
            return
        }
        
        let rect = stringSize.height > self.size.height ? CGRect(x: 0.0, y: 0.0, width: stringSize.width, height: self.size.height) : CGRect(x: 0, y: 0, width: stringSize.width, height: stringSize.height).integral
        for item in ranges{
            let substtring=self.text.substring(to: item.0.upperBound)
            let att=NSAttributedString(string: substtring, attributes: self.attributes)
            let bounding=att.boundingRect(with: rect.size, options:options , context: nil)
            
            let renderer=UIGraphicsImageRenderer.init(bounds: rect)
            if let image=renderer.image(actions: {c in
                att.draw(with: rect, options: options, context: nil)
            }).cgImage
                
            {
                apngRenderer.add(image, withDelay: self.delay)
            }

           
        }
        
        let renderer=UIGraphicsImageRenderer.init(bounds: rect)
        if let image=renderer.image(actions:{ c in}).cgImage{
            apngRenderer.add(image, withDelay: self.delay)
        }
        
        apngRenderer.finalize(completion: {out, error in
            if let url=out{
                self.completion(url)
            }
            
        })
        
        
        
    }
    
    
    
    
}
