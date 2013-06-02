//
//  JDataStack.m
//  JKit
//
//  Created by Jeremy Tregunna on 2012-12-30.
//  Copyright (c) 2012 Jeremy Tregunna. All rights reserved.
//

#import "JDataStack.h"

@interface NSIncrementalStore (AFIncrementalStoreAdditions)
- (NSPersistentStoreCoordinator*)backingPersistentStoreCoordinator;
@end

@interface JDataStack ()
@property (nonatomic, strong) id<JDataStackDelegate> delegate;

- (NSURL*)applicationDocumentsDirectory;
@end

@implementation JDataStack

@synthesize delegate = _delegate;
@synthesize mainManagedObjectContext = _mainManagedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize writeManagedObjectContext = _writeManagedObjectContext;

- (instancetype)initWithDelegate:(id<JDataStackDelegate>)delegate
{
    if((self = [super init]))
    {
        NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(_willSave:) name:NSManagedObjectContextWillSaveNotification object:nil];
        [center addObserver:self selector:@selector(_didSave:) name:NSManagedObjectContextDidSaveNotification object:nil];

        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self name:NSManagedObjectContextWillSaveNotification object:nil];
    [center removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    self.delegate = nil;
}

#pragma mark - Core Data Methods

- (void)writeToDisk
{
    NSManagedObjectContext* writeManagedObjectContext = [self writeManagedObjectContext];
    NSManagedObjectContext* mainManagedObjectContext = [self mainManagedObjectContext];

    [mainManagedObjectContext performBlock:^{
        NSError* error = nil;
        if([mainManagedObjectContext hasChanges] && ![mainManagedObjectContext save:&error])
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);

        [writeManagedObjectContext performBlock:^{
            NSError* error = nil;
            if([writeManagedObjectContext hasChanges] && ![writeManagedObjectContext save:&error])
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }];
    }];
}

- (void)performBlock:(void (^)())block target:(id)target async:(BOOL)async
{
    if (async)
        [target performBlock:block];
    else
        [target performBlockAndWait:block];
}

- (void)saveWriteContext
{
    NSManagedObjectContext* managedObjectContext = [self writeManagedObjectContext];
    [self saveContext:managedObjectContext];
}


- (void)saveMainContext
{
    NSManagedObjectContext* managedObjectContext = [self mainManagedObjectContext];
    [self saveContext:managedObjectContext];
}

- (void)saveContext:(NSManagedObjectContext*)context
{
    // You need the performBlock to execute the save on the Context Queue
    void (^block)() = ^{
        NSError* error = nil;
        if([context hasChanges] && ![context save:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
    };

    [self performBlock:block target:context async:YES];
}

#pragma mark - Core Data stack

- (NSManagedObjectContext*)newPrivateManagedObjectContext
{
    NSManagedObjectContext* privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateManagedObjectContext setParentContext:[self mainManagedObjectContext]];
    [privateManagedObjectContext setUndoManager:nil];
    return privateManagedObjectContext;
}

- (NSManagedObjectContext*)writeManagedObjectContext
{
    @synchronized(self)
    {
        if(_writeManagedObjectContext != nil)
            return _writeManagedObjectContext;

        NSPersistentStoreCoordinator* coordinator = [self persistentStoreCoordinator];

        if(coordinator != nil)
        {
            _writeManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
            [_writeManagedObjectContext setUndoManager:nil];
            [_writeManagedObjectContext setPersistentStoreCoordinator:coordinator];
        }

        return _writeManagedObjectContext;
    }
}

- (NSManagedObjectContext*)mainManagedObjectContext
{
    @synchronized(self)
    {
        if(_mainManagedObjectContext != nil)
            return _mainManagedObjectContext;

        _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainManagedObjectContext setParentContext:[self writeManagedObjectContext]];

        return _mainManagedObjectContext;
    }
}

- (NSManagedObjectModel*)managedObjectModel
{
    @synchronized(self)
    {
        if(_managedObjectModel != nil)
            return _managedObjectModel;

        NSURL* modelURL = [self.delegate modelURLForDataStack:self];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        return _managedObjectModel;
    }
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    @synchronized(self)
    {
        if(_persistentStoreCoordinator != nil)
            return _persistentStoreCoordinator;

        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

        [self.delegate dataStack:self preflightSetupForPersistentStoreCoordinator:_persistentStoreCoordinator];

        return _persistentStoreCoordinator;
    }
}

#pragma mark - Notifications

- (void)_willSave:(NSNotification*)notification
{
    if([_delegate respondsToSelector:@selector(dataStack:willSaveWithSaveContext:)])
        [_delegate dataStack:self willSaveWithSaveContext:notification.object];
}

- (void)_didSave:(NSNotification*)notification
{
    NSManagedObjectContext* saveContext = notification.object;
    NSManagedObjectContext* writeContext = self.writeManagedObjectContext;

    if(saveContext == writeContext)
        return;

    if(saveContext.persistentStoreCoordinator && (writeContext.persistentStoreCoordinator != saveContext.persistentStoreCoordinator))
        return;

    [saveContext performBlock:^{
        [saveContext.parentContext performBlock:^{
            [saveContext.parentContext mergeChangesFromContextDidSaveNotification:notification];

            if([_delegate respondsToSelector:@selector(dataStack:didSaveWithSaveContext:)])
                [_delegate dataStack:self didSaveWithSaveContext:saveContext];
        }];
    }];
}

#pragma mark - Application's Documents directory

- (NSURL*)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
