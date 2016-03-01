//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

class HTMLElement {
    let name: String
    let text: String?
    
    lazy var asHTML: Void -> String = {
        [unowned self] in
        if let text = self.text {
            return "<\(self.name)>\(text)<\(self.name)"
        } else {
            return "<\(self.name)>"
        }
    }
    
    init(name: String, text: String? = nil) {
        self.name = name
        self.text = text
    }
    
    deinit {
        print("\(name) is being deinitialized")
    }
}

var elem = HTMLElement(name: "p", text: "This is some text")
print("HTML: \(elem.asHTML())")


let heading = HTMLElement(name: "h1")
let defaultText = "some default text"
heading.asHTML = {
    return "<\(heading.name)>\(heading.text ?? defaultText)/<\(heading.name)>"
    //""
 }

print(heading.asHTML())

let secs = 4.435987
let format = "Seconds: %02.3f"
let formatted = String(format: format, arguments:[secs])


let offset = formatted.rangeOfString(".")
let distance = formatted.startIndex.distanceTo((offset?.endIndex)!)
let decText = String(formatted.characters.dropFirst(distance))
print(decText)

//public struct NumberGroup: CustomPlaygroundQuickLookable {
//	var numbers = [Int]()
//	public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
//		if let max = numbers.maxElement() {
//			var counts = Array(count: max + 1, repeatedValue:0)
//			for item in numbers {
//				counts[item]++
//			}
//			return PlaygroundQuickLook.Image(BarChart(counts))
//		}
//		return PlaygroundQuickLook.Text("Numbers are not initialized")
//	}
//}

//var group = NumberGroup()
//for index in 0...50 {
//	group.numbers.append(Int(arc4random_uniform(10)))
//}
//
//group.numbers
//
//group




