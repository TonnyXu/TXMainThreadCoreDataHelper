/*
 Copyright 2013 Tonny Xu
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TXMainThreadMOC.h"
#import "TXMainThreadMOC_Definition.h"

@interface TXMainThreadMOC()

@property (nonatomic, retain, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;
- (void)prepopulateData;

@end

@implementation TXMainThreadMOC

+ (TXMainThreadMOC *)sharedInstance{
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);
  
  static TXMainThreadMOC *MOCInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    MOCInstance = [[TXMainThreadMOC alloc] init];
  });
  
  return MOCInstance;
}

- (id)init{
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);
  
  self = [super init];
  if (self) {
    [[NSNotificationCenter defaultCenter] 
     addObserver:self 
     selector:@selector(mergeChanges:) 
     name:NSManagedObjectContextDidSaveNotification 
     object:nil]; // it's very important to set sender object to nil to accept notification from any MOC object
  }
  
  return self;
}

- (void)dealloc{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//////////////////////////////////////////////////////////////////////////////
// CoreData properties.
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);
  
  if (_managedObjectContext != nil) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {

    /* NOTE By Tonny
     * -------------
     * Aug 9, 2012
     *
     * iOS 5 added new concurrency support for Core Data, instead of using 
     * [NSManageObjectContext new], use the -initWithConcurrencyType: method will
     * make it more easy to understand.
     * 
     */
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    _managedObjectContext.undoManager = nil;
    _managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    
    [self prepopulateData];
  }
  return _managedObjectContext;
}

//////////////////////////////////////////////////////////////////////////////
// Returns the managed object model for the application.
// If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
- (NSManagedObjectModel *)managedObjectModel {
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);
  
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }

  self.managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
  
  return _managedObjectModel;
}

//////////////////////////////////////////////////////////////////////////////
// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);
  
  if (_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
	NSString *storePath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:DBFileName];
  
	NSFileManager *fileManager = [NSFileManager defaultManager];
	// If the expected store doesn't exist, copy the default store.
	if (![fileManager fileExistsAtPath:storePath]) {
		NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:DBFileName ofType:nil];
		if (defaultStorePath) {
			[fileManager copyItemAtPath:defaultStorePath toPath:storePath error:NULL];
		}
	}
  
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
  
	NSError *error;
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
  
  NSDictionary *migarationOptions = @{NSMigratePersistentStoresAutomaticallyOption:@(YES), NSInferMappingModelAutomaticallyOption:@(YES)};
  
  // This method will create the DB if it is not existed.
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:migarationOptions error:&error]) {
    
    // Typical reasons for an error here include:
    // The persistent store is not accessible
    // The schema for the persistent store is incompatible with current managed object model
    // Check the error message to determine what the actual problem was.
    //
		abort();
  }
  return _persistentStoreCoordinator;
}

//////////////////////////////////////////////////////////////////////////////
// this is called via observing "NSManagedObjectContextDidSaveNotification" from SubThreadMOC
- (void)mergeChanges:(NSNotification *)notification {

  dispatch_async(dispatch_get_main_queue(), ^{
    NSManagedObjectContext *mainContext = [self managedObjectContext];
    if ([notification object] == mainContext) {
      // main context save, no need to perform the merge
      return;
    }
    
    [mainContext mergeChangesFromContextDidSaveNotification:notification];
  });
}

- (void)saveContext
{
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);

  NSError *error = nil;
  NSManagedObjectContext *mainMoc = self.managedObjectContext;
  if (mainMoc != nil)
  {
    if ([mainMoc hasChanges] && ![mainMoc save:&error])
    {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
       */
      abort();
    }
  }
}

- (void)prepopulateData{
  // Add your code here to prepopulate data.

}


#ifdef DEBUG
- (void)deleteStoreFileAndRecreateStore{
  NSAssert([NSThread isMainThread], @"%s should be run on the main thread", __FUNCTION__);

  NSPersistentStore *store = [[self.persistentStoreCoordinator persistentStores] lastObject];
  NSError *error;
  NSURL *storeURL = store.URL;
  NSPersistentStoreCoordinator *storeCoordinator = self.persistentStoreCoordinator;
  [storeCoordinator removePersistentStore:store error:&error];
  [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
#if !__has_feature(objc_arc)
  [persistentStoreCoordinator release];
#endif
  _persistentStoreCoordinator = nil;
  _managedObjectContext = nil;
}
#else
- (void)deleteStoreFileAndRecreateStore{}
#endif

#pragma mark - Application's Documents directory
/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
