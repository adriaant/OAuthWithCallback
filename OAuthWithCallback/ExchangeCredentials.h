//  Created by Adriaan Tijsseling on 11/07/23.

#import "ExchangeCredentials.h"

@protocol ExchangeCredentialsDelegate;

@class OAToken, OAConsumer;

@interface ExchangeCredentials : NSObject {
	NSError		*error;	
	id<ExchangeCredentialsDelegate>	delegate;

@private
	OAToken		*_requestToken;
}

@property(nonatomic,retain) NSError *error;
@property(nonatomic,assign) id delegate;

- (id)initWithDelegate:(id<ExchangeCredentialsDelegate>)del;
- (void)requestRequestToken;
- (void)requestAccessToken:(NSString*)callback;
- (NSURLRequest*)authorizeURLRequest;

@end

@protocol ExchangeCredentialsDelegate 

@required
- (void)credentialFailed:(ExchangeCredentials*)credential;
- (void)credentialSucceeded:(NSString*)username;
- (OAConsumer*)consumer;
- (void)startAuthorization:(NSURLRequest*)request;
@end
