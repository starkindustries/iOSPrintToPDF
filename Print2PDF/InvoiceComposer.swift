//
//  InvoiceComposer.swift
//  Print2PDF
//
//  Created by Zion Perez on 11/27/17.
//  Copyright © 2017 Appcoda. All rights reserved.
//

import UIKit

class InvoiceComposer: NSObject {
    
    let pathToInvoiceHTMLTemplate = Bundle.main.path(forResource: "invoice", ofType: "html")
    
    let pathToSingleItemHTMLTemplate = Bundle.main.path(forResource: "single_item", ofType: "html")
    
    let pathToLastItemHTMLTemplate = Bundle.main.path(forResource: "last_item", ofType: "html")
    
    let senderInfo: String = "Gabriel Theodoropoulos<br>123 Somewhere Str.<br>10000 - MyCity<br>MyCountry"
    
    let dueDate: String = ""
    
    let paymentMethod: String = "Wire Transfer"
    
    let logoImageURL: String = "http://www.appcoda.com/wp-content/uploads/2015/12/blog-logo-dark-400.png"
    
    var invoiceNumber: String!
    
    var pdfFilename: String!
    
    override init() {
        super.init()
    }
    
    func exportHTMLContentToPDF(HTMLContent: String) {
        let printPageRenderer = CustomPrintPageRenderer()
        
        let printFormatter = UIMarkupTextPrintFormatter(markupText: HTMLContent)
        printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        // old: printPageRenderer.addPrintFormatter(printFormatter, startingAtPageAtIndex: 0)
        
        let pdfData = drawPDFUsingPrintPageRenderer(printPageRenderer: printPageRenderer)
        
        pdfFilename = "\(AppDelegate.getAppDelegate().getDocDir())/Invoice\(invoiceNumber).pdf"
        pdfData?.write(toFile: pdfFilename, atomically: true)
        
        print(pdfFilename)
    }
    
    func drawPDFUsingPrintPageRenderer(printPageRenderer: UIPrintPageRenderer) -> NSData! {
        let data = NSMutableData()
        
        UIGraphicsBeginPDFContextToData(data, CGRect.zero, nil)
        // old: UIGraphicsBeginPDFContextToData(data, CGRectZero, nil)
        
        UIGraphicsBeginPDFPage()
        
        printPageRenderer.drawPage(at: 0, in: UIGraphicsGetPDFContextBounds())
        // old: printPageRenderer.drawPageAtIndex(0, inRect: UIGraphicsGetPDFContextBounds())
        
        UIGraphicsEndPDFContext()
        
        return data
    }
    
    func renderInvoice(invoiceNumber: String, invoiceDate: String, recipientInfo: String, items: [[String: String]], totalAmount: String) -> String! {
        // Store the invoice number for future use.
        self.invoiceNumber = invoiceNumber
        
        do {
            // Load the invoice HTML template code into a String variable.
            var HTMLContent = try String(contentsOfFile: pathToInvoiceHTMLTemplate!)
            
            // Replace all the placeholders with real values except for the items.
            // The logo image.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#LOGO_IMAGE#", with: logoImageURL)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#LOGO_IMAGE#", withString: logoImageURL)
            
            // Invoice number.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#INVOICE_NUMBER#", with: invoiceNumber)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#INVOICE_NUMBER#", withString: invoiceNumber)
            
            // Invoice date.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#INVOICE_DATE#", with: invoiceDate)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#INVOICE_DATE#", withString: invoiceDate)
            
            // Due date (we leave it blank by default).
            HTMLContent = HTMLContent.replacingOccurrences(of: "#DUE_DATE#", with: dueDate)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#DUE_DATE#", withString: dueDate)
            
            // Sender info.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#SENDER_INFO#", with: senderInfo)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#SENDER_INFO#", withString: senderInfo)
            
            // Recipient info.
            let recipientInfoTemp: String = recipientInfo.replacingOccurrences(of: "\n", with: "<br>")
            HTMLContent = HTMLContent.replacingOccurrences(of: "#RECIPIENT_INFO#", with: recipientInfoTemp)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#RECIPIENT_INFO#", withString: recipientInfo.stringByReplacingOccurrencesOfString("\n", withString: "<br>"))
            
            // Payment method.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#PAYMENT_METHOD#", with: paymentMethod)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#PAYMENT_METHOD#", withString: paymentMethod)
            
            // Total amount.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#TOTAL_AMOUNT#", with: totalAmount)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#TOTAL_AMOUNT#", withString: totalAmount)
            
            // The invoice items will be added by using a loop.
            var allItems = ""
            
            // For all the items except for the last one we'll use the "single_item.html" template.
            // For the last one we'll use the "last_item.html" template.
            for i in 0..<items.count {
                var itemHTMLContent: String!
                
                // Determine the proper template file.
                if i != items.count - 1 {
                    itemHTMLContent = try String(contentsOfFile: pathToSingleItemHTMLTemplate!)
                }
                else {
                    itemHTMLContent = try String(contentsOfFile: pathToLastItemHTMLTemplate!)
                }
                
                // Replace the description and price placeholders with the actual values.
                itemHTMLContent = itemHTMLContent.replacingOccurrences(of: "#ITEM_DESC#", with: items[i]["item"]!)
                // old: itemHTMLContent = itemHTMLContent.stringByReplacingOccurrencesOfString("#ITEM_DESC#", withString: items[i]["item"]!)
                
                // Format each item's price as a currency value.
                let formattedPrice = AppDelegate.getAppDelegate().getStringValueFormattedAsCurrency(items[i]["price"]!)
                itemHTMLContent = itemHTMLContent.replacingOccurrences(of: "#PRICE#", with: formattedPrice)
                // old: itemHTMLContent = itemHTMLContent.stringByReplacingOccurrencesOfString("#PRICE#", withString: formattedPrice)
                
                // Add the item's HTML code to the general items string.
                allItems += itemHTMLContent
            }
            
            // Set the items.
            HTMLContent = HTMLContent.replacingOccurrences(of: "#ITEMS#", with: allItems)
            // old: HTMLContent = HTMLContent.stringByReplacingOccurrencesOfString("#ITEMS#", withString: allItems)
            
            // The HTML code is ready.
            return HTMLContent
        }
        catch {
            print("Unable to open and use HTML template files.")
        }
        
        return nil
    }
}
