# Converting Turbo/Hotwire/Stimulus Web Apps to Native Android & iOS Apps

> A comprehensive guide for creating native Hotwire Native applications for both Android and iOS platforms from an existing Turbo/Hotwire/Stimulus web application.
>
> **This guide covers all documentation sections:** Getting Started, Path Configuration, Bridge Components, Native Screens, and Configuration for both platforms.

---

## Table of Contents

1. [Understanding Hotwire Native](#understanding-hotwire-native)
2. [Architecture Overview](#architecture-overview)
3. [Android Development](#android-development)
4. [iOS Development](#ios-development)
5. [Path Configuration](#path-configuration)
6. [Bridge Components](#bridge-components)
7. [Native Screens](#native-screens)
8. [App Configuration](#app-configuration)
9. [Web App Modifications](#web-app-modifications)
10. [Advanced Patterns & Progressive Rollout](#advanced-patterns--progressive-rollout)
11. [Testing & Deployment](#testing--deployment)
12. [Troubleshooting](#troubleshooting)

---

## Understanding Hotwire Native

### What is Hotwire Native?

Hotwire Native is a high-level native framework for iOS and Android that allows you to leverage your existing Hotwire web application to build great mobile apps. The framework provides a complete native shell that wraps your web app, managing native navigation while your content remains web-based.

**Key Principle: Content is all web. Navigation is all native.**

### How It Works

1. Hotwire Native displays your server-rendered HTML and CSS within a native mobile shell
2. The framework intercepts link taps and passes control to a native adapter
3. Native navigation and platform-specific animations are handled automatically
4. Screenshots are cached for performance when navigating back
5. Interactive pop gestures (especially on iOS) work seamlessly
6. Your Android and iOS apps update whenever you deploy to your server (no app store review needed for web content)

### Core Benefits

- **No Content Duplication**: Reuse your existing web app's HTML, CSS, and JavaScript
- **Native Performance**: WebView-based navigation with native UI controls and animations
- **Fast Updates**: Deploy updates without app store reviews
- **Progressive Enhancement**: Choose which screens or components to build natively in Swift/Kotlin
- **Single Backend**: One server serves both web and mobile clients
- **Platform-Specific UI**: Uses native navigation controls, back buttons, animations, and gestures

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│     Existing Turbo/Hotwire/Stimulus Web App        │
│        (Rails, Django, Phoenix, etc.)              │
│                                                     │
│  HTML + CSS + JavaScript (Stimulus Controllers)    │
└─────────────────────────────────────────────────────┘
                       ▲
         ┌─────────────┼─────────────────┐
         │             │                 │
    ┌────┴─────┐   ┌──┴──────┐   ┌──────┴────┐
    │  Android │   │   iOS   │   │   Web     │
    │   App    │   │   App   │   │ Browser   │
    │ (Kotlin) │   │ (Swift) │   │ (Chrome)  │
    └──────────┘   └─────────┘   └───────────┘
```

**Each native app:**
- Wraps your web app in a native shell
- Manages a single WebView (Android) / WKWebView (iOS) instance
- Handles native navigation, animations, and gestures
- Intercepts link taps to provide native UX
- Can include native-only screens and components (progressive enhancement)

---

## Android Development

### Prerequisites

- **Android Studio** (latest version recommended)
- **Minimum SDK**: API 28 or higher
- **Language**: Kotlin

### Step 1: Create a New Android Project

1. Open Android Studio
2. Select `File → New → New Project...`
3. Choose the **"Empty Views Activity"** template
4. Configure your project:
   - **Minimum SDK**: API 28 or higher
   - **Build Configuration Language**: Kotlin DSL

### Step 2: Integrate Hotwire Native

#### Add Dependencies

Edit your app's `build.gradle.kts` file (module level, **not** project level):

```kotlin
dependencies {
    implementation("dev.hotwire:core:<latest-version>")
    implementation("dev.hotwire:navigation-fragments:<latest-version>")
}
```

Find the latest version at: https://github.com/hotwired/hotwire-native-android/releases

#### Enable Internet Permission

Edit `AndroidManifest.xml` and add this line **above** the `<application>` tag:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

#### Configure Main Layout

Replace the entire contents of `res/layouts/activity_main.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.fragment.app.FragmentContainerView
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/main_nav_host"
    android:name="dev.hotwire.navigation.navigator.NavigatorHost"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    app:defaultNavHost="false" />
```

#### Initialize MainActivity

Replace `MainActivity.kt` with:

```kotlin
package com.example.myapplication

import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<View>(R.id.main_nav_host).applyDefaultImeWindowInsets()
    }

    override fun navigatorConfigurations() = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = "https://yourdomain.com",  // Your web app URL
            navigatorHostId = R.id.main_nav_host
        )
    )
}
```

**Important**: Replace `"https://yourdomain.com"` with your actual web application URL.

### Step 3: Create an Application Class (Recommended)

Create a new Kotlin file `MyApplication.kt` to configure Hotwire options before the activity is created:

```kotlin
import android.app.Application
import dev.hotwire.navigation.hotwire.Hotwire

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Configure Hotwire options here
        Hotwire.config.debugLoggingEnabled = BuildConfig.DEBUG
        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG

        // Register your custom fragments and bridge components
        // (see later sections for details)
    }
}
```

Register this in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    ...>
    <!-- ... -->
</application>
```

### Step 4: Test the Android App

1. Click `Run → Run 'app'` to launch in the emulator
2. The app should load your web application in a native WebView
3. Tap links to navigate - you should see native push animations
4. Use the back button to navigate backward

---

## iOS Development

### Prerequisites

- **Xcode 15 or higher**
- **iOS 13.0 or later** (typical minimum deployment target)
- **Language**: Swift

### Step 1: Create a New iOS Project

1. Open Xcode
2. Select `File → New → Project...`
3. Choose the iOS **"App"** template
4. Configure your project:
   - **Product Name**: Your app name
   - **Language**: Swift
   - **Interface**: Storyboard
   - Choose a location and click Create

### Step 2: Integrate Hotwire Native

#### Add the Package Dependency

1. In Xcode, select `File → Add Packages...`
2. Enter this URL in the search field: `https://github.com/hotwired/hotwire-native-ios`
3. Ensure your project is selected under "Add to Project"
4. Select the version (default to latest) and click "Add Package"
5. Select your app target and click "Add Package"

#### Initialize AppDelegate

Create or replace your `AppDelegate.swift` with:

```swift
import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Hotwire options here (see Configuration section)
        Hotwire.config.debugLoggingEnabled = true

        // Register your custom bridge components
        // (see later sections for details)

        return true
    }
}
```

#### Initialize SceneDelegate

Replace your `SceneDelegate.swift` with:

```swift
import HotwireNative
import UIKit

let rootURL = URL(string: "https://yourdomain.com")!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private let navigator = Navigator(configuration: .init(
        name: "main",
        startLocation: rootURL
    ))

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigator.rootViewController
        self.window = window
        window.makeKeyAndVisible()

        navigator.start()
    }
}
```

**Important**: Replace `"https://yourdomain.com"` with your actual web application URL.

### Step 3: Test the iOS App

1. Click `Product → Run` to launch in the simulator
2. The app should load your web application in a native WKWebView
3. Tap links to navigate - you should see native push animations
4. Use the back button or swipe from left edge to navigate backward

---

## Path Configuration

Path Configuration is a JSON file that defines how URLs are handled by your native app. This is the **most important concept** for customizing your native app's behavior.

### What Path Configuration Does

- Defines which URLs open in modals vs. pushing to the stack
- Enables/disables pull-to-refresh per-route
- Intercepts URLs to route them to native screens
- Controls navigation animations and gestures
- Can be updated remotely without app store submissions

### Basic Structure

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/new$", "/edit$"],
      "properties": {
        "context": "modal",
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

**How it works:**
- Rules are evaluated in order (first match wins)
- `patterns` are regular expressions matched against the URL path
- `properties` define behavior for matching URLs
- Multiple patterns in one rule are treated as OR

### Android Path Configuration Example

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "uri": "hotwire://fragment/web",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/new$"],
      "properties": {
        "context": "modal",
        "uri": "hotwire://fragment/web/modal/sheet",
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

**Key Android Properties:**
- `context`: "default" (push) or "modal" (present)
- `uri`: Hotwire URI scheme pointing to a fragment (required for default web)
- `pull_to_refresh_enabled`: Boolean
- `title`: Optional native title for the screen

### iOS Path Configuration Example

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/new$"],
      "properties": {
        "context": "modal",
        "pull_to_refresh_enabled": false
      }
    }
  ]
}
```

**Key iOS Properties:**
- `context`: "default" (push) or "modal" (present)
- `pull_to_refresh_enabled`: Boolean
- `view_controller`: String identifier for a native view controller (optional)

### Loading Path Configuration

#### Android

**Option 1: Load from bundled asset and remote server**

Create a JSON file at `app/src/main/assets/json/configuration.json` with your configuration.

In your `Application` class:

```kotlin
import dev.hotwire.navigation.hotwire.Hotwire
import dev.hotwire.navigation.config.PathConfiguration

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/configuration.json",
                remoteFileUrl = "https://example.com/configurations/android_v1.json"
            )
        )
    }
}
```

**Loading Order (if both provided):**
1. Local bundled file (immediate)
2. Locally cached copy of remote file (if exists)
3. Newly downloaded remote file (asynchronously)

#### iOS

**Option 1: Load from bundled asset and remote server**

Add `path-configuration.json` to your Xcode project (make sure it's added to your app target).

In `AppDelegate.swift`:

```swift
import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let localPathConfigURL = Bundle.main.url(
            forResource: "path-configuration",
            withExtension: "json"
        )!
        let remotePathConfigURL = URL(
            string: "https://example.com/configurations/ios_v1.json"
        )!

        Hotwire.loadPathConfiguration(from: [
            .file(localPathConfigURL),
            .server(remotePathConfigURL)
        ])

        return true
    }
}
```

**Loading Order (if both provided):**
1. Local bundled file (immediate)
2. Locally cached copy of remote file (if exists from previous launch)
3. Newly downloaded remote file (asynchronously)

### Query String Matching

By default, path patterns match both the path component AND the query string.

**Example patterns with query strings:**

```json
{
  "patterns": [".*\\?.*foo=bar.*"],
  "properties": { "context": "modal" }
}
```

This matches any URL containing `foo=bar` in the query string.

**iOS only: Disable query string matching:**

```swift
Hotwire.config.pathConfiguration.matchQueryStrings = false
```

### Common Path Configuration Patterns

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": ["^/$"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": true
      }
    },
    {
      "patterns": ["/new$", "/edit$"],
      "properties": {
        "context": "modal",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": ["/search"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": false
      }
    },
    {
      "patterns": [".*"],
      "properties": {
        "context": "default",
        "pull_to_refresh_enabled": true
      }
    }
  ]
}
```

