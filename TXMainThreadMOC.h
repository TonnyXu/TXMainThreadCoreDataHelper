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
