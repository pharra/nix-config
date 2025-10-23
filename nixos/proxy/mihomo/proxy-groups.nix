{...}: let
  # 区域/筛选正则（来自你提供的 YAML）
  FilterHK = "^(?=.*(香港|HK|Hong|🇭🇰))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterJP = "^(?=.*(日本|JP|Japan|🇯🇵))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterKR = "^(?=.*(韩国|韓|KR|Korea|🇰🇷))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterSG = "^(?=.*(新加坡|狮城|SG|Singapore|🇸🇬))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterUS = "^(?=.*(美国|US|United States|America|🇺🇸))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterUK = "^(?=.*(英国|UK|United Kingdom|🇬🇧))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterFR = "^(?=.*(法国|FR|France|🇫🇷))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterDE = "^(?=.*(德国|DE|Germany|🇩🇪))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterTW = "^(?=.*(台湾|TW|Taiwan|Wan|🇨🇳|🇨🇳))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterOthers = "^(?!.*(🇭🇰|HK|Hong|香港|🇨🇳|TW|Taiwan|Wan|🇯🇵|JP|Japan|日本|🇸🇬|SG|Singapore|狮城|🇺🇸|US|United States|America|美国|🇩🇪|DE|Germany|德国|🇬🇧|UK|United Kingdom|英国|🇰🇷|KR|Korea|韩国|韓|🇫🇷|FR|France|法国)).*$";
  FilterSave = "^(?=.*((\\s|-)0\\.[0-9](×|x|X)|低倍率|省流|大流量)).*$";
  FilterAdvance = "^(?=.*((?i)(\\s|-)(([1-9](\\.\\d+)?)(×|x|X))|专线|专用|高级|急速|高倍率|IEPL|IPLC|AIA|CTM|CC|iepl|iplc|aia|ctm|cc)).*$";
  FilterLanding = "^(?=.*((?i)落地|家宽|自建)).*$";
  FilterAll = "^(?=.*(.))(?!.*((?i)群|邀请|返利|循环|官网|客服|网站|网址|获取|订阅|流量|到期|机场|下次|版本|官址|备用|过期|已用|联系|邮箱|工单|贩卖|通知|倒卖|防止|国内|地址|频道|无法|说明|使用|提示|特别|访问|支持|教程|关注|更新|作者|加入|(\\b(USE|USED|TOTAL|EXPIRE|EMAIL|Panel|Channel|Author)\\b|(\\d{4}-\\d{2}-\\d{2}|\\d+G)))).*$";
  FilterTunnel = "^(?=.*(香港|HK|Hong|🇭🇰|日本|JP|Japan|🇯🇵|新加坡|狮城|SG|Singapore|🇸🇬|韩国|KR|Korea|🇰🇷|美国|US|United States|America|🇺🇸))^(?!.*(网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点|落地|家宽|自建|×)).*$";
  FilterRate1x = "^(?=.*(?i:(?:0\\.[5-9]\\d*|1(?:\\.(?:[0-4]\\d*|5(?:0*)?))?)\\s*(?:×|x))).*$";
  FilterRate2x = "^(?=.*(?i:(?:1\\.(?:[5-9]\\d*)|2(?:\\.(?:[0-4]\\d*|5(?:0*)?))?)\\s*(?:×|x))).*$";
  FilterRate3x = "^(?=.*(?i:(?:2\\.(?:[5-9]\\d*)|3(?:\\.(?:[0-4]\\d*|5(?:0*)?))?)\\s*(?:×|x))).*$";
  FilterRate5x = "^(?=.*(?i:(?:3\\.(?:5-9]\\d*)|4(?:\\.\\d+)?|5(?:\\.0*)?)\\s*(?:×|x))).*$"; # 保留原始意图（若需严格修正请确认正则）
  # 组类型模板
  Select = {
    type = "select";
    url = "http://1.1.1.1/generate_204";
    hidden = false;
    include-all = true;
  };
  Auto = {
    type = "url-test";
    url = "http://1.1.1.1/generate_204";
    interval = 300;
    tolerance = 50;
    hidden = false;
    include-all = true;
  };
  Loadbalance = {
    type = "load-balance";
    url = "http://1.1.1.1/generate_204";
    interval = 300;
    strategy = "round-robin";
    hidden = false;
    include-all = true;
  };