---

## Bridge Components

Bridge Components allow you to create native UI elements that communicate with your Hotwire web app. This is how you progressively enhance your app with native components while maintaining your web app as the source of truth.

### Architecture

Bridge Components consist of three parts:

1. **HTML Markup**: Data attributes that configure Stimulus
2. **Stimulus Controller (JavaScript)**: Handles bridge communication
3. **Native Code**: Kotlin (Android) or Swift (iOS) implementation

### Complete Example: Native Button Component

#### HTML Markup

```html
<a
  href="/profile"
  data-controller="button"
  data-bridge-title="Profile"
>
  View profile
</a>
```

#### Stimulus Controller (JavaScript)

Create a new Stimulus controller in your web app:

```javascript
// app/javascript/controllers/button_controller.js
import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "button"

  connect() {
    super.connect()
    const element = this.bridgeElement
    const title = element.bridgeAttribute("title")

    // Send message to native component
    // Third parameter is callback when native component responds
    this.send("connect", { title }, () => {
      this.element.click()
    })
  }
}
```

**Install the bridge package in your web app:**

```bash
npm install @hotwired/hotwire-native-bridge
```

#### Android Native Component

Create `ButtonComponent.kt`:

```kotlin
import android.util.Log
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {

    override fun onReceive(message: Message) {
        when (message.event) {
            "connect" -> handleConnectEvent(message)
            else -> Log.w("ButtonComponent", "Unknown event: ${message.event}")
        }
    }

    private fun handleConnectEvent(message: Message) {
        val data = message.data<MessageData>() ?: return

        // Add native button to toolbar
        val activity = delegate.destination.activity
        // ... native button implementation using data.title ...

        performButtonClick()
    }

    private fun performButtonClick(): Boolean {
        return replyTo("connect")
    }

    @Serializable
    data class MessageData(
        @SerialName("title")
        val title: String
    )
}
```

