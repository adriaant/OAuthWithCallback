//  Created by Adriaan Tijsseling on 11/07/23.

#import "ExchangeCredentials.h"
#import "OAMutableURLRequest.h"
#import "OARequestParameter.h"
#import "OADataFetcher.h"
#import "SFHFKeychainUtils.h"

@interface ExchangeCredentials (Private)
- (void)requestTokenThread:(id)obj;
- (void)serviceTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)error;
- (void)serviceTicket:(OAServiceTicket*)ticket finishedWithData:(NSData*)data;
- (void)setRequestToken:(OAServiceTicket *)ticket withData:(NSData *)data;
- (NSString*)extractUsernameFromHTTPBody:(NSString*)body;
@end

@implementation ExchangeCredentials

@synthesize delegate, error;

- (id)initWithDelegate:(id<ExchangeCredentialsDelegate>)del {
	self = [super init];
	if (self) {
		self.delegate = del;
	}
	return self;
}

/**
 * Step 1: Reuqest a request token. 
 */
- (void)requestRequestToken {
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:
			[NSURL URLWithString:@"https://twitter.com/oauth/request_token"] 
			consumer:delegate.consumer
			token:nil					// we don't have a token yet
			realm:nil					// our service provider doesn't specify a realm
		    signatureProvider:nil]; 	// use the default method, HMAC-SHA1
    [request setHTTPMethod: @"POST"];
	OADataFetcher *dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(setRequestToken:withData:) didFailSelector:@selector(serviceTicket:didFailWithError:)];
	[dataFetcher release];
	[request release];
}

/**
 * Once a request token has been obtained, store it and 
 * tell the delegate it can load the authorization webpage. 
 */
- (void)setRequestToken:(OAServiceTicket *)ticket withData:(NSData *)data {
	if (!ticket.didSucceed || !data) {
		[self serviceTicket:nil didFailWithError:[NSError errorWithDomain:
			NSLocalizedString(@"Twitter rejected the authentication.", @"Failed to start authentication")
			code:0 userInfo:nil]];
		return;
	}
	
	NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (!dataString) {
		[self serviceTicket:nil didFailWithError:[NSError errorWithDomain:
			NSLocalizedString(@"Twitter rejected the authentication.", @"Failed to start authentication")
			code:0 userInfo:nil]];
		return;
	}
	
	[_requestToken release];
	_requestToken = [[OAToken alloc] initWithHTTPResponseBody:dataString];
	[dataString release];
	
	if (self.delegate) {
		[delegate startAuthorization:[self authorizeURLRequest]];
	}
}

/**
 * This generates a URL request that can be passed to a UIWebView. 
 * It will open a page in which the user must enter their Twitter credentials
 */
- (NSURLRequest*)authorizeURLRequest {
	OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:
		[NSURL URLWithString: @"https://twitter.com/oauth/authorize"] 
		consumer:nil
		token:_requestToken
		realm:nil 
		signatureProvider:nil] autorelease];
	NSMutableArray *requestParameters = [NSMutableArray arrayWithCapacity:3];
	[requestParameters addObject:[[[OARequestParameter alloc] initWithName:@"oauth_token" value:_requestToken.key] autorelease]];
	[requestParameters addObject:[[[OARequestParameter alloc] initWithName:@"force_login" value:@"true"] autorelease]];
	[request setParameters:requestParameters];
	return request;
}

/**
 * The user has entered his/her credentials and we got the callback request.
 * Go ahead and get the access token now. 
 */
- (void)requestAccessToken:(NSString*)callback {


    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:
									[NSURL URLWithString:@"https://twitter.com/oauth/access_token"] 
																   consumer:delegate.consumer
																	  token:_requestToken
																	  realm:nil		// our service provider doesn't specify a realm
														  signatureProvider:nil]; 	// use the default method, HMAC-SHA1
    [request setHTTPMethod: @"POST"];

	NSArray *parts = [callback componentsSeparatedByString:@"?"];
	NSArray *pairs = [[parts objectAtIndex:1] componentsSeparatedByString:@"&"];
	for (NSString *pair in pairs) {
		NSArray *elements = [pair componentsSeparatedByString:@"="];
		[request setOAuthParameterName:[elements objectAtIndex:0] withValue:[elements objectAtIndex:1]];
	}
	
	OADataFetcher *dataFetcher = [[OADataFetcher alloc] init];
	[dataFetcher fetchDataWithRequest:request delegate:self didFinishSelector:@selector(setAccessToken:withData:) didFailSelector:@selector(serviceTicket:didFailWithError:)];
	[dataFetcher release];
	[request release];
}

/**
 * The access token has been obtained. Store it and use it for making Twitter API calls. 
 */
- (void)setAccessToken:(OAServiceTicket*)ticket withData:(NSData*)data {
	if (ticket.didSucceed && data != nil) {
		NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if (dataString) {
			NSString *username = [self extractUsernameFromHTTPBody:dataString];
			if (username != nil) {

				NSString *accessToken = [NSString stringWithString:dataString];
				
				[SFHFKeychainUtils storeUsername:username andPassword:accessToken forServiceName:@"Callback_OAuth" updateExisting:YES error:&error];
				if (error) {
					@throw [NSException exceptionWithName:@"Exception" reason:@"The keychain, it hates us." userInfo:nil];
				}

				[self.delegate performSelectorOnMainThread:@selector(credentialSucceeded:) withObject:username waitUntilDone:NO];
				return;
			}
		}
	}
		
	[self serviceTicket:nil didFailWithError:[NSError errorWithDomain:
			NSLocalizedString(@"Twitter rejected the authentication.", @"Failed to start authentication")
			code:0 userInfo:nil]];
}

/**
 * Utility function to grab screen name out of authorization response.
 */
- (NSString*)extractUsernameFromHTTPBody:(NSString*)body {
	if (body != nil && [body length] > 0) {
		NSArray *tuples = [body componentsSeparatedByString:@"&"];
		if (tuples.count > 0) {
			for (NSString *tuple in tuples) {
				NSArray *keyValueArray = [tuple componentsSeparatedByString:@"="];
				if (keyValueArray.count == 2 && [[keyValueArray objectAtIndex:0] isEqualToString:@"screen_name"]) 
					return [keyValueArray objectAtIndex:1];
			}
		}
	}
	return nil;
}

/**
 * Meh. 
 */
- (void)serviceTicket:(OAServiceTicket*)ticket didFailWithError:(NSError*)err {
	self.error = err;
	if (self.delegate) {
		[self.delegate performSelectorOnMainThread:@selector(credentialFailed:) withObject:self waitUntilDone:NO];
	}
}

- (void)dealloc {
	[_requestToken release];
	[error release];
	[super dealloc];
}

@end
