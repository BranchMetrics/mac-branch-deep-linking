# Branch-SDK-Mac
The Branch SDK for Mac OS X

## To Do
```
* [x] Add common files from iOS
* [x] Set up project
* [x] Create test bed app
* [x] Get device info for mac environment
* [x] Get application info for mac environment
* [x] Open / Install network called correctly
* [x] Open / Install with deep link data
* [x] Make a Branch-Test test project bundle.
* [ ] Deferred deep linking
* [ ] Send v2-event
```

## Notes

### Running framework unit tests with a TEST_HOST  of the parent application.

1.  Set `Branch_Test_Host` = $(BUILT_PRODUCTS_DIR)/TestBed-Mac.app/Contents/MacOS/TestBed-Mac
2.  Add `$(BranchTestHost)` to the BranchTest.xctest target `TEST_HOST` build variable.
3.  Add `$(BranchTestHost)` to the BranchTest.xctest target `BUNDLE_LOADER` build variable.
4.  Add `BranchTests.xctest` to the host app's copy files build phase.
 
### Random

// Current Version:  $(CURRENT_PROJECT_VERSION)
// http://fredandrandall.com/blog/2011/07/30/how-to-launch-your-macios-app-with-a-custom-url/

```
- application:didReceiveRemoteNotification:
- application:continueUserActivity:restorationHandler:
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls;
```
### Headers
```
{
    "args": {},
    "headers": {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "accept-encoding": "br, gzip, deflate",
        "accept-language": "en-us",
        "cookie": "sails.sid=s%3AL6Xda7UJ52rFiG28BfKB3TzkXtPmkoej.Dsj9VXWMp0aNbS2ajf0Oyetjs9sMZwcaN2ydga5fdVw; _ga=GA1.2.806008704.1526704395; _gid=GA1.2.947786828.1526704395",
        "host": "postman-echo.com",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/11.1 Safari/605.1.15",
        "x-forwarded-port": "443",
        "x-forwarded-proto": "https"
    },
    "url": "https://postman-echo.com/get"
}
```
