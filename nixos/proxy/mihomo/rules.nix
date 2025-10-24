{...}: let
  RuleSet_classical = {
    type = "http";
    behavior = "classical";
    interval = 43200;
    format = "text";
    proxy = "节点选择";
  };
  RuleSet_domain = {
    type = "http";
    behavior = "domain";
    interval = 43200;
    format = "text";
    proxy = "节点选择";
  };
  RuleSet_ipcidr = {
    type = "http";
    behavior = "ipcidr";
    interval = 43200;
    format = "text";
    proxy = "节点选择";
  };
  RuleSet_filter = {
    type = "http";
    behavior = "domain";
    interval = 43200;
    format = "mrs";
    proxy = "节点选择";
  };
in {
  services.mihomo.config = {
    rules = [
      # 非 IP 类规则
      "RULE-SET,reject_non_ip,REJECT"
      "RULE-SET,reject_domainset,REJECT"
      "RULE-SET,reject_non_ip_drop,REJECT-DROP"
      "RULE-SET,reject_non_ip_no_drop,REJECT"
      "GEOSITE,steam@cn,DIRECT"
      "RULE-SET,cdn_domainset,节点选择"
      "RULE-SET,cdn_non_ip,节点选择"
      "RULE-SET,stream_non_ip,国外媒体"
      "RULE-SET,telegram_non_ip,电报信息"
      "RULE-SET,apple_cdn,DIRECT"
      "RULE-SET,download_domainset,省流自动"
      "RULE-SET,download_non_ip,省流自动"
      "RULE-SET,microsoft_cdn_non_ip,DIRECT"
      "RULE-SET,apple_cn_non_ip,DIRECT"
      "RULE-SET,apple_services,苹果服务"
      "RULE-SET,microsoft_non_ip,微软服务"
      "RULE-SET,ai_non_ip,人工智能"
      "RULE-SET,global_non_ip,节点选择"
      "RULE-SET,domestic_non_ip,DIRECT"
      "RULE-SET,cn,DIRECT"
      "RULE-SET,direct_non_ip,DIRECT"
      "RULE-SET,lan_non_ip,DIRECT"

      # IP 类规则
      "RULE-SET,reject_ip,REJECT"
      "RULE-SET,telegram_ip,电报信息,no-resolve"
      "RULE-SET,stream_ip,国外媒体"
      "RULE-SET,lan_ip,DIRECT,no-resolve"
      "RULE-SET,domestic_ip,DIRECT"
      "RULE-SET,china_ip,DIRECT"
      "MATCH,节点选择"
    ];

    rule-providers = {
      fakeip-filter =
        RuleSet_filter
        // {
          url = "https://testingcf.jsdelivr.net/gh/DustinWin/ruleset_geodata@mihomo-ruleset/fakeip-filter.mrs";
          path = "./rule_set/other_ruleset/fakeip-filter.mrs";
        };

      cn =
        RuleSet_filter
        // {
          url = "https://testingcf.jsdelivr.net/gh/DustinWin/ruleset_geodata@mihomo-ruleset/cn.mrs";
          path = "./rule_set/other_ruleset/cn.mrs";
        };

      private =
        RuleSet_filter
        // {
          url = "https://testingcf.jsdelivr.net/gh/DustinWin/ruleset_geodata@mihomo-ruleset/private.mrs";
          path = "./rule_set/other_ruleset/private.mrs";
        };

      trackerslist =
        RuleSet_filter
        // {
          url = "https://testingcf.jsdelivr.net/gh/DustinWin/ruleset_geodata@mihomo-ruleset/trackerslist.mrs";
          path = "./rule_set/other_ruleset/trackerslist.mrs";
        };

      reject_non_ip_no_drop =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/reject-no-drop.txt";
          path = "./rule_set/sukkaw_ruleset/reject_non_ip_no_drop.txt";
        };

      reject_non_ip_drop =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/reject-drop.txt";
          path = "./rule_set/sukkaw_ruleset/reject_non_ip_drop.txt";
        };

      reject_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/reject.txt";
          path = "./rule_set/sukkaw_ruleset/reject_non_ip.txt";
        };

      reject_domainset =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/domainset/reject.txt";
          path = "./rule_set/sukkaw_ruleset/reject_domainset.txt";
        };

      reject_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/ip/reject.txt";
          path = "./rule_set/sukkaw_ruleset/reject_ip.txt";
        };

      cdn_domainset =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/domainset/cdn.txt";
          path = "./rule_set/sukkaw_ruleset/cdn_domainset.txt";
        };

      cdn_non_ip =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/cdn.txt";
          path = "./rule_set/sukkaw_ruleset/cdn_non_ip.txt";
        };

      stream_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/stream.txt";
          path = "./rule_set/sukkaw_ruleset/stream_non_ip.txt";
        };

      stream_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/ip/stream.txt";
          path = "./rule_set/sukkaw_ruleset/stream_ip.txt";
        };

      ai_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/ai.txt";
          path = "./rule_set/sukkaw_ruleset/ai_non_ip.txt";
        };

      telegram_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/telegram.txt";
          path = "./rule_set/sukkaw_ruleset/telegram_non_ip.txt";
        };

      telegram_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/ip/telegram.txt";
          path = "./rule_set/sukkaw_ruleset/telegram_ip.txt";
        };

      apple_cdn =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/domainset/apple_cdn.txt";
          path = "./rule_set/sukkaw_ruleset/apple_cdn.txt";
        };

      apple_services =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/apple_services.txt";
          path = "./rule_set/sukkaw_ruleset/apple_services.txt";
        };

      apple_cn_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/apple_cn.txt";
          path = "./rule_set/sukkaw_ruleset/apple_cn_non_ip.txt";
        };

      microsoft_cdn_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/microsoft_cdn.txt";
          path = "./rule_set/sukkaw_ruleset/microsoft_cdn_non_ip.txt";
        };

      microsoft_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/microsoft.txt";
          path = "./rule_set/sukkaw_ruleset/microsoft_non_ip.txt";
        };

      download_domainset =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/domainset/download.txt";
          path = "./rule_set/sukkaw_ruleset/download_domainset.txt";
        };

      download_non_ip =
        RuleSet_domain
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/download.txt";
          path = "./rule_set/sukkaw_ruleset/download_non_ip.txt";
        };

      lan_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/lan.txt";
          path = "./rule_set/sukkaw_ruleset/lan_non_ip.txt";
        };

      lan_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/ip/lan.txt";
          path = "./rule_set/sukkaw_ruleset/lan_ip.txt";
        };

      domestic_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/domestic.txt";
          path = "./rule_set/sukkaw_ruleset/domestic_non_ip.txt";
        };

      direct_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/direct.txt";
          path = "./rule_set/sukkaw_ruleset/direct_non_ip.txt";
        };

      global_non_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/non_ip/global.txt";
          path = "./rule_set/sukkaw_ruleset/global_non_ip.txt";
        };

      domestic_ip =
        RuleSet_classical
        // {
          url = "https://ruleset.skk.moe/Clash/ip/domestic.txt";
          path = "./rule_set/sukkaw_ruleset/domestic_ip.txt";
        };

      china_ip =
        RuleSet_ipcidr
        // {
          url = "https://testingcf.jsdelivr.net/gh/Seameee/override-hub@refs/heads/main/mergecnip/china_ip.txt";
          path = "./rule_set/other_ruleset/china_ip.txt";
        };
    };
  };
}
