#!/bin/sh

#  ci_pre_xcodebuild.sh
#  
#
#  Created by EMRE SOKULLU on 27.03.2023.
#  

# https://developer.apple.com/documentation/xcode/writing-custom-build-scripts

set -e

# https://github.com/mastodon/mastodon-ios/blob/develop/Documentation/Setup.md

# install the rbenv
brew install rbenv

# configure the terminal
which ruby
# > /usr/bin/ruby
echo 'eval "$(rbenv init -)"' >> ~/.zprofile
source ~/.zprofile
which ruby
# > /Users/mainasuk/.rbenv/shims/ruby

# restart the terminal

# install ruby (we use the version defined in .ruby-version)
rbenv install


## Bootstrap

bundle install
bundle exec pod clean
bundle exec arkana -e ./env/.env

# clean pods
bundle exec pod clean

# make install
bundle exec pod install --repo-update
