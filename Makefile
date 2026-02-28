run-dev:
	flutter run --dart-define=BACKEND_URL=http://localhost:3000/api -d 00008130-001935290821401C

run-prod:	
	flutter run --dart-define=BACKEND_URL=https://drawback.chat/api -d 00008130-001935290821401C

build-ios-prod:
	flutter build ios --dart-define=BACKEND_URL=https://drawback.chat/api

build-android-prod:
	flutter build apk --dart-define=BACKEND_URL=https://drawback.chat/api

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