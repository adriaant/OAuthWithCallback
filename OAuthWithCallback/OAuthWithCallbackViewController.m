//  Created by Adriaan Tijsseling on 11/07/23.

#import "OAuthWithCallbackViewController.h"
#import "OAConsumer.h"

@interface OAuthWithCallbackViewController ()
- (void)setupConsumer;
- (void)prepareAuthorization;
@end

@implementation OAuthWithCallbackViewController

@synthesize webView, consumer, userRequest;

/**
 * Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad {
    [super viewDidLoad];
	self.webView.delegate = self;
	[self setupConsumer];
	[self prepareAuthorization];
}

/**
 * No comment. 
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
#pragma mark OAuth Interface

/**
 * Set up our OAuth handler.
 */
- (void)setupConsumer {
	consumer = [[OAConsumer alloc] initWithKey:@"SET_YOUR_API_KEY_HERE" secret:@"YOUR_SECRET_IS_NOT_SAFE"];
}

/**
 * Start the process with requesting a request token. 
 */
- (void)prepareAuthorization {
	if (_credential != nil) {
		_credential.delegate = nil;
		[_credential release];
	}
	_credential = [[ExchangeCredentials alloc] initWithDelegate:self];
	[_credential requestRequestToken];
}

/**
 * Request token is in. Let user enter credentials in webpage. 
 */
- (void)startAuthorization:(NSURLRequest*)request {
	[webView loadRequest:request];
}

/**
 * The force was not with us. 
 */
- (void)credentialFailed:(ExchangeCredentials*)credential {
	NSInteger code = 0;	
	NSString  *h = NSLocalizedString(@"Failure", @"Failure alert header"), *msg = nil;
	
	if (credential != nil) {
		code = [credential.error code];
	}
	
	if (code == NSURLErrorNetworkConnectionLost || code == NSURLErrorNotConnectedToInternet) {
		msg = NSLocalizedString(@"No network connection.", @"Network down.");
	} else if (code == NSURLErrorTimedOut) {
		msg = NSLocalizedString(@"Connection timed out, try again in a minute.", @"Connection fail");
	} else if (code >= 500) {
		msg = NSLocalizedString(@"Twitter is overloaded, try again in a minute.", @"API fail");
	} else {
		msg = NSLocalizedString(@"Twitter rejected the authentication. Please check your username and password.", @"Failed to authenticate user");
		h = NSLocalizedString(@"Access Denied", @"Credentials failed alert header");
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:h message:msg delegate:self
										  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button") otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self prepareAuthorization];
}

/**
 * Twitter has found us worthy. 
 */
- (void)credentialSucceeded:(NSString*)newUsername {
	NSLog(@"Authorized as %@", [newUsername description]);
	userRequest = [[TwitterRequest alloc] initWithDelegate:self screenname:newUsername];
	[userRequest makeRequest];
}

#pragma mark -
#pragma mark Delegate Calls

/**
 * Webview delegate call will tell us when we've gotten the callback url redirect request.
 * That's our clue that the user has authorized us. In a real app, you'd use this to hide
 * the webview and do something really useful.   
 */
- (BOOL)webView:(UIWebView*)wv shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	
	BOOL    response = YES;
	NSURL 	*requestURL = [request URL];
	
	NSDictionary *dictionary = [request allHTTPHeaderFields];
	for (id key in dictionary) {
		NSLog(@"HTTPHeaderFields - key: %@, value: %@", [key description], [[dictionary objectForKey:key] description]);
	}
	
	NSLog(@"%@", [requestURL description]);
	if ([[requestURL host] isEqualToString:@"USE_WHATEVER_HOST_YOUR_CALLBACK_URL_IS"]) {
		[_credential performSelector:@selector(requestAccessToken:) withObject:[requestURL absoluteString] afterDelay:0.1];
		return NO;
	}	
	
	switch (navigationType) {
		case UIWebViewNavigationTypeLinkClicked:
			[[UIApplication sharedApplication] openURL:[request URL]];
			response = NO;
			break;
		case UIWebViewNavigationTypeFormSubmitted:
			NSLog(@"Authenticating...");
			break;
		case UIWebViewNavigationTypeBackForward:
			response = NO;
			break;
		case UIWebViewNavigationTypeReload:
			break;
		case UIWebViewNavigationTypeFormResubmitted:
			break;
		case UIWebViewNavigationTypeOther:
			break;
		default:
			break;
	}
	return response;
}

- (void)webView:(UIWebView*)wv didFailLoadWithError:(NSError*)error {
	NSLog(@"%@", [error localizedDescription]);
}

#pragma mark -
#pragma mark TwitterRequest Delegate Calls

/**
 * Success callback from making a Twitter API call. 
 */
- (void)twitterRequest:(TwitterRequest*)request finishedLoadingData:(NSData*)data {
	if (request == self.userRequest) {
		if (data != nil) {
			NSString* encstring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			NSLog(@"%@", encstring);
			[encstring release];
		}
		self.userRequest = nil;
	}
	[data release];
}

/**
 * An it is not our day callback. 
 */
- (void)twitterRequest:(TwitterRequest*)request failedWithError:(NSError*)error {
	NSLog(@"%@", [error localizedDescription]);
	self.userRequest = nil;
}

#pragma mark -
#pragma mark Cleanup

/**
 * It's dusty. 
 */
- (void)dealloc {
	if (_credential) {
		_credential.delegate = nil;
		[_credential release];
	}
	webView.delegate = nil;
    [webView release];
	[consumer release];
	[userRequest release];
    [super dealloc];
}

@end
