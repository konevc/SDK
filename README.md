# Kone AI SDK — Special Offers Tab

Drop-in **"Special Offers"** tab for any app. Adds a free personal AI assistant powered by `go.kone.vc/mcp/chat`. Chat-first UI, quick-question chips, API key authentication.

---

## Platforms

| Platform | File | Install |
|---|---|---|
| React Native | `react-native/src/KoneSpecialOffers.tsx` | npm |
| Flutter | `flutter/lib/kone_sdk.dart` | pub.dev |
| iOS (Swift) | `ios-swift/KoneSDK.swift` | Copy file |
| Android (Kotlin) | `android-kotlin/KoneSDK.kt` | Copy file |
| Web / PWA | `web-pwa/kone-sdk.js` | `<script>` tag or npm |

---

## Quick start by platform

### React Native

```bash
npm install kone-sdk-react-native
```

```tsx
import { KoneSpecialOffers } from 'kone-sdk-react-native';

// Inside your tab navigator:
<Tab.Screen
  name="Special Offers"
  children={() => (
    <KoneSpecialOffers
      apiKey="YOUR_API_KEY"
      siteUrl="https://yourapp.com"
    />
  )}
/>
```

**Custom chips:**
```tsx
<KoneSpecialOffers
  apiKey="YOUR_API_KEY"
  accentColor="#e84c1f"
  quickChips={[
    { label: '🍕 Best pizza near me', question: 'Where can I find the best pizza near me?' },
    { label: '💻 Laptop deals',       question: 'What are the best laptop deals right now?' },
  ]}
/>
```

---

### Flutter

```yaml
# pubspec.yaml
dependencies:
  kone_sdk:
    path: ./kone_sdk   # or pub.dev once published
  http: ^1.2.0
  url_launcher: ^6.2.0
```

```dart
import 'package:kone_sdk/kone_sdk.dart';

// Inside your tab bar:
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Special Offers'),
  ],
)

// In your tab body:
KoneSpecialOffers(
  config: KoneSDKConfig(
    apiKey: 'YOUR_API_KEY',
    siteUrl: 'https://yourapp.com',
    accentColor: Color(0xFF5B6EF5),
  ),
)
```

---

### iOS (Swift)

1. Drag `KoneSDK.swift` into your Xcode project
2. No CocoaPods needed — pure URLSession, no external dependencies

```swift
import UIKit

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let config = KoneSDKConfig(
            apiKey: "YOUR_API_KEY",
            siteUrl: "https://yourapp.com"
        )
        let offersVC = KoneSpecialOffersViewController(config: config)

        viewControllers = [
            makeTab(HomeViewController(), title: "Home",           icon: "house"),
            makeTab(offersVC,             title: "Special Offers", icon: "sparkles"),
            makeTab(ProfileViewController(), title: "Profile",     icon: "person"),
        ]
    }

    private func makeTab(_ vc: UIViewController, title: String, icon: String) -> UIViewController {
        vc.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), tag: 0)
        return vc
    }
}
```

---

### Android (Kotlin)

1. Copy `KoneSDK.kt` into your project under `app/src/main/java/vc/kone/sdk/`
2. Add to `build.gradle`:
```gradle
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
}
```

```kotlin
// In your Activity with BottomNavigationView:
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val config = KoneSDKConfig(
            apiKey  = "YOUR_API_KEY",
            siteUrl = "https://yourapp.com"
        )

        val offersFragment = KoneSpecialOffersFragment.newInstance(config)

        // Add to bottom nav
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, offersFragment)
            .commit()
    }
}
```

---

### Web / PWA

**Via `<script>` tag:**
```html
<script src="kone-sdk.js"></script>
<div id="special-offers-tab" style="height: 600px;"></div>

<script>
  const { KoneSpecialOffers } = KoneSDK;

  new KoneSpecialOffers({
    apiKey:  'YOUR_API_KEY',
    siteUrl: 'https://yourapp.com',
  }).mount('#special-offers-tab');
</script>
```

**Via ES module / npm:**
```js
import { KoneSpecialOffers } from 'kone-sdk-web';

new KoneSpecialOffers({
  apiKey:      'YOUR_API_KEY',
  siteUrl:     'https://yourapp.com',
  accentColor: '#e84c1f',
  quickChips: [
    { label: '👟 Shoes deals',   question: 'Where can I buy cheap shoes in the UK?' },
    { label: '🤖 Top AI tools', question: 'Recommend top AI tools for 2025' },
  ],
}).mount('#special-offers-tab');
```

---

## Config options (all platforms)

| Option | Type | Default | Description |
|---|---|---|---|
| `apiKey` | string | **required** | Your Kone publisher API key |
| `siteUrl` | string | `https://kone.vc` | Your app/site URL (sent as context to AI) |
| `greeting` | string | built-in | Opening message shown to the user |
| `accentColor` | color | `#5b6ef5` | Brand color for buttons and avatar |
| `quickChips` | array | 4 defaults | Quick-question buttons on landing screen |

---

## How it works

```
User opens "Special Offers" tab
  → Landing screen: quick-question chips + "Ask your own question"
  → User taps chip or CTA
  → Chat screen opens
  → Message sent to: POST https://go.kone.vc/mcp/chat
      { url, prompt, api_key, response_id? }
  → AI responds, response_id saved for conversation continuity
  → Footer: "More AI agents ↗ kone.vc/apps.html"
```

---

## Getting an API key

Contact kone.vc to get your publisher API key:  
→ **https://kone.vc/apps.html**
