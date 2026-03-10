run-dev:
	flutter run --dart-define=BACKEND_URL=https://6a57-143-105-174-218.ngrok-free.app/api -d 00008130-001935290821401C

run-prod:	
	flutter run --dart-define=BACKEND_URL=https://drawback.chat/api -d 00008130-001935290821401C

run-web-prod:
	flutter run -d chrome --web-port=28080 --dart-define=BACKEND_URL=https://drawback.chat/api

run-web-dev:
	flutter run -d chrome --web-port=28080 --dart-define=BACKEND_URL=http://localhost:3000/api	

build-ios-prod:
	flutter build ios --dart-define=BACKEND_URL=https://drawback.chat/api

archive-ios:
	./scripts/deploy-ios.sh

# Android builds
build-android-prod:
	# Build App Bundle for Play Store (AAB is required for new apps)
	flutter build appbundle --dart-define=BACKEND_URL=https://drawback.chat/api

build-android-apk-prod:
	# Build APK for testing only (NOT for Play Store)
	flutter build apk --dart-define=BACKEND_URL=https://drawback.chat/api

archive-android:
	./scripts/deploy-android.sh

build-web-prod:
	flutter build web --dart-define=BACKEND_URL=https://drawback.chat/api

tests:
	flutter test

tests-coverage:
	flutter test --coverage

tests-coverage-check:tests-coverage
	./scripts/check_coverage.sh --check

tests-coverage-view:tests-coverage
	./scripts/check_coverage.sh --view

analyze:
	flutter analyze

clean-pods:
	cd ios && pod deintegrate && rm -rf Pods Podfile.lock

clean:
	flutter clean

clean-all: clean clean-pods

install:	
	flutter pub get
	cd ios && pod install

re-install: clean-all install

# Version management
bump-major:
	./scripts/bump-version.sh major

bump-minor:
	./scripts/bump-version.sh minor

bump-patch:
	./scripts/bump-version.sh patch

bump-build:
	./scripts/bump-version.sh build

bump-and-commit-major:
	./scripts/bump-version.sh major --commit

bump-and-commit-minor:
	./scripts/bump-version.sh minor --commit

bump-and-commit-patch:
	./scripts/bump-version.sh patch --commit

inspect-android-bundle:
	bundletool validate --bundle=build/app/outputs/bundle/release/app-release.aab

validate-android-bundle:
	bundletool validate --bundle=build/app/outputs/bundle/release/app-release.aab

generate-android-apks:
	bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=test.apks \
  --ks=~/upload-keystore.jks \
  --ks-key-alias=upload

install-android-bundle:
	bundletool install-apks --apks=test.apks