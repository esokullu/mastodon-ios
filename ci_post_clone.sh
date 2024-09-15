#!/bin/sh

#  ci_pre_xcodebuild.sh
#  
#
#  Created by EMRE SOKULLU on 27.03.2023.
#  

# https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e

echo "Beginning..."
# https://github.com/mastodon/mastodon-ios/blob/develop/Documentation/Setup.md

# install the rbenv
brew install rbenv
echo "brew install rbenv [done] ..."


echo 'eval "$(rbenv init -)"' >> ~/.zprofile
echo "rbenv INIT [done] ..."

source ~/.zprofile
echo "source zprofile [done] ..."


# install ruby (we use the version defined in .ruby-version)
rbenv install
echo "rbenv install [done] ..."

## Bootstrap

bundle install
echo "bundle install [done] ..."

bundle exec pod clean
echo "bundle exec pod clean [done] ..."

bundle exec arkana -e ./env/.env
echo "bundle exec arkana [done] ..."

# clean pods
bundle exec pod clean
echo "bundle exec pod clean [done] ..."

# make install
bundle exec pod install --repo-update
echo "bundle exec pod install [done] ..."
