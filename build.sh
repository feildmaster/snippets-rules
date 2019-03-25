#!/bin/bash

# Exit on error
set -e

# Secure env variables
if [ -z "$TRAVIS_SECURE_ENV_VARS" ]; then
  echo "TRAVIS_SECURE_ENV_VARS: unset, setting to false"
  TRAVIS_SECURE_ENV_VARS=false
else
  echo "TRAVIS_SECURE_ENV_VARS: $TRAVIS_SECURE_ENV_VARS"
fi

# Build
npm install
npm run build

export FIREBASE=./node_modules/.bin/firebase

# Only run test suite when we can decode the service acct
if [ "$TRAVIS_SECURE_ENV_VARS" = false ]; then
  echo "Could not find secure environment variables, skipping integration tests."
else
  $FIREBASE --debug setup:emulators:firestore

  # Directly run the Firestore emulator to force the host
  # See: https://github.com/firebase/quickstart-nodejs/issues/48
  java -jar $HOME/.cache/firebase/emulators/cloud-firestore-emulator-*.jar --host=127.0.0.1 &
  PID=$!

  while ! nc -z localhost 8080; do
    sleep 0.1
  done

  GOOGLE_APPLICATION_CREDENTIALS=service-account.json npm run test

  kill $PID
fi