in {
  services.mihomo.config.proxy-groups = [
    # 主选择组
    {
      name = "节点选择";
      type = "select";
      proxies = [
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "DIRECT"
      ];
      url = "http://1.1.1.1/generate_204";
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Global.png";
    }

    # 手动/自动
    (Select
      // {
        name = "手动选择";
        filter = FilterAll;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Static.png";
      })

    {
      name = "自动选择";
      type = "select";
      proxies = [
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
        "一倍速率"
        "二倍速率"
        "三倍速率"
        "五倍速率"
      ];
      url = "http://1.1.1.1/generate_204";
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
    }

    {
      name = "省流自动";
      type = "select";
      proxies = [
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
        "一倍速率"
        "二倍速率"
        "三倍速率"
        "五倍速率"
      ];
      url = "http://1.1.1.1/generate_204";
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
    }

    # 特殊分组
    (Auto
      // {
        name = "省流选择";
        filter = FilterSave;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })

    (Auto
      // {
        name = "高级选择";
        filter = FilterAdvance;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })

    (Select
      // {
        name = "中继选择";
        filter = FilterAll;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Final.png";
      })

    (Select
      // {
        name = "落地选择";
        filter = FilterLanding;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Global.png";
      })

    (Loadbalance
      // {
        name = "节点轮询";
        filter = FilterTunnel;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Roundrobin.png";
      })

    # 应用分组
    {
      name = "电报信息";
      type = "select";
      proxies = [
        "节点选择"
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
      ];
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Telegram.png";
    }

    {
      name = "人工智能";
      type = "select";
      proxies = [
        "狮城节点"
        "节点选择"
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "香港节点"
        "日本节点"
        "韩国节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
      ];
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/OpenAI.png";
    }

    {
      name = "苹果服务";
      type = "select";
      proxies = [
        "DIRECT"
        "节点选择"
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
      ];
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Apple.png";
    }

    {
      name = "微软服务";
      type = "select";
      proxies = [
        "DIRECT"
        "节点选择"
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
      ];
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Microsoft.png";
    }

    {
      name = "国外媒体";
      type = "select";
      proxies = [
        "节点选择"
        "自动选择"
        "手动选择"
        "省流选择"
        "高级选择"
        "中继选择"
        "落地选择"
        "节点轮询"
        "香港节点"
        "日本节点"
        "韩国节点"
        "狮城节点"
        "美国节点"
        "英国节点"
        "法国节点"
        "德国节点"
        "台湾节点"
      ];
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Streaming.png";
    }

    # 自动选择 - 按地区
    (Auto
      // {
        name = "香港节点";
        filter = FilterHK;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/HK.png";
      })
    (Auto
      // {
        name = "日本节点";
        filter = FilterJP;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/JP.png";
      })
    (Auto
      // {
        name = "韩国节点";
        filter = FilterKR;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/KR.png";
      })
    (Auto
      // {
        name = "狮城节点";
        filter = FilterSG;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/SG.png";
      })
    (Auto
      // {
        name = "美国节点";
        filter = FilterUS;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/US.png";
      })
    (Auto
      // {
        name = "英国节点";
        filter = FilterUK;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/UK.png";
      })
    (Auto
      // {
        name = "法国节点";
        filter = FilterFR;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/FR.png";
      })
    (Auto
      // {
        name = "德国节点";
        filter = FilterDE;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/DE.png";
      })
    (Auto
      // {
        name = "台湾节点";
        filter = FilterTW;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/CN.png";
      })
    (Auto
      // {
        name = "一倍速率";
        filter = FilterRate1x;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })
    (Auto
      // {
        name = "二倍速率";
        filter = FilterRate2x;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })
    (Auto
      // {
        name = "三倍速率";
        filter = FilterRate3x;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })
    (Auto
      // {
        name = "五倍速率";
        filter = FilterRate5x;
        icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
      })
  ];
}
