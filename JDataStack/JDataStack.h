//
//  JDataStack.h
//  JKit
//
//  Created by Jeremy Tregunna on 2012-12-30.
//  Copyright (c) 2012 Jeremy Tregunna. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol JDataStackDelegate;

@interface JDataStack : NSObject
@property (nonatomic, readonly) NSManagedObjectContext* mainManagedObjectContext;
@property (nonatomic, readonly) NSManagedObjectContext* writeManagedObjectContext;

@property (nonatomic, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectModel* managedObjectModel;

- (instancetype)initWithDelegate:(id<JDataStackDelegate>)delegate;

- (NSManagedObjectContext*)newPrivateManagedObjectContext;

- (void)saveWriteContext;
- (void)saveMainContext;
- (void)saveContext:(NSManagedObjectContext*)context;
- (void)writeToDisk;
- (void)performBlock:(void (^)())block target:(id)target async:(BOOL)async;

@end

@protocol JDataStackDelegate <NSObject>
@required
- (NSURL*)modelURLForDataStack:(JDataStack*)dataStack;
- (void)dataStack:(JDataStack*)dataStack preflightSetupForPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)persistentStoreCoordinator;
@optional
- (void)dataStack:(JDataStack*)dataStack willSaveWithSaveContext:(NSManagedObjectContext*)saveContext;
- (void)dataStack:(JDataStack*)dataStack didSaveWithSaveContext:(NSManagedObjectContext*)saveContext;
- (void)dataStack:(JDataStack*)dataStack didFailWithError:(NSError*)error;
@end
