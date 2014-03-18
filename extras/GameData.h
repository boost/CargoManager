//
//  GameData.h
//

#import <Foundation/Foundation.h>

#import "CargoManager.h"

@class SKProduct;

@protocol GameDataDelegate;
@protocol RMStoreTransactionPersistor;

@interface StoreKitElement : NSObject

@property (nonatomic, readonly) NSString *productIdentifier;

// This proerty gets the cached SKProduct from the CargoManager
@property (nonatomic, readonly) SKProduct *product;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (id)initWithProductIdentifier:(NSString *)productIdentifier;

@end

@protocol GameDataDelegate <NSObject>

-(void) startProgressView;

-(void) updateProgress:(CGFloat) progress;

-(void) endProgressView;

@end


@protocol RMStoreTransactionPersistor<NSObject>

- (void)persistTransaction:(SKPaymentTransaction*)transaction;

@end

@interface GameData : NSObject <CargoManagerContentDelegate>

@property (nonatomic, readonly) NSArray *storeKitElements;

+ (GameData *)sharedData;
@property (nonatomic, weak) id <GameDataDelegate>  gameDelegate;
@property (nonatomic, weak) id<RMStoreTransactionPersistor> transactionPersistor;
- (void)loadStoreKitElementsFromFile;

@end



