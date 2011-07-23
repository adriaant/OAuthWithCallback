//  Created by Adriaan Tijsseling on 11/07/23.

@protocol TwitterRequestDelegate;

@class OAConsumer;

@interface TwitterRequest : NSObject {
	NSString	*screenName;
@private
    NSURLConnection	*connection;
	NSMutableData	*data;
	id<TwitterRequestDelegate> delegate;
}

@property(nonatomic,assign) id delegate;
@property(nonatomic,retain) NSString *screenName;

/**
 * Initialize a request.
 *
 * \param  del  the delegate that made the request. Usually a \c BasicJob instance.
 */
- (id)initWithDelegate:(id)del screenname:(NSString*)name;

/**
 * Make the request.
 */
- (void)makeRequest;

/**
 * The url to submit the request to.
 */
- (NSURL*)url;

/**
 * Contents of POST or PUT request.
 */
- (NSData*)body;

/**
 * Specifies which REST method to use (GET, POST, PUT, DELETE).
 */
- (NSString*)httpMethod;

/**
 * Cancels the current request.
 */
- (void)cancel;

/**
 * Terminates the request. Invoked when response is not 200.
 */
- (void)stopReceiveWithStatus:(NSString*)statusString code:(NSInteger)code;

/**
 * Headers for authentication.
 */
- (NSString*)authorizationString;

@end

/**
 * Delegates must implement the routines below to handle success or failure.
 */
@protocol TwitterRequestDelegate 

@required
- (void)twitterRequest:(TwitterRequest*)request finishedLoadingData:(NSData*)data;
- (void)twitterRequest:(TwitterRequest*)request failedWithError:(NSError*)error;
- (OAConsumer*)consumer;
@end
