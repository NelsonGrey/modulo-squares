#!/usr/bin/env python3
"""Manages the Google Play one-time-product IAP catalog via the Android
Publisher API's newer `oneTimeProducts` resource. The legacy
`inappproducts.insert` endpoint returns PERMISSION_DENIED for this app (see
docs/GO_LIVE_RUNBOOK.md sec 2.6) -- this is the replacement.

IMPORTANT API quirks discovered building this (undocumented / misleading in
Google's own discovery doc -- worth keeping this comment if anyone revisits):
  - `regionsVersion` is NOT a field of the OneTimeProduct resource body
    (despite appearing in its schema) -- it must be passed as the query
    parameter `regionsVersion.version`, dotted notation, url-encoded.
  - `updateMask` is required and non-empty even when creating a brand new
    resource via `allowMissing=true`, despite the API description claiming
    "If a new one-time product is created, update_mask is ignored."
  - GET/list/batchGet use camelCase `oneTimeProducts` in the URL path, but
    `patch` specifically uses lowercase `onetimeproducts`. Not a typo --
    confirmed against Google's live discovery document.
  - `taxAndComplianceSettings.productTaxCategoryCode` is optional -- Google
    applies a sensible default if omitted. Only set it if a specific
    category is required.

Usage:
  manage-play-iap.py status <product_id>          # read-only
  manage-play-iap.py create-draft <product_id> --price 2.99 --currency USD \
      --title "Unlock Premium" --description "Remove ads with a one-time purchase."
      # Creates the product with a real regional price list, in DRAFT state.
      # Does NOT activate it -- that is a separate, deliberate step (see
      # activate-offer below), left for a human to trigger.
  manage-play-iap.py activate-offer <product_id> <purchase_option_id>
      # The one live-activation step this script supports, kept separate
      # and explicit on purpose -- this makes the product actually
      # purchasable for real money.
"""

import argparse
import json
import subprocess
import sys
import urllib.parse

PACKAGE_NAME = "com.modulosquares.app.android"
SA_ACCOUNT = "google-play-console-service@modulo-squares-prod.iam.gserviceaccount.com"
API_BASE = f"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{PACKAGE_NAME}"


def get_token():
    result = subprocess.run(
        [
            "gcloud", "auth", "print-access-token",
            f"--account={SA_ACCOUNT}",
            "--scopes=https://www.googleapis.com/auth/androidpublisher",
        ],
        capture_output=True, text=True, check=True,
    )
    return result.stdout.strip()


class ApiError(Exception):
    def __init__(self, status, body):
        self.status = status
        self.body = body
        super().__init__(f"API error {status}: {body}")


def api_request(method, url, token, body=None):
    # Shells out to curl rather than using urllib directly -- this machine's
    # python.org framework build has an unconfigured CA bundle
    # (CERTIFICATE_VERIFY_FAILED), while curl's system trust store works
    # fine. Keeps this script portable across environments (CI included)
    # without depending on a specific Python SSL/certifi setup.
    cmd = [
        "curl", "-s", "-w", "\n%{http_code}",
        "-H", f"Authorization: Bearer {token}",
        "-H", "Content-Type: application/json",
        "-X", method,
    ]
    if body is not None:
        cmd += ["-d", json.dumps(body)]
    cmd.append(url)

    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    *body_lines, status_line = result.stdout.rsplit("\n", 1)
    status = int(status_line)
    response_text = "\n".join(body_lines) if body_lines else (body_lines[0] if body_lines else "")
    parsed = json.loads(response_text) if response_text.strip() else {}

    if status >= 400:
        raise ApiError(status, parsed)
    return parsed


def cmd_status(args):
    token = get_token()
    try:
        product = api_request(
            "GET", f"{API_BASE}/oneTimeProducts/{args.product_id}", token
        )
    except ApiError as e:
        if e.status == 404:
            print(f"Product '{args.product_id}' does not exist yet.")
            return
        raise

    print(f"Product: {product['productId']}")
    for listing in product.get("listings", []):
        print(f"  [{listing['languageCode']}] {listing['title']!r} -- {listing['description']!r}")
    for po in product.get("purchaseOptions", []):
        regions = len(po.get("regionalPricingAndAvailabilityConfigs", []))
        print(
            f"  purchaseOption '{po['purchaseOptionId']}': state={po.get('state')} "
            f"legacyCompatible={po.get('buyOption', {}).get('legacyCompatible')} "
            f"regions={regions}"
        )


def cmd_create_draft(args):
    token = get_token()

    convert = api_request(
        "POST", f"{API_BASE}/pricing:convertRegionPrices", token,
        body={"price": {"currencyCode": args.currency, "units": str(int(args.price)),
                         "nanos": round((args.price - int(args.price)) * 1_000_000_000)}},
    )
    regions_version = convert["regionVersion"]["version"]
    regional_configs = [
        {"regionCode": code, "price": data["price"], "availability": "AVAILABLE"}
        for code, data in convert["convertedRegionPrices"].items()
    ]
    other = convert["convertedOtherRegionsPrice"]

    product = {
        "packageName": PACKAGE_NAME,
        "productId": args.product_id,
        "listings": [
            {"languageCode": "en-US", "title": args.title, "description": args.description}
        ],
        "purchaseOptions": [
            {
                "purchaseOptionId": args.purchase_option_id,
                "buyOption": {"legacyCompatible": True},
                "regionalPricingAndAvailabilityConfigs": regional_configs,
                "newRegionsConfig": {
                    "usdPrice": other["usdPrice"],
                    "eurPrice": other["eurPrice"],
                    "availability": "AVAILABLE",
                },
            }
        ],
    }

    query = urllib.parse.urlencode({
        "allowMissing": "true",
        "regionsVersion.version": regions_version,
        "updateMask": "listings,purchaseOptions",
    })
    url = f"{API_BASE}/onetimeproducts/{args.product_id}?{query}"
    result = api_request("PATCH", url, token, body=product)

    state = result["purchaseOptions"][0]["state"]
    print(f"Created '{args.product_id}' with {len(regional_configs)} regional prices.")
    print(f"Purchase option '{args.purchase_option_id}' state: {state}")
    if state == "DRAFT":
        print(
            "This is a DRAFT -- not purchasable yet. Run "
            f"'activate-offer {args.product_id} {args.purchase_option_id}' "
            "when ready to make it live (real money, human decision)."
        )


def cmd_activate_offer(args):
    token = get_token()
    url = f"{API_BASE}/onetimeproducts/{args.product_id}/purchaseOptions/{args.purchase_option_id}:activate"
    result = api_request("POST", url, token, body={})
    print(f"Activated. Response: {json.dumps(result, indent=2)}")


parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
sub = parser.add_subparsers(dest="command", required=True)

p_status = sub.add_parser("status")
p_status.add_argument("product_id")
p_status.set_defaults(func=cmd_status)

p_create = sub.add_parser("create-draft")
p_create.add_argument("product_id")
p_create.add_argument("--price", type=float, required=True)
p_create.add_argument("--currency", default="USD")
p_create.add_argument("--title", required=True)
p_create.add_argument("--description", required=True)
p_create.add_argument("--purchase-option-id", default="default", dest="purchase_option_id")
p_create.set_defaults(func=cmd_create_draft)

p_activate = sub.add_parser("activate-offer")
p_activate.add_argument("product_id")
p_activate.add_argument("purchase_option_id")
p_activate.set_defaults(func=cmd_activate_offer)

if __name__ == "__main__":
    args = parser.parse_args()
    args.func(args)
