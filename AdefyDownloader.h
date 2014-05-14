#import <Foundation/Foundation.h>

@interface AdefyDownloader : NSObject

- (AdefyDownloader *)init:(NSString *)_apiKey
             withAdServer:(NSString *)_url
                   ofType:(NSString *)_adType;
- (AdefyDownloader *)init:(NSString *)_apiKey
                   ofType:(NSString *)_adType;
- (AdefyDownloader *)init:(NSString *)_apiKey;

- (void)fetchAd:(NSString *)name
 withDurationMS:(int)duration
   withTemplate:(NSString *)template;
- (NSString *)getPathForGLAd:(NSString *)name;

@end