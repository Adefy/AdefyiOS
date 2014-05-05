#import "AdefyDownloader.h"
#import <AdSupport/ASIdentifierManager.h>

NSString *DEFAULT_ADEFY_SERVER = @"https://app.adefy.com/api/v1/serve";
NSString *DEFAULT_AD_TYPE = nil;

NSFileManager *FILE_MANAGER;
NSMutableString *CACHE_DIR;

@implementation AdefyDownloader {

@protected
  NSString *apiKey;
  NSString *adType;
  NSString *serverURL;
}

+ (void)initialize {

  FILE_MANAGER = [[NSFileManager alloc] init];
  CACHE_DIR = [AdefyDownloader getCacheDir];

  if(![AdefyDownloader cacheDirectoryExists]) {
    NSLog(@"Cache directory doesn't exist, creating (%@)...", CACHE_DIR);

    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:CACHE_DIR
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:&error];

    if(!success) {
      NSLog(@"Error creating cache dir: %@ %@", error, [error userInfo]);
    } else {
      NSLog(@"...done");
    }
  }
}

+ (NSMutableString *)getCacheDir {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;

  return [NSMutableString stringWithFormat:@"%@/adefy/ads/", documentsPath];
}

+ (BOOL)cacheDirectoryExists {

  BOOL isDir;
  BOOL exists = [FILE_MANAGER fileExistsAtPath:CACHE_DIR
                                   isDirectory:&isDir];

  return isDir && exists;
}

- (AdefyDownloader *)init:(NSString *)_apiKey
             withAdServer:(NSString *)_url
                   ofType:(NSString *)_adType {

  self = [super init];

  apiKey = _apiKey;
  serverURL = _url;
  adType = _adType;

  return self;
}

- (AdefyDownloader *)init:(NSString *)_apiKey
                   ofType:(NSString *)_adType {
  return [self init:_apiKey
       withAdServer:DEFAULT_ADEFY_SERVER
             ofType:_adType];
}

- (AdefyDownloader *)init:(NSString *)_apiKey {
  return [self init:_apiKey
       withAdServer:DEFAULT_ADEFY_SERVER
             ofType:DEFAULT_AD_TYPE];
}

// Returns UUID, Width, and Height in a dictionary
- (NSMutableDictionary *)getUserInformation {
  NSMutableDictionary *uInfo = [[NSMutableDictionary alloc] init];

  ASIdentifierManager* advertisingIdentManager = [ASIdentifierManager sharedManager];
  CGRect screenRect = [[UIScreen mainScreen] bounds];

  NSNumber *screenWidth = [NSNumber numberWithInt:(int)screenRect.size.width];
  NSNumber *screenHeight = [NSNumber numberWithInt:(int) screenRect.size.height];
  NSString *uuid = [advertisingIdentManager.advertisingIdentifier UUIDString];

  [uInfo setObject:uuid forKey:@"UUID"];
  [uInfo setObject:screenWidth forKey:@"Width"];
  [uInfo setObject:screenHeight forKey:@"Height"];
  // Note that we don't pass the username, as Apple doesn't like that

  return uInfo;
}

- (NSString *)buildQueryString {
  NSMutableString *query = [NSMutableString stringWithString:serverURL];
  NSMutableDictionary *userInformation = [self getUserInformation];

  NSNumber * width = [userInformation objectForKey:@"Width"];
  NSNumber * height = [userInformation objectForKey:@"Height"];
  NSString *uuid = [userInformation objectForKey:@"UUID"];

  [query appendFormat:@"?width=%i&height=%i&uuid=%@", [width intValue], [height intValue], uuid];

  return query;
}

- (void)fetchAd:(NSString *)name withDurationMS:(int)duration {

  // Get queue handles
  dispatch_queue_t backgroundQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_queue_t mainQ = dispatch_get_main_queue();

  // Start primary download
  dispatch_async(backgroundQ, ^{

    //
    // TODO: Use a different download mechanism
    //
    NSURL *url = [NSURL URLWithString:[self buildQueryString]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *downloadPath = [CACHE_DIR stringByAppendingPathComponent:name];
    NSMutableString *finalFilename = [NSMutableString stringWithFormat:@"%@.ttx", downloadPath];

    // Perform download (blocks!)
    [data writeToFile:finalFilename atomically:YES];

    // Notify main thread
    dispatch_async(mainQ, ^{
      NSLog(@"Downloaded! %@", name);
    });
  });
}

@end