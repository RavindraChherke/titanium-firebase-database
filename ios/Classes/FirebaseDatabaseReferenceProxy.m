/**
 * titanium-firebase-database
 *
 * Created by Hans Knöchel
 * Copyright (c) 2018 by Hans Knöchel. All rights reserved.
 */

#import "FirebaseDatabaseReferenceProxy.h"
#import "TiUtils.h"

@implementation FirebaseDatabaseReferenceProxy

- (void)dealloc
{
  [_reference removeAllObservers];
}

- (id)_initWithPageContext:(id<TiEvaluator>)context
      andDatabaseReference:(FIRDatabaseReference *)reference
          observableEvents:(NSArray<NSNumber *> *)observableEvents
{
  if (self = [super _initWithPageContext:context]) {
    _reference = reference;
    if (observableEvents != nil) {
      for (NSNumber *observableEvent in observableEvents) {
        [_reference observeEventType:[TiUtils intValue:observableEvent]
                           withBlock:^(FIRDataSnapshot *_Nonnull snapshot) {
                             [self _sendEvent:@{ @"value" : [snapshot value] } forEventType:[TiUtils intValue:observableEvent]];
                           }];
      }
    }
  }

  return self;
}

- (FirebaseDatabaseReferenceProxy *)child:(id)arguments
{
  ENSURE_SINGLE_ARG(arguments, NSDictionary);

  NSString *identifier = [arguments objectForKey:@"identifier"];
  NSString *path = [arguments objectForKey:@"path"];
  NSString *url = [arguments objectForKey:@"url"];
  NSArray *observableEvents = [arguments objectForKey:@"observableEvents"];

  FIRDatabaseReference *reference = nil;

  if (identifier != nil) {
    reference = [[[FIRDatabase database] reference] child:identifier];
  }

  if (path != nil) {
    reference = [[FIRDatabase database] referenceWithPath:path];
  }

  if (url != nil) {
    reference = [[FIRDatabase database] referenceFromURL:url];
  }

  if (reference == nil) {
    [self throwException:@"Cannot construct database reference" subreason:@"No valid key (identifier, path or url) found" location:CODELOCATION];
  }

  return [[FirebaseDatabaseReferenceProxy alloc] _initWithPageContext:self.pageContext
                                                 andDatabaseReference:reference
                                                     observableEvents:observableEvents];
}

- (void)setValue:(id)value
{
  value = [value objectAtIndex:0];
  [_reference setValue:value];
}

- (void)removeValue:(id)unused
{
  [_reference removeValue];
}

- (void)updateChildValues:(id)childValues
{
  ENSURE_SINGLE_ARG(childValues, NSDictionary);
  [_reference updateChildValues:childValues];
}

- (void)setPriority:(NSNumber *)priority
{
  [_reference setPriority:priority];
}

- (void)_sendEvent:(NSDictionary *)event forEventType:(FIRDataEventType)eventType
{
  NSString *identifier = nil;

  if (eventType == FIRDataEventTypeValue) {
    identifier = @"value";
  } else if (eventType == FIRDataEventTypeChildAdded) {
    identifier = @"add";
  } else if (eventType == FIRDataEventTypeChildRemoved) {
    identifier = @"remove";
  } else if (eventType == FIRDataEventTypeChildMoved) {
    identifier = @"move";
  } else if (eventType == FIRDataEventTypeChildChanged) {
    identifier = @"change";
  }

  if (identifier == nil) {
    [self throwException:@"Invalid constant passed" subreason:@"Expected one of DATA_EVENT_TYPE_*" location:CODELOCATION];
  }

  [self fireEvent:identifier withObject:event];
}

@end
