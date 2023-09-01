# frozen_string_literal: true

# vim: set ft=ruby:

## Paths
ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), '../')).freeze
FASTLANE_ROOT = File.join(ROOT_DIR, 'fastlane').freeze
CONFIG_PATH = File.join(FASTLANE_ROOT, 'config').freeze
APP_CONFIG_ROOT = File.join(ROOT_DIR, 'App', 'App', 'Config').freeze
APP_CONFIG_XCCONFIG = File.join(APP_CONFIG_ROOT, 'AppConfig.xcconfig').freeze
APP_CONFIG_GOOGLE = File.join(APP_CONFIG_ROOT, 'GoogleService-Info.plist').freeze
WORKSPACE = File.join(ROOT_DIR, 'crisiscleanup.xcworkspace').freeze

## App Identifiers
APP_ID = {
  dev: 'com.crisiscleanup.dev',
  prod: 'com.crisiscleanup.prod',
  earlyaccess: 'com.crisiscleanup.earlyaccess'
}.freeze

## App Config
APP_CONFIG = {
  apiBaseUrl: ENV['CCU_API_BASE_URL'],
  baseUrl: ENV['CCU_BASE_URL'],
  apiHost: ENV['CCU_API_HOST'],
  debugEmailAddress: ENV['CCU_DEBUG_EMAIL_ADDRESS'],
  debugAccountPassword: ENV['CCU_DEBUG_ACCOUNT_PASSWORD'],
  googleMapsApiKey: ENV['CCU_MAPS_API_KEY']
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
