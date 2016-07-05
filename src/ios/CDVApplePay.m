#import "CDVApplePay.h"
#import <Stripe/Stripe.h>
#import <Stripe/STPAPIClient.h>
#import <Stripe/STPCardBrand.h>
#import <PassKit/PassKit.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>


@implementation CDVApplePay

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    NSString * StripePublishableKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"StripePublishableKey"];
    merchantId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ApplePayMerchant"];
    [Stripe setDefaultPublishableKey:StripePublishableKey];
    self = (CDVApplePay*)[super initWithWebView:(UIWebView*)theWebView];
    
    return self;
}

- (void)dealloc
{
    
}

- (void)onReset
{
    
}

- (void)setMerchantId:(CDVInvokedUrlCommand*)command
{
    merchantId = [command.arguments objectAtIndex:0];
    NSLog(@"ApplePay set merchant id to %@", merchantId);
}

- (void)getAllowsApplePay:(CDVInvokedUrlCommand*)command
{
    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    PKPaymentRequest *request = [Stripe
                                 paymentRequestWithMerchantIdentifier:merchantId];
    
    // Configure a dummy request
    NSString *label = @"Premium Llama Food";
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    request.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:label
                                                                        amount:amount]
                                    ];
    
    if ([Stripe canSubmitPaymentRequest:request]) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"user has apple pay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"user does not have apple pay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)getStripeToken:(CDVInvokedUrlCommand*)command
{
    
    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
    PKPaymentRequest *request = [Stripe
                                 paymentRequestWithMerchantIdentifier:merchantId];
    
    // Configure your request here.
    NSString *label = [command.arguments objectAtIndex:1];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[command.arguments objectAtIndex:0]];
    request.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:label
                                                                        amount:amount]
                                    ];
    
    NSString *cur = [command.arguments objectAtIndex:2];
    request.currencyCode = cur;
    
    callbackId = command.callbackId;
    
    if ([Stripe canSubmitPaymentRequest:request]) {
        PKPaymentAuthorizationViewController *paymentController;
        paymentController = [[PKPaymentAuthorizationViewController alloc]
                             initWithPaymentRequest:request];
        paymentController.delegate = self;
        [self.viewController presentViewController:paymentController animated:YES completion:nil];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"You dont have access to ApplePay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"couldn't get a stripe token from STPAPIClient"];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
            return;
        } else {

            NSString* brand;
            
            switch (token.card.brand) {
                case STPCardBrandVisa:
                    brand = @"Visa";
                    break;
                case STPCardBrandAmex:
                    brand = @"American Express";
                    break;
                case STPCardBrandMasterCard:
                    brand = @"MasterCard";
                    break;
                case STPCardBrandDiscover:
                    brand = @"Discover";
                    break;
                case STPCardBrandJCB:
                    brand = @"JCB";
                    break;
                case STPCardBrandDinersClub:
                    brand = @"Diners Club";
                    break;
                case STPCardBrandUnknown:
                    brand = @"Unknown";
                    break;
            }
            
            NSDictionary* card = @{
               @"id": token.card.cardId,
               @"brand": brand,
               @"last4": [NSString stringWithFormat:@"%@", token.card.last4],
               @"exp_month": [NSString stringWithFormat:@"%lu", token.card.expMonth],
               @"exp_year": [NSString stringWithFormat:@"%lu", token.card.expYear]
           };
            
            NSDictionary* message = @{
               @"id": token.tokenId,
               @"card": card
            };
            
            completion(PKPaymentAuthorizationStatusSuccess);
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary: message];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
        
    }];
}
 
 
 - (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
     CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"user cancelled apple pay"];
     [self.commandDelegate sendPluginResult:result callbackId:callbackId];
     [self.viewController dismissViewControllerAnimated:YES completion:nil];
 }
 
@end