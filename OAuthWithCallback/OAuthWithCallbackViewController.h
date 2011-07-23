//  Created by Adriaan Tijsseling on 11/07/23.

#import <UIKit/UIKit.h>
#import "ExchangeCredentials.h"
#import "TwitterRequest.h"

@class OAConsumer, TwitterUser;

@interface OAuthWithCallbackViewController : UIViewController <UIWebViewDelegate, ExchangeCredentialsDelegate, UIAlertViewDelegate, TwitterRequestDelegate> {
	OAConsumer				*consumer;
@private
	UIWebView				*webView;
	
	ExchangeCredentials		*_credential;
	TwitterRequest			*userRequest;
}

@property(nonatomic,retain) IBOutlet UIWebView *webView;
@property(nonatomic,retain) OAConsumer *consumer;
@property(nonatomic,retain) TwitterRequest *userRequest;

@end