Register in your `Application` class:

```kotlin
import dev.hotwire.core.bridge.BridgeComponentFactory

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("button", ::ButtonComponent)
        )
    }
}
```

#### iOS Native Component

Create `ButtonComponent.swift`:

```swift
import HotwireNative
import UIKit

final class ButtonComponent: BridgeComponent {
    override class var name: String { "button" }

    override func onReceive(message: Message) {
        guard let viewController else { return }
        addButton(via: message, to: viewController)
    }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    private func addButton(via message: Message, to viewController: UIViewController) {
        guard let data: MessageData = message.data() else { return }

        let action = UIAction { [unowned self] _ in
            self.reply(to: "connect")
        }

        let item = UIBarButtonItem(title: data.title, primaryAction: action)
        viewController.navigationItem.rightBarButtonItem = item
    }
}

private extension ButtonComponent {
    struct MessageData: Decodable {
        let title: String
    }
}
```

Register in `AppDelegate.swift`:

```swift
import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Hotwire.registerBridgeComponents([
            ButtonComponent.self
        ])
        return true
    }
}
```

### Hide Web Elements When Native Component is Active

Use CSS to hide web elements when the native app supports the component:

```css
/* Hide web button when native app has button component */
[data-bridge-components~="button"][data-controller~="button"] {
    display: none;
}
```

