# JDataStack
Copyright © 2012-2013, Jeremy Tregunna, All Rights Reserved.

JDataStack is an implementation of a multi-context Core Data stack for iOS 5.0 and higher.

## Using

Create an instance of JDataStack like this:

    JDataStack* stack = [[JDataStack alloc] initWithDelegate:delegateObject];

Set up your delegateObject with the two required methods, something like this:

    - (void)dataStack:(JDataStack*)dataStack preflightSetupForPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)persistentStoreCoordinator
    {
        URL* storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Personal.sqlite"];
         
        NSError* error = nil;
        if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
        {
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
            if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
            {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
        NSDictionary* fileAttributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
        if(![[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:[storeURL path] error:&error])
        {
            NSLog(@"Unable to set file protection attribute on store. Error: %@", error);
        }

and likewise:

    - (NSURL*)modelURLForDataStack:(JDataStack*)dataStack
    {
        return [[NSBundle mainBundle] URLForResource:@"Personal" withExtension:@"momd"];
    }

The reason you must supply these is that JDataStack won't know what you've named your model file, or if you want an in-memory persistent store or a sqlite store. You have to set these up according to your application requirements. You can mutate (and are expected to) the `persistentStoreCoordinator` variable in the preflight delegate.

The delegate has other methods you can implement which may be useful for your purposes.

You must pass this instance around in your application. You can check out [JInjector](https://github.com/jeremytregunna/JInjector) for a simple dependency injection tool to help with this in some architectures.

If you have a lot of work to do that you'd like to do in a background context, you can get a new managed object context in a background thread by asking the stack for one:

    NSManagedObjectContext* moc = [stack newPrivateManagedObjectContext];

If you need a reference to the main managed object context:

    NSManagedObjectContext* moc = [stack mainManagedObjectContext];

There is a separate managed object context for writing to disk and it's at the similarly named:

    NSManagedObjectContext* moc = [stack writeManagedObjectContext];

Finally, you can save changes you make like so:

    [moc performBlock:^{
        NSError* error = nil;
        if(![moc save:&error])
            NSLog(@"Error: %@", error);
        [stack writeToDisk]; // Optional, only if you want to persist the changes to disk.
    }];

## License

Copyright (c) 2012-2013, Jeremy Tregunna

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

