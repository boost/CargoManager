//
//  GameData.m
//

#import "GameData.h"

#import <StoreKit/StoreKit.h>

#import "CargoManager.h"
#import "RMStoreKeychainPersistence.h"

@interface StoreKitElement ()

@property (nonatomic) NSString *productIdentifier;
@property (nonatomic) NSString *imageName;

@end

@implementation StoreKitElement

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithProductIdentifier:dictionary[@"productIdentifier"]];
}

- (id)initWithProductIdentifier:(NSString *)productIdentifier
{
    if ( !(self = [super init]) )
    {
        return nil;
    }
    
    self.productIdentifier = productIdentifier;
    
    return self;
}

- (SKProduct *)product
{
    return [[CargoManager sharedManager] productForIdentifier:self.productIdentifier];
}

@end


@interface GameData ()

@property (nonatomic) NSArray *storeKitElements;

@end

@implementation GameData

static GameData *_gameData = nil;

+ (GameData *)sharedData
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
                  ^{
                      _gameData = [[GameData alloc] init];
                  });
    return _gameData;
}

- (id)init
{
    if ( _gameData )
    {
        return _gameData;
    }

    if ( !(self = [super init]) )
    {
        return nil;
    }

    self.storeKitElements = nil;
    
    [self loadGameData];
    
    return self;
}

- (void)loadGameData
{
    [self loadStoreKitElementsFromFile];
}

- (void)loadStoreKitElementsFromFile
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"storeKitElements" ofType:@"plist"];
    NSArray *plistArray = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];

    NSAssert(plistArray != nil, @"ERROR: Failed to load storeKitElements.plist.");

    if ( plistArray )
    {
        NSMutableArray *storeKitElements = [[NSMutableArray alloc] initWithCapacity:[plistArray count]];

        for ( NSDictionary* dictionary in plistArray )
        {
            StoreKitElement* storeKitProduct = [[StoreKitElement alloc] initWithDictionary:dictionary];
            [storeKitElements addObject:storeKitProduct];
        }

        // Storey inmutable copy
        self.storeKitElements = [storeKitElements copy];
    }
}

- (StoreKitElement *)storeKitElementForProductIdentifier:(NSString *)productIdentifier
{
    for (StoreKitElement *element in self.storeKitElements)
    {
        if ( [element.productIdentifier isEqualToString:productIdentifier] )
        {
            return element;
        }
    }
    return nil;
}

- (int)countOfStoreKitElements
{
    return [self.storeKitElements count];
}

#pragma mark - CargoManager StoreKitContentProviderDelegate

- (NSArray *)productIdentifiers
{
    NSMutableArray *productIdentifiers = [[NSMutableArray alloc] init];

    for (StoreKitElement *element in self.storeKitElements)
    {
        [productIdentifiers addObject:element.productIdentifier];
    }

    // Return a non-mutable copy
    return [NSArray arrayWithArray:productIdentifiers];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    // Implement here the result of a successful IAP
    // on the corresponding productIdentifier
//    StoreKitElement *storeKitElement = [self storeKitElementForProductIdentifier:productIdentifier];
//    [storeKitElement.product downloadContentLengths];
    
    
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction
{
    [_transactionPersistor persistTransaction:transaction];

}



-(void)downloadUpdated:(SKDownload *)download
{
    NSArray * directories;
    
    if(download.downloadState == SKDownloadStateActive) {
        
        #ifdef DEBUG
        NSLog(@"downloadStateActive");
                NSLog(@"%f", download.progress);
                NSLog(@"%f remaining", download.timeRemaining);
        #endif
        
        if (download.progress == 0.0)
        {
            
        }
        #define WAIT_TOO_LONG_SECONDS 60
        #define TOO_LARGE_DOWNLOAD_BYTES 4194304
            
//            const BOOL instantDownload = (download.timeRemaining != SKDownloadTimeRemainingUnknown && download.timeRemaining < WAIT_TOO_LONG_SECONDS) ||
//            (download.contentLength < TOO_LARGE_DOWNLOAD_BYTES);
        
        [_gameDelegate updateProgress:download.progress];
        //display downloading sign
    }
    
    if(download.downloadState == SKDownloadStateFailed) {
        #ifdef DEBUG
        NSLog(@"downloadStateFailed");
        #endif
        [_gameDelegate endProgressView];
    }
    
    if(download.downloadState == SKDownloadStateFinished) {
        #ifdef DEBUG
        NSLog(@"downloadStateFinished");
        #endif
    }
    
    if(download.downloadState == SKDownloadStatePaused) {
        #ifdef DEBUG
        NSLog(@"downloadStatePaused");
        #endif
    }
    
    if(download.downloadState == SKDownloadStateWaiting) {
        #ifdef DEBUG
        NSLog(@"downloadStateWaiting");
        #endif
    }
    
    if(download.downloadState == SKDownloadStateFinished) {
        
        

        directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = [directories lastObject];
        
        NSError * error;
        #ifdef DEBUG
        NSLog(@"download url %@", download.contentURL.path);
        #endif
        
        NSString *source = [download.contentURL relativePath];
        NSDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:[source stringByAppendingPathComponent:@"ContentInfo.plist"]];
        
        if (![dict objectForKey:@"IAPProductIdentifier"])
        {
            [[SKPaymentQueue defaultQueue] finishTransaction:download.transaction];
            
            return;
        }
        
        NSString * productIdentifier = [dict objectForKey:@"IAPProductIdentifier"];
        NSString * contentDirectory = [source stringByAppendingPathComponent:@"Contents"];
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:contentDirectory error:&error];
        for (NSString *file in directoryContent)
        {
//            NSString *content = [[source stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:file];
            [self createDirectory:productIdentifier atFilePath:documents];
            
            NSString * newDirectory = [documents stringByAppendingPathComponent:productIdentifier];
            
            NSString * newLocation = [newDirectory stringByAppendingPathComponent:file];
            
            NSString * filePath = [contentDirectory stringByAppendingPathComponent:file];
            
            [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newLocation  error:&error];

            NSLog(@"error %@", [error localizedDescription]);
        }
        
    }
    
}

-(void)createDirectory:(NSString *)directoryName atFilePath:(NSString *)filePath
{
    NSString *filePathAndDirectory = [filePath stringByAppendingPathComponent:directoryName];
    NSError *error;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathAndDirectory isDirectory:nil]){
        return;
    }
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:filePathAndDirectory
                                   withIntermediateDirectories:NO
                                                    attributes:nil
                                                         error:&error])
    {
        NSLog(@"Create directory error: %@", error);
    }
}


@end