This CSS only applies when:
- The native app has registered the "button" component
- The element has both `data-bridge-components~="button"` and `data-controller~="button"`

### Bridge Component Communication Flow

```
Web (JavaScript)                 Native (Kotlin/Swift)
─────────────────                ──────────────────────
Stimulus Controller
    │
    ├─ send("connect", {...})  ──────────> BridgeComponent.onReceive()
    │                                        │
    │                                        └─ Native UI Implementation
    │                                        │
    │ <─────── reply("connect") ─────────────┘
    │
    └─ Callback executes
       (clicks the button)
```

---

## Native Screens

Native Screens allow you to build complete screens in native code (Swift/Kotlin) while keeping your server and navigation intact. This is the ultimate form of progressive enhancement.

### When to Use Native Screens

- Complex screens with lots of native-only interactions
- Screens requiring native hardware access (camera, contacts, etc.)
- Performance-critical screens with complex state management
- Onboarding flows that need native-like feel

### Android Native Screens

#### Step 1: Create Path Configuration

Define the native screen in your path configuration:

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": ["/numbers$"],
      "properties": {
        "uri": "hotwire://fragment/numbers",
        "title": "Numbers"
      }
    }
  ]
}
```

#### Step 2: Create the Fragment

```kotlin
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import dev.hotwire.navigation.fragments.HotwireFragment
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink

@HotwireDestinationDeepLink(uri = "hotwire://fragment/numbers")
class NumbersFragment : HotwireFragment() {

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Implement your native UI
        val recyclerView = view.findViewById<RecyclerView>(R.id.recycler_view)
        // ... setup native implementation ...
    }
}
```

#### Step 3: Register the Fragment

```kotlin
import dev.hotwire.navigation.hotwire.Hotwire
import dev.hotwire.navigation.fragments.HotwireWebFragment

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.registerFragmentDestinations(
            HotwireWebFragment::class,  // Don't forget this for regular web destinations
            NumbersFragment::class
        )
    }
}
```

### iOS Native Screens

#### Step 1: Create Path Configuration

```json
{
  "settings": {},
  "rules": [
    {
      "patterns": ["/numbers$"],
      "properties": {
        "view_controller": "numbers"
      }
    }
  ]
}
```

#### Step 2: Create the View Controller

```swift
import UIKit

class NumbersViewController: UITableViewController, PathConfigurationIdentifiable {
    static var pathConfigurationIdentifier: String { "numbers" }

    let url: URL

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Implement your native UI
    }
}
```

#### Step 3: Handle the Proposal in SceneDelegate

```swift
import HotwireNative
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private lazy var navigator = Navigator(
        configuration: .init(name: "main", startLocation: rootURL),
        delegate: self
    )
    // ... rest of implementation ...
}

