# Branch-SDK-Mac
The Branch SDK for Mac OS X

## To Do
```
## Coding Tasks
* [x] Add common files from iOS
* [x] Set up project
* [x] Create test bed app
* [x] Get device info for mac environment
* [x] Get application info for mac environment
* [x] Open / Install network called correctly
* [x] Open / Install with deep link data
* [x] Make a Branch-Test test project bundle
* [x] Send v2-event
* [x] Deferred deep linking

## Unit Tests
### Branch Events
* [x] BranchEvent.Test.m

### App Installs
* [-] First install app dates.
* [-] Re-open app dates (with app update).
* [-] Re-open app dates (non-update).
* [-] Re-install app dates.

### Open URL Tests
* [x] Open app scheme URL
* [x] Open http scheme URL 
* [x] Delegate Tests

### Request Tests
* [ ] Intrumentation tests.
* [ ] Make sure requests have meta-data when set.

### Functional Tests
* [ ] Set logging enabled / disabled.
* [ ] Set identity.
* [ ] Log out.
* [ ] Make short link.
* [ ] Make long link.

### Tracking Disabled
* [ ] Tracking disabled: Test setting persistence, open link work, long links work, else fail.

## Documentation
### AppleDoc
* https://github.com/tomaz/appledoc
* http://appledoc.gentlebytes.com/appledoc/
* Example: https://www.cocoanetics.com/2011/11/amazing-apple-like-documentation/

### Jazzy
* https://github.com/realm/jazzy
```

## Design Questions
1. Should we be able to directly open an app scheme like:  `testbed-mac://testbed-mac.app.link/ODYeswaVWM` rather just 
    app schemes like `testbed-mac://open?link_click_id=348527481794276288` on Mac?
     
2. Should the Mac SDK be able to process http/https schemes too, like: `https://testbed-mac.app.link/ODYeswaVWM`?

## Notes

### Running framework unit tests with a TEST_HOST  of the parent application.

In the Branch project:
1.  Set `Branch_Test_Host` = $(BUILT_PRODUCTS_DIR)/TestBed-Mac.app/Contents/MacOS/TestBed-Mac
2.  Add `$(BranchTestHost)` to the BranchTest.xctest target `TEST_HOST` build variable.
3.  Add `$(BranchTestHost)` to the BranchTest.xctest target `BUNDLE_LOADER` build variable.

In the TestBed-Mac project:
4.  Add `BranchTests.xctest` to the host app's copy files build phase.
5.  Add `BranchTests.xctest` to the host app's target dependency.
6. Set the test build configuration to `BranchTestHost`.
 
### Random

// Current Version:  $(CURRENT_PROJECT_VERSION)
// http://fredandrandall.com/blog/2011/07/30/how-to-launch-your-macios-app-with-a-custom-url/

```
- application:didReceiveRemoteNotification:
- application:continueUserActivity:restorationHandler:
- (void)application:(NSApplication *)application openURLs:(NSArray<NSURL *> *)urls;
```
### HTTP Headers

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
