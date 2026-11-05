# Santa's Draw — iOS

Native SwiftUI client for [letsraffle-api](https://github.com/selamet/letsraffle-api).

## Requirements

- Xcode 16+ (iOS 17 SDK or newer)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Getting started

```bash
make generate   # creates SantasDraw.xcodeproj from project.yml
make open       # opens the project in Xcode
make test       # runs unit tests on the simulator
```

The Xcode project is generated and not committed; edit `project.yml` instead.

## Configuration

| Key            | Debug                          | Release                              |
|----------------|--------------------------------|--------------------------------------|
| `API_BASE_URL` | `http://localhost:8000/api/v1` | `https://api.letsraffle.com/api/v1` |
| `WEB_BASE_URL` | `https://letsraffle.com`       | `https://letsraffle.com`             |

Override locally by creating `Config/Secrets.xcconfig` (git-ignored), e.g.

```
API_BASE_URL = http:$(SLASH)/192.168.1.20:8000/api/v1
```

## Structure

```
SantasDraw/
├── App/            # entry point, settings, config
├── DesignSystem/   # palette, components, illustrations
└── Localization/   # TR / EN strings
```