extension SceneDelegate: NavigatorDelegate {
    func handle(
        proposal: VisitProposal,
        from navigator: Navigator
    ) -> ProposalResult {
        switch proposal.viewController {
        case NumbersViewController.pathConfigurationIdentifier:
            let numbersViewController = NumbersViewController(url: proposal.url)
            return .acceptCustom(numbersViewController)
        default:
            return .accept
        }
    }
}
```

### Progressive Rollout with Native Screens

One of the biggest advantages of native screens is the ability to roll back without app store submissions.

If you discover a critical issue with your native screen, simply update your remote path configuration to remove the native routing:

**Before (using native screen):**

```json
{
  "patterns": ["/numbers$"],
  "properties": {
    "uri": "hotwire://fragment/numbers",
    "view_controller": "numbers"
  }
}
```

**After (rolled back to web):**

```json
{
  "patterns": ["/numbers$"],
  "properties": {}
}
```

Now users will see the web version at `/numbers` instead of the native screen. No app update required!

---

## App Configuration

### Android Configuration

Configure Hotwire options in your `Application` class before the activity launches.

```kotlin
import android.app.Application
import dev.hotwire.navigation.hotwire.Hotwire
import dev.hotwire.core.bridge.BridgeComponentFactory

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Debug logging
        Hotwire.config.debugLoggingEnabled = BuildConfig.DEBUG
        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG

        // Set default fragment for web content
        Hotwire.defaultFragmentDestination = HotwireWebFragment::class

        // Register custom fragments
        Hotwire.registerFragmentDestinations(
            HotwireWebFragment::class,
            CustomScreenFragment::class
        )

        // Register bridge components
        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("my-custom", ::MyCustomComponent)
        )

        // Set custom user agent prefix
        Hotwire.config.applicationUserAgentPrefix = "My Application;"

        // Load path configuration
        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/configuration.json",
                remoteFileUrl = "https://example.com/configurations/android_v1.json"
            )
        )
    }
}
```

**Key Configuration Options:**
- `debugLoggingEnabled`: Enable debug logging for visits, bridge elements, etc.
- `webViewDebuggingEnabled`: Enable remote debugging via Chrome DevTools
- `defaultFragmentDestination`: Default fragment for web content
- `applicationUserAgentPrefix`: Custom user agent prefix

The library automatically appends to your user agent:
- "Hotwire Native Android; Turbo Native Android;"
- "bridge-components: [your registered components];"
- Chromium's default user agent

### iOS Configuration

Configure Hotwire options in `AppDelegate.swift` **before** instantiating the Navigator.

```swift
import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // General configuration
        Hotwire.config.debugLoggingEnabled = true
        Hotwire.config.applicationUserAgentPrefix = "My Application;"
        Hotwire.config.showDoneButtonOnModals = true
        Hotwire.config.backButtonDisplayMode = .minimal

        // Turbo configuration
        Hotwire.config.defaultViewController = { url in
            CustomViewController(url: url)
        }
        Hotwire.config.defaultNavigationController = {
            CustomNavigationController()
        }
        Hotwire.config.makeCustomWebView = { session in
            let webView = WKWebView(frame: .zero, configuration: session.webViewConfiguration)
            // Customize web view...
            return webView
        }

        // Path configuration
        Hotwire.config.pathConfiguration.matchQueryStrings = true
        let localPathConfigURL = Bundle.main.url(
            forResource: "path-configuration",
            withExtension: "json"
        )!
        Hotwire.loadPathConfiguration(from: [
            .file(localPathConfigURL),
            .server(URL(string: "https://example.com/configurations/ios_v1.json")!)
        ])

        // Bridge configuration
        Hotwire.config.jsonEncoder = JSONEncoder()  // Custom encoder
        Hotwire.config.jsonDecoder = JSONDecoder()  // Custom decoder

        // Register bridge components
        Hotwire.registerBridgeComponents([
            FormComponent.self,
            MenuComponent.self,
            ButtonComponent.self
        ])

        return true
    }
}
```

**Key Configuration Options:**

**General:**
- `debugLoggingEnabled`: Enable debug logging
- `applicationUserAgentPrefix`: Custom user agent prefix
- `showDoneButtonOnModals`: Show "Done" button on modal screens
- `backButtonDisplayMode`: Control back button appearance

**Turbo:**
- `defaultViewController`: Custom view controller class for web content
- `defaultNavigationController`: Custom navigation controller class
- `makeCustomWebView`: Configure individual WKWebView instances

**Path Configuration:**
- `matchQueryStrings`: Match query strings in path rules

**Bridge:**
- `jsonEncoder`: Custom JSON encoder for bridge payloads
- `jsonDecoder`: Custom JSON decoder for bridge payloads

---

## Web App Modifications

### Minimum Changes Required

Your existing Turbo/Hotwire/Stimulus web app requires **minimal to no changes** to work with native apps:

- ✅ Use existing HTML/CSS/JavaScript as-is
- ✅ Existing Stimulus controllers work automatically
- ✅ Session cookies handle authentication
- ✅ Turbo links and forms work without modification

### Optional: Detect Native App Users

Add logic to detect when users are accessing your app via native apps:

#### Rails Example

```ruby
class ApplicationController < ActionController::Base
  helper_method :hotwire_native_app?

  private

  def hotwire_native_app?
    request.user_agent.include?("Hotwire Native")
  end
