//
//  TXMainThreadMOC.h
//
//  Created by Tonny on 11/06/27.
//  Copyright 2013 Tonny Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define MainThreadMOC [TXMainThreadMOC sharedInstance]

@interface TXMainThreadMOC : NSObject 

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (TXMainThreadMOC *)sharedInstance;

- (void)mergeChanges:(NSNotification *)notification;
- (void)saveContext;

// for test only. In release build, it will be turned into an empty function
- (void)deleteStoreFileAndRecreateStore;
@end
