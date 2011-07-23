//  Created by Adriaan Tijsseling on 11/07/23.

#import "TwitterRequest.h"
#import "SFHFKeychainUtils.h"
#import "OAMutableURLRequest.h"
#import "OAToken.h"

@implementation TwitterRequest

@synthesize delegate, screenName;

#pragma mark -
#pragma mark Init/Dealloc

- (id)initWithDelegate:(id)del screenname:(NSString*)name {
	self = [super init];
	if (self != nil) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		self.delegate = del;
		self.screenName = name;
	}
	return self;
}

- (void)dealloc {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if (connection) {
		[connection release];
	}
	if (data) {
		[data release];
	}
	[screenName release];
	[super dealloc];
}

#pragma mark -
#pragma mark Request Construction

/**
 * The Twitter API url for making user info request.
 */
- (NSURL*)url {
	NSString *urlStr = [NSString stringWithFormat:@"https://api.twitter.com/1/users/show.xml?screen_name=%@", self.screenName];
	return [NSURL URLWithString:urlStr];
}	

/**
 * The OAuth signature for the request.
 */
- (NSString*)authorizationString {
	
	NSError	 *error;
	NSString *loginString = self.screenName;
	NSString *passwordString = [SFHFKeychainUtils getPasswordForUsername:[loginString lowercaseString] andServiceName:@"Callback_OAuth" error:&error];
	
	if (passwordString == nil) {
		[self stopReceiveWithStatus:NSLocalizedString(@"This app has not been allowed access to Twitter yet.", @"Missing credentials alert message") code:401];
		return nil;
	}
	
	return passwordString;
}

/**
 * Create a signed Twitter API request. 
 */
- (void)makeRequest {
	NSString *authorizationStr = [self authorizationString];
	if (authorizationStr == nil) {
		return;
	}
	OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:authorizationStr];
	OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[self url]
																   consumer:delegate.consumer 
																	  token:token
																	  realm:@"http://api.twitter.com/"
														  signatureProvider:nil];
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setTimeoutInterval:20.0];
	
	// Here I assume that I'm of sane mind and won't be setting a body AND using a GET request
	// Surely that would be daft.
	NSData *body = [self body];
	if (body) {
		[request setHTTPBody:body];
	}
	[request setHTTPMethod:[self httpMethod]];
	[request prepare];
	
	data = [[NSMutableData alloc] initWithCapacity:1024];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[token release];
	[request release];
}

- (NSData*)body { // override if you need to use post
	return nil;
}

- (NSString*)httpMethod {
	return @"GET";
}

#pragma mark -
#pragma mark HTTP

/** Shuts down the connection and displays the result (statusString == nil) 
 * or the error status (otherwise).
 */
- (void)stopReceiveWithStatus:(NSString*)statusString code:(NSInteger)code
{
	if (connection) {
		[connection cancel];
	}
	if (self.delegate && [self.delegate respondsToSelector:@selector(twitterRequest:failedWithError:)]) {
		[self.delegate performSelector:@selector(twitterRequest:failedWithError:) withObject:self withObject:[NSError errorWithDomain:statusString code:code userInfo:nil]];
	}
}

- (void)cancel {
	self.delegate = nil;
	if (connection) {
		[connection cancel];
	}
}

#pragma mark -
#pragma mark NSURLConnection delegate methods

/**
 * check that the HTTP status code is 2xx and that the Content-Type is acceptable.
 */
- (void)connection:(NSURLConnection*)theConnection didReceiveResponse:(NSURLResponse*)response {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if ((httpResponse.statusCode / 100) != 2) {
        [self stopReceiveWithStatus:[NSString stringWithFormat:@"HTTP error %zd", (ssize_t) httpResponse.statusCode] code:httpResponse.statusCode];
    }
}

- (void)connection:(NSURLConnection*)theConnection didReceiveData:(NSData*)newData {
	[data appendData:newData];
}

- (void)connection:(NSURLConnection*)theConnection didFailWithError:(NSError*)error {
    NSLog(@"%@", [error localizedDescription]);
	[connection release]; connection = nil;
	[data release]; data = nil;
	if (self.delegate && [self.delegate respondsToSelector:@selector(twitterRequest:failedWithError:)]) {
		[self.delegate performSelector:@selector(twitterRequest:failedWithError:) withObject:self withObject:error];
		return;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection*)theConnection {
	if (self.delegate && [self.delegate respondsToSelector:@selector(twitterRequest:finishedLoadingData:)]) {
		NSData *copiedData = [[NSData alloc] initWithData:data];
		[self.delegate performSelector:@selector(twitterRequest:finishedLoadingData:) withObject:self withObject:copiedData];
	}
	[connection release]; connection = nil;
	[data release]; data = nil;
}

@end
