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
    fileprivate lazy var attributes:[NSAttributedStringKey:AnyObject] = {
        let font=UIFont.init(name: "AmericanTypewriter-Bold", size: self.fontSize)
        let style=NSMutableParagraphStyle()
        style.alignment=NSTextAlignment.center
        style.lineBreakMode=NSLineBreakMode.byWordWrapping
        let at:[NSAttributedStringKey:AnyObject]=[NSAttributedStringKey.font:font!,
                                                  NSAttributedStringKey.foregroundColor:#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1),
                                                  NSAttributedStringKey.strokeColor:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1),
                                                  NSAttributedStringKey.strokeWidth:-4.0 as AnyObject,
                                                  NSAttributedStringKey.paragraphStyle:style,
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
            
            let font=self.attributes[NSAttributedStringKey.font] as! UIFont
            let newFontSize=font.pointSize / (ratio<1/self.minimumScaleFactor ? ratio :1/self.minimumScaleFactor)
            let newFont=font.withSize(newFontSize)
            self.attributes[NSAttributedStringKey.font]=newFont
            stringSize=att.boundingRect(with: self.size, options: [.usesLineFragmentOrigin,.usesFontLeading], context: nil)
            
        }

        
        var ranges=[(Range<String.Index>,String)]()
        let range:Range<String.Index>=self.text.startIndex..<self.text.endIndex
        self.text.enumerateSubstrings(in: range, options: [.byWords], {subString, range1, range2,_ in
            ranges.append((range2,subString!))
        })
        if ranges.count == 1 || self.text.count<10{
            ranges.removeAll()
            self.text.enumerateSubstrings(in: range, options: [.byComposedCharacterSequences], {subString, range1, range2,_ in
                ranges.append((range2
                    ,subString!))
            })
        }
        ranges.append((range,self.text))
        
        ranges=ranges.filter({item in
            let substring=self.text.prefix(upTo: item.0.upperBound)
            let att=NSAttributedString(string: String(substring), attributes: self.attributes)
            let bounding=att.boundingRect(with: stringSize.size, options:[.usesLineFragmentOrigin,.usesFontLeading] , context: nil)
            return bounding.height <= self.size.height
        })
        
        
        
        guard let apngRenderer=APNGEncoder.init(url: self.path, count: UInt(ranges.count)) else{
            self.completion(nil)
            return
        }
        
        var blankAttributes=self.attributes
        blankAttributes[NSAttributedStringKey.foregroundColor]=UIColor.clear
        blankAttributes[NSAttributedStringKey.strokeColor]=UIColor.clear
        blankAttributes[NSAttributedStringKey.strokeWidth]=nil
        
        let rect = stringSize.height > self.size.height ? CGRect(x: 0.0, y: 0.0, width: stringSize.width, height: self.size.height) : CGRect(x: 0, y: 0, width: stringSize.width, height: stringSize.height).integral
        for item in ranges{
            
            let substring=self.text.prefix(upTo: item.0.upperBound)
            let att1=NSAttributedString(string: String(substring), attributes: self.attributes)
            let remainder=self.text.suffix(from: item.0.upperBound)
            let att2=NSAttributedString(string: String(remainder), attributes: blankAttributes)
            let drawString=NSMutableAttributedString(attributedString: att1)
            drawString.append(att2)
            let renderer=UIGraphicsImageRenderer.init(bounds: rect)
            if let image=renderer.image(actions: {c in
                drawString.draw(with: rect, options: options, context: nil)
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
