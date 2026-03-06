run-dev:
	flutter run --dart-define=BACKEND_URL=https://6a57-143-105-174-218.ngrok-free.app/api -d 00008130-001935290821401C

run-prod:	
	flutter run --dart-define=BACKEND_URL=https://drawback.chat/api -d 00008130-001935290821401C

run-web-prod:
	flutter run -d chrome --dart-define=BACKEND_URL=https://drawback.chat/api

run-web-dev:
	flutter run -d chrome --dart-define=BACKEND_URL=http://localhost:3000/api	

build-ios-prod:
	flutter build ios --dart-define=BACKEND_URL=https://drawback.chat/api

archive-ios:
	./scripts/deploy-ios.sh

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