end
```

#### Usage in Views

```erb
<% if hotwire_native_app? %>
  <!-- Native app specific content -->
  <div class="native-only">
    This is only shown in the native app
  </div>
<% end %>
```

### Optional: Mobile Viewport Configuration

Ensure your app renders properly on mobile devices:

```html
<head>
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <!-- viewport-fit=cover handles notches and safe areas -->
</head>
```

### Optional: Install Hotwire Native Bridge

To use bridge components in your web app, install the bridge package:

```bash
npm install @hotwired/hotwire-native-bridge
```

Or if using importmap:

```ruby
# config/importmap.rb
pin "@hotwired/hotwire-native-bridge", to: "https://cdn.jsdelivr.net/npm/@hotwired/hotwire-native-bridge@1/dist/index.js"
```

### Optional: Custom API Endpoints for Mobile

Create lightweight API endpoints for native app features:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :settings, only: [:show, :update]
    resources :profile, only: [:show, :update]
  end
end

# app/controllers/api/v1/settings_controller.rb
class Api::V1::SettingsController < ApplicationController
  def show
    render json: current_user.settings
  end

  def update
    current_user.update(settings_params)
    render json: current_user.settings
  end
end
```

### Handling Navigation Events

Emit custom events that bridge code can listen to:

```javascript
// In your Stimulus controllers
document.addEventListener('turbo:load', () => {
  console.log('Page loaded:', window.location.href)

  // Notify native apps of page load
  if (window.HotwireNative) {
    window.HotwireNative.notifyPageLoad?.()
  }
})
```

### Testing Native App Behavior in Browser

Spoof the user agent in your browser's console to test native-specific code:

```javascript
// Chrome DevTools console
Object.defineProperty(navigator, 'userAgent', {
  get: function() { return 'HotwireNative/Android 1.0' }
})

// Refresh page - now hotwire_native_app? will return true
```

---

## Advanced Patterns & Progressive Rollout

### Why Progressive Rollout Matters

In a purely native app, discovering a critical bug forces you to:
1. Fix the bug in code
2. Submit to App Store/Play Store review
3. Wait for review approval (1-7 days typically)
4. Users manually update their app

With Hotwire Native, you can:
1. Update your path configuration immediately
2. Roll back to web version (no review needed)
3. Deploy fixes instantly
4. Gradually migrate back to native

### Example: Rolling Out a Native Screen Gradually

**Phase 1: Start with web content**

```json
{
  "patterns": ["/checkout$"],
  "properties": {}
}
```

**Phase 2: Enable for specific app versions**

```json
{
  "patterns": ["/checkout$"],
  "properties": {
    "uri": "hotwire://fragment/checkout",
    "view_controller": "checkout"
  },
  "release_version_rules": [
    {
      "min_version": "1.0",
      "max_version": "1.5"
    }
  ]
}
```

**Phase 3: If critical bug found, instant rollback**

```json
{
  "patterns": ["/checkout$"],
  "properties": {}
}
```

### Feature Flags in Path Configuration

You can also use custom properties for feature flagging:

```json
{
  "patterns": ["/new-feature"],
  "properties": {
    "enabled": false
  }
}
```

Then in your app:

**Android:**

```kotlin
// Retrieve custom property
val rule = // ... get matching rule ...
val isEnabled = rule.properties["enabled"] as? Boolean ?: true
```

**iOS:**

```swift
// Retrieve custom property
if let rule = proposal.properties["enabled"] as? Bool, !rule {
    // Feature disabled
}
```

---

## Testing & Deployment

### Local Testing

#### Android

1. **Using Emulator:**
   - Android Studio provides emulator devices
   - Replace `localhost` with your machine's IP (e.g., `192.168.1.100:3000`)
   - Or use Android Studio's port forwarding

