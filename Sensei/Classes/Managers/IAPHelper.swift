//
//  IAPHelper.swift
//  habi-v2
//
//  Created by Sergey Sheba on 3/21/16.
//  Copyright © 2016 Thinkmobiles. All rights reserved.
//

import UIKit
import StoreKit

protocol IAPurchaseDelegate: class {
    
    func didPurchase(identifier productIdentifier: String, transaction: SKPaymentTransaction, success: Bool, error: NSError?)
}

class IAPHelper: NSObject {

    typealias RequestProductCompletitionHandler = (success: Bool, products: [SKProduct]?) -> Void

    weak var delegate: IAPurchaseDelegate?
    
    private var productRequest: SKProductsRequest?
    private var completitionHadler: RequestProductCompletitionHandler?
    private var productIdentifiers: Set<String>
    private var purchasedProductIdentifiers = Set<String>()
    private var productIdentifierToRestore: String?
    
    init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
        
        for prodIdentifier in self.productIdentifiers {
            if let productPurchased: Bool = NSUserDefaults.standardUserDefaults().boolForKey(prodIdentifier) {
                if productPurchased {
                    self.purchasedProductIdentifiers.insert(prodIdentifier)
                    print("Prev purchased: \(prodIdentifier)")
                } else {
                    print("Not purchased: \(prodIdentifier)")
                }
            }
        }
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
    func requestProducts(completion: RequestProductCompletitionHandler) {
        completitionHadler = completion
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest?.delegate = self
        productRequest?.start()
    }
    
    
    func buyProduct(product: SKProduct) {
        print("Buying \(product.productIdentifier)")
        addLoader()
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    func isProductPurchased(productIdentifier: String) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    func restorePurchaseWithIdentifier(productIdentifier: String) {
        let loader = LoaderView()
        UIApplication.sharedApplication().keyWindow?.addSubview(loader)

        productIdentifierToRestore = productIdentifier
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    func getFormattedLocalePrice(product: SKProduct) -> String {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.formatterBehavior = .Behavior10_4
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.locale = product.priceLocale
        let formattedPrice = numberFormatter.stringFromNumber(product.price)!
        return formattedPrice
    }
}

extension IAPHelper: SKPaymentTransactionObserver {
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        removeLoader()
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        removeLoader()
        
        for transaction in transactions {
            switch transaction.transactionState {
                case .Purchased:
                    completeTransaction(transaction)
                case .Failed:
                    failedTransaction(transaction)
                case .Restored:
                    restoreTransaction(transaction)
                default:
                    print("nothing")
            }
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func completeTransaction(transaction: SKPaymentTransaction) {
        provideContentForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        delegate?.didPurchase(identifier: transaction.payment.productIdentifier, transaction: transaction, success: true, error: nil)
    }
    
    func restoreTransaction(transaction: SKPaymentTransaction) {
        provideContentForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        if transaction.payment.productIdentifier == productIdentifierToRestore {
            delegate?.didPurchase(identifier: transaction.payment.productIdentifier, transaction: transaction, success: true, error: nil)
        }
    }
    
    func failedTransaction(transaction: SKPaymentTransaction) {
        if let url = NSBundle.mainBundle().appStoreReceiptURL {
            let data = NSData(contentsOfURL: url)
            print(data)
        }
        let isCancelled = transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue
        if isCancelled {
            print(String(format: "Transaction error: %@", transaction.error!.localizedDescription))
        }
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        delegate?.didPurchase(identifier: transaction.payment.productIdentifier, transaction: transaction, success: false, error: isCancelled ? nil : transaction.error)
    }
    
    func provideContentForProductIdentifier(productIdentifier: String) {
        purchasedProductIdentifiers.insert(productIdentifier)
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}

extension IAPHelper: SKProductsRequestDelegate {
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let skProducts = response.products
        for skProduct in skProducts {
            print(String(format: "Found products %@ %@ %@", skProduct.productIdentifier, skProduct.localizedTitle, getFormattedLocalePrice(skProduct)))
        }
        if let completion = completitionHadler {
            completion(success: true, products: skProducts)
        }
    }
    
    func request(request: SKRequest, didFailWithError error: NSError) {
        print(String(format: "Failed to load list with products %@", error.localizedDescription))
        if let completion = completitionHadler {
            completion(success: false, products: nil)
        }
    }
}
