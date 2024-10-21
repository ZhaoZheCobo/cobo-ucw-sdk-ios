# Cobo UCW SDK iOS

## Installation

The [Swift Package Manager](https://swift.org/package-manager/) (SwiftPM) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

You can create a Swift package or Xcode project and import UCW SDK as a dependency. 

### Swift package

Once you have your Swift package set up, adding UCW SDK to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
        .package(url: "https://github.com/CoboGlobal/cobo-ucw-sdk-ios")
    ]
```

And in the target:

```swift
targets: [
    .target(
        name: "<project_name>",
        dependencies: ["UCWSDK"])
]
```
### Xcode project

Once you have your project set up in Xcode, select `File` > `Add Package Dependency` and enter its repository URL `https://github.com/CoboGlobal/cobo-ucw-sdk-ios`. 

For more information, please refer [here](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app
).

## Usage

 In source file where you want to use UCW SDK add:

```swift
import UCWSDK
```

Use the UCW SDK to initialize a secrets and return a new TSS Node ID.

```swift
let secrets = "secrets.db"
let passphrase = "uKm7@_NQ4xiQn7UbU-!JXaMdJa*BgNJj"

Task {
    do {
        let nodeID = try await initializeSecrets(secretsFile: secrets, passphrase: passphrase)
        print(" TSS Node ID: \(nodeID)")
    } catch {
        print("Error: \(error)")
    }
}
```

##  Notice

Please note that the new UCW SDK has not been released yet, so it is not functional at the moment.
Please be patient and wait for its release.
