# frozen_string_literal: true

# vim: set ft=ruby:

## Paths
ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '../')).freeze
FASTLANE_ROOT = File.join(ROOT_DIR, 'fastlane').freeze
CONFIG_PATH = File.join(FASTLANE_ROOT, 'config').freeze
WORKSPACE = File.join(ROOT_DIR, 'crisiscleanup.xcworkspace').freeze

## App Identifiers
APP_ID = {
  dev: 'com.crisiscleanup.dev',
  prod: 'com.crisiscleanup.prod',
  earlyaccess: 'com.crisiscleanup.earlyaccess'
}.freeze

## Developer Center Auth
APPLE_AUTH = {
  username: ENV['FASTLANE_USER'],
  password: ENV['FASTLANE_PASSWORD'],
  team_id: ENV['FASTLANE_TEAM_ID']
}.freeze

## Code sign keychain
KEYCHAIN = {
  name: ENV['KEYCHAIN_NAME'],
  password: ENV['KEYCHAIN_PASSWORD'],
  path: ENV['KEYCHAIN_PATH']
}.freeze

## Cert (Sigh)
ENV['CERT_KEYCHAIN_PATH'] ||= KEYCHAIN[:path]
ENV['CERT_KEYCHAIN_PASSWORD'] ||= KEYCHAIN[:password]

## Unlock Keychain
ENV['FL_UNLOCK_KEYCHAIN_PATH'] ||= KEYCHAIN[:path]
ENV['FL_UNLOCK_KEYCHAIN_PASSWORD'] ||= KEYCHAIN[:password]

## Match
ENV['MATCH_KEYCHAIN_NAME'] ||= KEYCHAIN[:name]
ENV['MATCH_KEYCHAIN_PASSWORD'] ||= KEYCHAIN[:password]
ENV['MATCH_USERNAME'] ||= APPLE_AUTH[:username]

## Produce
ENV['PRODUCE_USERNAME'] ||= APPLE_AUTH[:username]
ENV['PRODUCE_TEAM_ID'] ||= APPLE_AUTH[:team_id]
ENV['PRODUCE_ITC_TEAM_ID'] ||= APPLE_AUTH[:team_id]