2. **Using Real Device:**
   - Connect device via USB
   - Enable Developer Mode and USB Debugging
   - `adb` command line for port forwarding:

```bash
adb forward tcp:3000 tcp:3000
```

#### iOS

1. **Using Simulator:**
   - Xcode simulator supports `localhost` directly
   - Use `http://localhost:3000` in your app

2. **Using Real Device:**
   - Must use HTTPS (certificate pinning issues on HTTP)
   - Use ngrok or similar to expose local server:

```bash
ngrok http 3000
```

### Environment-Specific Configuration

#### Android

```kotlin
// build.gradle.kts
flavorDimensions("environment")

productFlavors {
    create("development") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        buildConfigField("String", "API_URL", "\"http://192.168.1.100:3000\"")
    }
    create("staging") {
        dimension = "environment"
        applicationIdSuffix = ".staging"
        buildConfigField("String", "API_URL", "\"https://staging.example.com\"")
    }
    create("production") {
        dimension = "environment"
        buildConfigField("String", "API_URL", "\"https://example.com\"")
    }
}
```

Usage:

```kotlin
val startLocation = BuildConfig.API_URL

override fun navigatorConfigurations() = listOf(
    NavigatorConfiguration(
        name = "main",
        startLocation = startLocation,
        navigatorHostId = R.id.main_nav_host
    )
)
```

#### iOS

```swift
// Create different schemes in Xcode:
// - Development
// - Staging
// - Production

// Then use environment variables:
#if DEBUG
let rootURL = URL(string: "http://localhost:3000")!
#elseif STAGING
let rootURL = URL(string: "https://staging.example.com")!
#else
let rootURL = URL(string: "https://example.com")!
#endif
```

### Building for Production

#### Android

1. **Generate Signed Release Build:**
   - `Build → Generate Signed Bundle / APK...`
   - Select "Android App Bundle" (required for Google Play)
   - Create or select keystore
   - Set up release key password

2. **Configure Release Signing** in `build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}
```

#### iOS

1. **Archive for Distribution:**
   - Select "Any iOS Device" as build target
   - `Product → Archive`
   - In Organizer, click "Distribute App"
   - Select "App Store Connect" for production

2. **Configure Signing:**
   - Use Xcode's automatic signing
   - Or configure manually with provisioning profiles

---

## Troubleshooting

### Common Issues

#### WebView Not Loading

**Android:**
- Check `INTERNET` permission in AndroidManifest.xml
- Verify URL is accessible from device/emulator
- Enable WebView debugging: `Hotwire.config.webViewDebuggingEnabled = true`

**iOS:**
- Check App Transport Security settings for HTTP URLs
- Verify URL is accessible from simulator/device
- Enable debug logging: `Hotwire.config.debugLoggingEnabled = true`

#### Navigation Not Working

- Verify path configuration JSON is valid
- Check patterns are correct regex (escape special chars)
- Ensure path configuration is loaded before navigation starts

#### Bridge Components Not Responding

- Verify component is registered in native code
- Check component name matches exactly (case-sensitive)
- Enable debug logging to see bridge messages
- Verify `@hotwired/hotwire-native-bridge` is installed in web app

#### Authentication Issues

- Session cookies should persist in WebView automatically
- For OAuth, use ASWebAuthenticationSession (iOS) or Custom Tabs (Android)
- Verify cookies are being set correctly in web app

### Debug Logging

**Android:**

```kotlin
Hotwire.config.debugLoggingEnabled = true
Hotwire.config.webViewDebuggingEnabled = true
```

Then use Chrome DevTools: `chrome://inspect/#devices`

**iOS:**

```swift
Hotwire.config.debugLoggingEnabled = true
```

Then check Xcode console output.

---

## Additional Resources

- [Official Hotwire Native Documentation](https://native.hotwired.dev/)
- [Hotwire Native iOS GitHub](https://github.com/hotwired/hotwire-native-ios)
- [Hotwire Native Android GitHub](https://github.com/hotwired/hotwire-native-android)
- [Hotwire Native Bridge (JavaScript)](https://github.com/hotwired/hotwire-native-bridge)
- [Joe Masilotti's Hotwire Native Tutorials](https://masilotti.com/articles/)
- [37signals Hotwire Native Announcement](https://dev.37signals.com/announcing-hotwire-native/)

---

*Guide created: 2025-12-28*
*Based on Hotwire Native iOS v1.2.2 and Android v1.2.4*
