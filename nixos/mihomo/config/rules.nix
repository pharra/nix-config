{...}: let
  ip = {
    type = "http";
    interval = 86400;
    behavior = "ipcidr";
    format = "mrs";
  };
  domain = {
    type = "http";
    interval = 86400;
    behavior = "domain";
    format = "mrs";
  };
in {
  services.mihomo.config = {
    rules = [
      # 按照你的顺序和策略
      "RULE-SET,private_ip,DIRECT,no-resolve"
      "RULE-SET,github_domain,Github"
      "RULE-SET,twitter_domain,Twitter"
      "RULE-SET,youtube_domain,YouTube"
      "RULE-SET,google_domain,Google"
      "RULE-SET,telegram_domain,Telegram"
      "RULE-SET,netflix_domain,NETFLIX"
      "RULE-SET,bilibili_domain,哔哩哔哩"
      "RULE-SET,bahamut_domain,巴哈姆特"
      "RULE-SET,spotify_domain,Spotify"
      "RULE-SET,cn_domain,DIRECT"
      "RULE-SET,geolocation-!cn,其他"

      "RULE-SET,google_ip,Google"
      "RULE-SET,netflix_ip,NETFLIX"
      "RULE-SET,telegram_ip,Telegram"
      "RULE-SET,twitter_ip,Twitter"
      "RULE-SET,cn_ip,DIRECT"
      "MATCH,其他"
    ];
    rule-providers = {
      private_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/private.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_private.mrs";
        };
      cn_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/cn.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_cn.mrs";
        };
      biliintl_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/biliintl.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_biliintl.mrs";
        };
      ehentai_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/ehentai.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_ehentai.mrs";
        };
      github_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/github.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_github.mrs";
        };
      twitter_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/twitter.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_twitter.mrs";
        };
      youtube_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/youtube.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_youtube.mrs";
        };
      google_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/google.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_google.mrs";
        };
      telegram_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/telegram.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_telegram.mrs";
        };
      netflix_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/netflix.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_netflix.mrs";
        };
      bilibili_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/bilibili.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_bilibili.mrs";
        };
      bahamut_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/bahamut.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_bahamut.mrs";
        };
      spotify_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/spotify.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_spotify.mrs";
        };
      pixiv_domain =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/pixiv.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_pixiv.mrs";
        };
      "geolocation-!cn" =
        domain
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geosite/geolocation-!cn.mrs";
          path = "./rule_set/MetaCubeX/geo_geosite_geolocation-!cn.mrs";
        };

      private_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/private.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_private.mrs";
        };
      cn_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/cn.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_cn.mrs";
        };
      google_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/google.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_google.mrs";
        };
      netflix_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/netflix.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_netflix.mrs";
        };
      twitter_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/twitter.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_twitter.mrs";
        };
      telegram_ip =
        ip
        // {
          url = "https://cdn.gh-proxy.com/https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/meta/geo/geoip/telegram.mrs";
          path = "./rule_set/MetaCubeX/geo_geoip_telegram.mrs";
        };
    };
  };
}
