//
//  SSKValidatorSpec.m
//
//  Copyright (c) 2014 Netguru Sp. z o.o. All rights reserved.
//

#import "SSKValidator.h"

@interface SSKValidationTestModel : NSObject
@property (unsafe_unretained, nonatomic) id value;
@end @implementation SSKValidationTestModel @end

// /////////////////////////////////////////////////////////////////////////////

#define kValue @"value"
#define kValid @"valid"
#define kName @"name"
#define kErrorsNumber @"errorsNumber"
#define kExpectedClass @"expectedClass"

SPEC_BEGIN(SSKValidatorSpec)

describe(@"SSKValidator", ^{
    
#pragma mark - Implementation:
    
    typedef void (^SSKValidationTestBlock)(NSString *, NSString *, NSArray *, void(^)(SSKPropertyValidator *));
    SSKValidationTestBlock testValidation = ^(NSString *name, NSString *errorMessage, NSArray *rules, void(^configureBlock)(SSKPropertyValidator *)) {
        
        describe([NSString stringWithFormat:@"%@ validator", name], ^{
            
            __block SSKPropertyValidator *validator = nil;
            __block SSKValidationTestModel *model = nil;
            
            beforeEach(^{
                model = [[SSKValidationTestModel alloc] init];
                validator = [SSKPropertyValidator validatorForPropertyName:kValue];
            });
            
            specify(^{
                [[validator shouldNot] beNil];
            });
        
            for (NSDictionary *rule in rules) {
                
                context([NSString stringWithFormat:@"using %@", rule[kName]], ^{
                    
                    __block BOOL success; __block  NSError *error; __block NSArray *array;
                    
                    beforeEach(^{
                        configureBlock(validator);
                        model.value = rule[kValue];
                        success = NO; error = nil; array = nil;
                    });
                    
                    NSArray *(^rulesBlock)() = ^NSArray *{
                        return @[validator];
                    };
                    
                    if(![rule[kValue] isKindOfClass:rule[kExpectedClass]]) {
                        
                        it(@"should not accept class other than specified", ^{
                            [[theBlock(^{
                                [SSKValidator validateModel:model error:&error usingRules:rulesBlock];
                            }) should] raiseWithName:NSInternalInconsistencyException];
                            
                            [[theBlock(^{
                                [SSKValidator validateModel:model usingRules:rulesBlock];
                            }) should] raiseWithName:NSInternalInconsistencyException];
                        });
                        
                    } else if ([rule[kValid] isEqualToNumber:@YES]) {
                        
                        it(@"should succeed", ^{
                            success = [SSKValidator validateModel:model error:&error usingRules:rulesBlock];
                            array = [SSKValidator validateModel:model usingRules:rulesBlock];
                            
                            [[theValue(success) should] beYes];
                            [[error should] beNil];
                            [[array should] haveCountOf:[rule[kErrorsNumber] integerValue]];
                        });
                        
                    } else {
                        
                        it(@"should fail", ^{
                            
                            success = [SSKValidator validateModel:model error:&error usingRules:rulesBlock];
                            array = [SSKValidator validateModel:model usingRules:rulesBlock];

                            [[theValue(success) should] beNo];
                            [[error shouldNot] beNil];
                            [[array should] haveCountOf:[rule[kErrorsNumber] integerValue]];
                            
                            if(errorMessage) {
                                [[error.localizedDescription should] containString:errorMessage];
                            }
                        });
                    }
                });
            }
        });
    };
    
    typedef NSDictionary * (^SSKValidationRuleBlock)(NSString *, NSObject *, BOOL, NSUInteger, Class);
    SSKValidationRuleBlock rule = ^(NSString *name, NSObject * value, BOOL valid, NSUInteger errors, Class expectedClass) {
        return @{kValue : value, kName : name, kValid : @(valid), kErrorsNumber : @(errors), kExpectedClass : expectedClass};
    };

#pragma mark - Actual tests:
    
    // Exceptions:
    testValidation(@"any string", nil, @[
         rule(@"incorrect defined class", @123, NO, 1, [NSString class]),
         rule(@"correct defined class", @"123", YES, 0, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.decimal();
    });

    testValidation(@"any number", nil, @[
         rule(@"incorrect defined class", @"YES", NO, 1, [NSNumber class]),
         rule(@"correct defined class", @YES, YES, 0, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.trueValue();
    });
    
    testValidation(@"any date", nil, @[
         rule(@"incorrect defined class", @"2014-12-01", NO, 1, [NSDate class]),
         rule(@"correct defined class", [NSDate dateWithTimeIntervalSinceNow:0], YES, 0, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo([NSDate dateWithTimeIntervalSinceNow:1000], SSKComparisionOperatorLessThan);
    });
    
    // Multiple returns error:
    testValidation(@"maxLength and decimal", nil, @[
         rule(@"to long non-decimal string", @"this_is_not_a_decimal_and_moreover_to_long_string", NO, 2, [NSString class]),
         rule(@"decimal with required length", @"1234567890", YES, 0, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.maxLength(20).decimal();
    });

    // Strings:
    testValidation(@"required", @"Please fill this required field", @[
        rule(@"any value", @"qux", YES, 0, [NSString class]),
        rule(@"no value", [NSNull null], NO, 1, [NSNull class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.required().nilOrEmpty(@"Please fill this required field");
    });

    testValidation(@"emailSyntax", @"Please provide valid email address", @[
        rule(@"email with valid syntax", @"john.appleseed@apple.com", YES, 0, [NSString class]),
        rule(@"email with invalid syntax", @"foo~", NO, 1, [NSString class])
    ], ^(SSKPropertyValidator *validator) {
        validator.emailSyntax().isntEmail(@"Please provide valid email address");
    });

    testValidation(@"decimal", @"This is not decimal!", @[
         rule(@"invalid decimal", @"123ewq", NO, 1, [NSString class]),
         rule(@"valid decimal", @"123567", YES, 0, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.decimal().isntDecimal(@"This is not decimal!");
    });

    testValidation(@"minLength", @"Min length is 20!", @[
         rule(@"to short string", @"veryShoryString", NO, 1, [NSString class]),
         rule(@"string with required length", @"this_string_should_pass_the_test", YES, 0, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.minLength(20).tooShort(@"Min length is 20!");
    });
    
    testValidation(@"maxLength", @"Max length is 25!", @[
         rule(@"to long string", @"this_string_should_not_pass_the_test", NO, 1, [NSString class]),
         rule(@"string with required length", @"veryShoryString", YES, 0, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.maxLength(25).tooLong(@"Max length is 25!");
    });
    
    testValidation(@"exactLength", @"String must have 10 chars", @[
         rule(@"string with correct length", @"this_string_should_pass_the_test", YES, 0, [NSString class]),
         rule(@"to long string", @"this_string_should_not_pass_the_test", NO, 1, [NSString class]),
         rule(@"to short string", @"just_a_String", NO, 1, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.exactLength(32).notExactLength(@"String must have 10 chars");
    });
    
    testValidation(@"lengthRange", @"Provide a string within 15 to 25 chars", @[
         rule(@"string with required length", @"string_which_passes_test", YES, 0, [NSString class]),
         rule(@"to long string", @"this_string_should_not_pass_the_test", NO, 1, [NSString class]),
         rule(@"to short string", @"just_a_String", NO, 1, [NSString class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.lengthRange(15, 25).tooShort(@"Provide a string within 15 to 25 chars").tooLong(@"Provide a string within 15 to 25 chars");
    });

    // Numbers:
    testValidation(@"falseValue", @"This field shoud be unselected", @[
         rule(@"false bool", @NO, YES, 0, [NSNumber class]),
         rule(@"true bool", @YES, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.falseValue().isntFalse(@"This field shoud be unselected");
    });
    
    testValidation(@"trueValue", @"This field shoud be selected", @[
         rule(@"true bool", @YES, YES, 0, [NSNumber class]),
         rule(@"false bool", @NO, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.trueValue().isntTrue(@"This field shoud be selected");
    });
    
    testValidation(@"min", @"min value is 10", @[
         rule(@"expected number", @100, YES, 0, [NSNumber class]),
         rule(@"to small number", @1, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.min(10).tooSmall(@"min value is 10");
    });
    
    testValidation(@"max", @"max value is 10", @[
         rule(@"expected number", @1, YES, 0, [NSNumber class]),
         rule(@"to big number", @100, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.max(10).tooBig(@"max value is 10");
    });
    
    testValidation(@"exact", @"This value should be 10", @[
         rule(@"expected number", @10, YES, 0, [NSNumber class]),
         rule(@"to big number", @100, NO, 1, [NSNumber class]),
         rule(@"to small number", @1, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.exact(10).notExact(@"This value should be 10");
    });
    
    testValidation(@"range", @"Valus should be between 5 and 50", @[
         rule(@"expected number", @10, YES, 0, [NSNumber class]),
         rule(@"to big number", @100, NO, 1, [NSNumber class]),
         rule(@"to small number", @1, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
         validator.range(5, 50).tooSmall(@"Valus should be between 5 and 50").tooBig(@"Valus should be between 5 and 50");
    });

    testValidation(@"compare 2 numbers (equal comparision operator)", @"Both numbers should be same!", @[
          rule(@"correct 2 numbers", @100, YES, 0, [NSNumber class]),
          rule(@"incorrect 2 numbers", @101, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@100, SSKComparisionOperatorEqual).isntEqual(@"Both numbers should be same!");
    });

    testValidation(@"compare 2 numbers (not equal comparision operator)", @"Both numbers shouldn't be same!", @[
        rule(@"correct numbers", @100, YES, 0, [NSNumber class]),
        rule(@"incorrect numbers", @101, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@101, SSKComparisionOperatorNotEqual).isEqual(@"Both numbers shouldn't be same!");
    });

    testValidation(@"compare 2 numbers (less than comparision operator)", @"First number should be smaller than the second one", @[
        rule(@"correct numbers", @100, YES, 0, [NSNumber class]),
        rule(@"incorrect numbers", @110, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@105, SSKComparisionOperatorLessThan).isntLess(@"First number should be smaller than the second one");
    });

    testValidation(@"compare 2 numbers (greater than comparision operator)", @"First number should be greater than the second one", @[
        rule(@"correct numbers", @110, YES, 0, [NSNumber class]),
        rule(@"incorrect numbers", @100, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@105, SSKComparisionOperatorGreaterThan).isntGreater(@"First number should be greater than the second one");
    });

    testValidation(@"compare 2 numbers (less or equal to comparision operator)", @"First number should be less than or equal tothe second one", @[
        rule(@"correct numbers", @100, YES, 0, [NSNumber class]),
        rule(@"incorrect numbers", @110, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@100, SSKComparisionOperatorLessThanOrEqualTo).isntLessOrEqual(@"First number should be less than or equal tothe second one");
    });

    testValidation(@"compare 2 numbers (greater or equal to comparision operator)", @"First number should be greater than or equal to the second one", @[
        rule(@"correct numbers", @110, YES, 0, [NSNumber class]),
        rule(@"incorrect numbers", @100, NO, 1, [NSNumber class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(@110, SSKComparisionOperatorGreaterThanOrEqualTo).isntGreaterOrEqual(@"First number should be greater than or equal to the second one");
    });
    
    // Dates:
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:10];
    
    testValidation(@"compare 2 dates (equal comparision operator)", @"Dates have to be same!", @[
        rule(@"2 same dates", date1, YES, 0, [NSDate class]),
        rule(@"2 different dates", date2, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date1, SSKComparisionOperatorEqual).isntEqual(@"Dates have to be same!");
    });
    
    testValidation(@"compare 2 dates (not equal comparision operator)", @"Dates have to be different!", @[
        rule(@"2 different dates", date1, YES, 0, [NSDate class]),
        rule(@"2 same dates", date2, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date2, SSKComparisionOperatorNotEqual).isEqual(@"Dates have to be different!");
    });
    
    testValidation(@"compare 2 dates (less than comparision operator)", @"First date have to be earlier than or equal to second one", @[
        rule(@"correct dates", date1, YES, 0, [NSDate class]),
        rule(@"incorrect dates", date2, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date2, SSKComparisionOperatorLessThan).isntLess(@"First date have to be earlier than or equal to second one");
    });
    
    testValidation(@"compare 2 dates (greater than comparision operator)", @"First date have to be later than or equal to second one", @[
        rule(@"correct dates", date2, YES, 0, [NSDate class]),
        rule(@"incorrect dates", date1, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date1, SSKComparisionOperatorGreaterThan).isntGreater(@"First date have to be later than or equal to second one");
    });

    testValidation(@"compare 2 dates (less or equal to comparision operator)", @"First date have to be earlier than the second one",@[
        rule(@"correct dates", date1, YES, 0, [NSDate class]),
        rule(@"incorrect dates", date2, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date1, SSKComparisionOperatorLessThanOrEqualTo).isntLessOrEqual(@"First date have to be earlier than the second one");
    });
    
    testValidation(@"compare 2 dates (greater or equal to comparision operator)", @"First date have to be later than the second one", @[
        rule(@"correct dates", date2, YES, 0, [NSDate class]),
        rule(@"incorrect dates", date1, NO, 1, [NSDate class]),
    ], ^(SSKPropertyValidator *validator) {
        validator.compareTo(date2, SSKComparisionOperatorGreaterThanOrEqualTo).isntGreaterOrEqual(@"First date have to be later than the second one");
    });
});

SPEC_END
