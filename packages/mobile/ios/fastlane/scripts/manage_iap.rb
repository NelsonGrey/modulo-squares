#!/usr/bin/env ruby
# frozen_string_literal: true

# Manages App Store Connect In-App Purchase products via the App Store
# Connect API (v2 inAppPurchases resource), using the same
# APP_STORE_CONNECT_KEY_ID/ISSUER_ID/KEY credentials the Fastfile already
# uses for TestFlight uploads. Fastlane's own `app_store_connect_api_key`
# produces an in-process Spaceship token, not an exportable JWT, so this
# mints its own ES256 JWT to call the REST API directly.
#
# Usage:
#   ruby manage_iap.rb status                 # read-only: app + IAP state
#   ruby manage_iap.rb verify_iap remove_ads   # read-only: check one IAP product

require "jwt"
require "openssl"
require "net/http"
require "uri"
require "json"
require "base64"
require "dotenv"

repo_root = File.expand_path("../../../../..", __dir__)
Dotenv.load(File.join(repo_root, ".env.development")) if File.exist?(File.join(repo_root, ".env.development"))

PRIVATE_KEY_BEGIN_MARKER = ["-----BEGIN", "PRIVATE", "KEY-----"].join(" ")
EC_PRIVATE_KEY_BEGIN_MARKER = ["-----BEGIN", "EC", "PRIVATE", "KEY-----"].join(" ")

def normalized_private_key_content
  raw = ENV["APP_STORE_CONNECT_KEY"].to_s
  raise "Missing APP_STORE_CONNECT_KEY" if raw.strip.empty?

  cleaned = raw.gsub("\0", "").gsub(/\x00/, "").gsub("%", "").strip
  key_content = cleaned
  unless key_content.include?("-----BEGIN")
    decoded = Base64.decode64(key_content.gsub(/\s+/, ""))
    key_content = decoded if decoded.include?("-----BEGIN")
  end

  key_content = key_content.gsub(/\A['"]|['"]\z/, "")
  key_content = key_content.gsub(/\\n/, "\n").gsub(/\r\n?/, "\n")
  key_content = key_content.lines.map(&:strip).reject(&:empty?).join("\n") + "\n"

  unless key_content.include?(PRIVATE_KEY_BEGIN_MARKER) || key_content.include?(EC_PRIVATE_KEY_BEGIN_MARKER)
    raise "APP_STORE_CONNECT_KEY could not be normalized to a valid .p8 key"
  end

  key_content
end

def mint_jwt
  key_id = ENV["APP_STORE_CONNECT_KEY_ID"].to_s.strip
  issuer_id = ENV["APP_STORE_CONNECT_ISSUER_ID"].to_s.strip
  raise "Missing APP_STORE_CONNECT_KEY_ID" if key_id.empty?
  raise "Missing APP_STORE_CONNECT_ISSUER_ID" if issuer_id.empty?

  private_key = OpenSSL::PKey.read(normalized_private_key_content)
  now = Time.now.to_i

  JWT.encode(
    {
      iss: issuer_id,
      iat: now,
      exp: now + (19 * 60), # Apple caps at 20 minutes; leave margin
      aud: "appstoreconnect-v1"
    },
    private_key,
    "ES256",
    { kid: key_id, typ: "JWT" }
  )
end

def asc_get(path)
  uri = URI("https://api.appstoreconnect.apple.com#{path}")
  req = Net::HTTP::Get.new(uri)
  req["Authorization"] = "Bearer #{mint_jwt}"
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  body = JSON.parse(res.body) rescue { "raw" => res.body }
  raise "ASC API GET #{path} failed (#{res.code}): #{body}" unless res.code.to_i.between?(200, 299)

  body
end

def app_id(bundle_id: "com.modulosquares.app.ios")
  result = asc_get("/v1/apps?filter[bundleId]=#{bundle_id}")
  app = result["data"]&.first
  raise "No app found for bundle id #{bundle_id}" unless app

  app["id"]
end

def print_status
  id = app_id
  puts "App Store Connect app id: #{id}"

  versions = asc_get("/v1/apps/#{id}/appStoreVersions?limit=5")
  puts "\nRecent App Store versions:"
  versions["data"].each do |v|
    attrs = v["attributes"]
    puts "  - #{attrs['versionString']}: appStoreState=#{attrs['appStoreState']} (created #{attrs['createdDate']})"
  end

  iaps = asc_get("/v1/apps/#{id}/inAppPurchasesV2?limit=20")
  puts "\nIn-App Purchases:"
  if iaps["data"].empty?
    puts "  (none found)"
  else
    iaps["data"].each do |p|
      attrs = p["attributes"]
      puts "  - #{attrs['productId']}: name=#{attrs['name']} type=#{attrs['inAppPurchaseType']} state=#{attrs['state']}"
    end
  end
end

def verify_iap(product_id)
  id = app_id
  iaps = asc_get("/v1/apps/#{id}/inAppPurchasesV2?filter[productId]=#{product_id}")
  if iaps["data"].empty?
    puts "IAP '#{product_id}' does NOT exist yet in App Store Connect."
    return
  end

  p = iaps["data"].first
  attrs = p["attributes"]
  puts "IAP '#{product_id}' exists:"
  puts "  id: #{p['id']}"
  puts "  name: #{attrs['name']}"
  puts "  type: #{attrs['inAppPurchaseType']}"
  puts "  state: #{attrs['state']}"
  puts "  reviewNote: #{attrs['reviewNote']}"

  # NOTE: localization/price-schedule sub-resource fetching isn't wired up yet --
  # Apple's v2 In-App Purchase relationship names didn't match several
  # reasonable guesses (inAppPurchaseLocalizations as a filtered collection is
  # GET_INSTANCE-only, not GET_COLLECTION; as an `include` on /v1/inAppPurchases
  # it's rejected as an invalid relationship name for this resource). The
  # top-level attributes above (name, type, state) plus the reviewNote (which
  # states the price directly) are sufficient for now to confirm this product
  # already exists correctly configured. Revisit with Apple's current API
  # reference if per-locale localization detail is needed later.
end

command = ARGV[0]
case command
when "status"
  print_status
when "verify_iap"
  product_id = ARGV[1] || "remove_ads"
  verify_iap(product_id)
else
  puts "Usage: ruby manage_iap.rb [status|verify_iap <product_id>]"
  exit 1
end
