/**
 * KHANT VPN private subscription gateway
 *
 * Required Cloudflare bindings / vars:
 * - ACCESS_KEYS: KV namespace binding; each key is a friend's access key.
 *   Store value "active" to allow access; delete or change it to revoke.
 * - GITHUB_TOKEN: secret with read-only Contents access to the private
 *   subscription repository.
 * - GITHUB_OWNER, GITHUB_REPO, GITHUB_FILE, GITHUB_BRANCH: repository location.
 *
 * App subscription URL format:
 *   https://<worker-host>/sub/<friend-access-key>
 */
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function response(body, status = 200, extra = {}) {
  return new Response(body, {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "no-store, no-cache, must-revalidate",
      "X-Content-Type-Options": "nosniff",
      ...extra,
    },
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== "GET" && request.method !== "HEAD") {
      return response("Method not allowed", 405, { Allow: "GET, HEAD, OPTIONS" });
    }
    if (!url.pathname.startsWith("/sub/")) {
      return response("KHANT VPN subscription gateway", 200);
    }

    const accessKey = url.pathname.slice("/sub/".length);
    if (!/^[A-Za-z0-9_-]{24,128}$/.test(accessKey)) {
      return response("Invalid access key", 401);
    }
    if (!env.ACCESS_KEYS || (await env.ACCESS_KEYS.get(accessKey)) !== "active") {
      return response("Access denied", 403);
    }

    const required = ["GITHUB_TOKEN", "GITHUB_OWNER", "GITHUB_REPO", "GITHUB_FILE"];
    for (const name of required) {
      if (!env[name]) return response("Subscription service is not configured", 503);
    }

    const branch = env.GITHUB_BRANCH || "main";
    const apiUrl = new URL(
      "https://api.github.com/repos/" +
      encodeURIComponent(env.GITHUB_OWNER) + "/" +
      encodeURIComponent(env.GITHUB_REPO) + "/contents/" +
      env.GITHUB_FILE.split("/").map(encodeURIComponent).join("/")
    );
    apiUrl.searchParams.set("ref", branch);

    let upstream;
    try {
      upstream = await fetch(apiUrl, {
        headers: {
          Authorization: "Bearer " + env.GITHUB_TOKEN,
          Accept: "application/vnd.github.raw+json",
          "X-GitHub-Api-Version": "2022-11-28",
          "User-Agent": "KHANT-VPN-Subscription-Gateway",
        },
      });
    } catch {
      return response("Subscription source is temporarily unavailable", 502);
    }

    if (!upstream.ok) {
      // Do not reveal GitHub details or credentials to app users.
      return response("Subscription source is unavailable", 502);
    }

    const body = await upstream.text();
    if (!body.trim()) return response("No servers are configured yet", 503);
    return response(request.method === "HEAD" ? null : body, 200);
  },
};
