# TXCoreDataHelper

It's a simple tool to help you use CoreData in your multithreaded iOS app correctly.

## Usage

### 1. Add `TXMainThreadMOC.h` to `.pch` file

This will make sure you can use it anywhere around the app.

```c
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <UIKit/UIKit.h>
    #import <CoreData/CoreData.h>
    #import "TXMainThreadMOC.h"
#endif
```

### 2. It's a singleton object

No matter you like this design pattern or not, since `NSManagedObjectContext` sticks to the thread where you create it, and main thread will be running until user quit your app or your app is killed by system. So, using singlton pattern for **main thread MOC** is reasonable.

### 3. Update `TXMainThreadMOC_definition.h`

This header file is only used to define the DB file's name. In your project, you can simple turn the code from:

```objective-c
#if (1)
  #define DBFileName @"CoreDataBooks.CDBStore"
#else
  #define DBFileName @"<#Set your DB file's name here, like `myDB.sqlite`#>"
#endif
```
to 
```objective-c
  #define DBFileName @"CoreDataBooks.CDBStore"
```

### 4. Use it whenever you need it.

* Access the MOC: `MainThreadMOC.managedObjectContext`
* Access the managed object model: `MainThreadMOC.managedObjectModel`
* Create child MOC based on `MainThreadMOC`:     

```objective-c
NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
[addingContext setParentContext:[MainThreadMOC managedObjectContext]];
```
* Create a MOC in sub thread:

```objective-c
NSManagedObjectContext *subMoc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
subMoc.persistentStoreCoordinator = MainThreadMOC.persistentStoreCoordinator;
subMoc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
```

## Merit 

1. You don't have to pass your main thread context throughout different view controllers
2. The class's name will reminder you where to use it
3. Making child MOC or subthread MOC is much more easy


### You don't need to add `managedObjectContext` proper to every view controller

See the diffs below. It's a simple diff shows that you can save some of your time and make your code much more clear and easy to understand.

```diff
diff --git a/CoreDataBooks/Classes/CoreDataBooksAppDelegate.m b/CoreDataBooks/Classes/CoreDataBooksAppDelegate.m
index 2e13162..5d2bf10 100644
--- a/CoreDataBooks/Classes/CoreDataBooksAppDelegate.m
+++ b/CoreDataBooks/Classes/CoreDataBooksAppDelegate.m
@@ -1,8 +1,8 @@
 
 /*
-     File: CoreDataBooksAppDelegate.m
+ File: CoreDataBooksAppDelegate.m
  Abstract: Application delegate to set up the Core Data stack and configure the first view and navigation controllers.
-  Version: 2
+ Version: 2
  
  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
  Inc. ("Apple") in consideration of your agreement to the following
@@ -49,176 +49,35 @@
 #import "CoreDataBooksAppDelegate.h"
 #import "RootViewController.h"
 
-
-@interface CoreDataBooksAppDelegate ()
-
-@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
-@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
-@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
-
-- (NSURL *)applicationDocumentsDirectory;
-- (void)saveContext;
-
-@end
-
-
+#import "TXMainThreadMOC.h"
 
 @implementation CoreDataBooksAppDelegate
 
 @synthesize window=_window;
-@synthesize managedObjectModel=_managedObjectModel, managedObjectContext=_managedObjectContext, persistentStoreCoordinator=_persistentStoreCoordinator;
 
 
 #pragma mark -
 #pragma mark Application lifecycle
 
-- (void)applicationDidFinishLaunching:(UIApplication *)application
-{
-    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
-    RootViewController *rootViewController = (RootViewController *)[[navigationController viewControllers] objectAtIndex:0];
-    rootViewController.managedObjectContext = self.managedObjectContext;
+- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
+  return YES;
 }
 
-
 - (void)applicationWillTerminate:(UIApplication *)application
 {
-    [self saveContext];
+  [MainThreadMOC saveContext];
 }
 
 
 - (void)applicationWillResignActive:(UIApplication *)application
 {
-    [self saveContext];
+  [MainThreadMOC saveContext];
 }
 
 
 - (void)applicationDidEnterBackground:(UIApplication *)application
 {
-    [self saveContext];
-}
-
-
-- (void)saveContext
-{
-    NSError *error;
-    if (_managedObjectContext != nil) {
-        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
-            /*
-             Replace this implementation with code to handle the error appropriately.
-     
-             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
-             */
-            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
-            abort();
-        } 
-    }
-}
-
-
-#pragma mark -
-#pragma mark Core Data stack
-
-/*
- Returns the managed object context for the application.
- If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- */
-- (NSManagedObjectContext *) managedObjectContext
-{
-    if (_managedObjectContext != nil) {
-        return _managedObjectContext;
-    }
-
-    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
-    if (coordinator != nil) {
-        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
-        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
-    }
-    return _managedObjectContext;
-}
-
-
-// Returns the managed object model for the application.
-// If the model doesn't already exist, it is created from the application's model.
-- (NSManagedObjectModel *)managedObjectModel
-{
-    if (_managedObjectModel != nil) {
-        return _managedObjectModel;
-    }
-    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataBooks" withExtension:@"momd"];
-    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
-    return _managedObjectModel;
-}
-
-
-/*
- Returns the persistent store coordinator for the application.
- If the coordinator doesn't already exist, it is created and the application's store added to it.
- */
-- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
-{
-    if (_persistentStoreCoordinator != nil) {
-        return _persistentStoreCoordinator;
-    }
-
-    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataBooks.CDBStore"];
-
-    /*
-     Set up the store.
-     For the sake of illustration, provide a pre-populated default store.
-     */
-    NSFileManager *fileManager = [NSFileManager defaultManager];
-    // If the expected store doesn't exist, copy the default store.
-    if (![fileManager fileExistsAtPath:[storeURL path]]) {
-        NSURL *defaultStoreURL = [[NSBundle mainBundle] URLForResource:@"CoreDataBooks" withExtension:@"CDBStore"];
-        if (defaultStoreURL) {
-            [fileManager copyItemAtURL:defaultStoreURL toURL:storeURL error:NULL];
-        }
-    }
-
-    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
-    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
-
-    NSError *error;
-    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
-        /*
-         Replace this implementation with code to handle the error appropriately.
-         
-         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
-         
-         Typical reasons for an error here include:
-         * The persistent store is not accessible;
-         * The schema for the persistent store is incompatible with current managed object model.
-         Check the error message to determine what the actual problem was.
-         
-         
-         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
-         
-         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
-         * Simply deleting the existing store:
-         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
-         
-         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
-         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
-         
-         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
-         
-         */
-        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
-        abort();
-    }
-
-    return _persistentStoreCoordinator;
-}
-
-
-#pragma mark -
-#pragma mark Application's documents directory
-
-// Returns the URL to the application's Documents directory.
-- (NSURL *)applicationDocumentsDirectory
-{
-    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
+  [MainThreadMOC saveContext];
 }
 
-
 @end

```

## Sample Project

See the `CoreDataBooks` project to see the detailed code.

## Report issues

Go to the [Issues](https://github.com/TonnyXu/TXCoreDataHelper/issues) page, and post your issue and other questions.