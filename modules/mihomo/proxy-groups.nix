{
  lib,
  config,
  ...
}: let
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
  FilterAll = "^(?=.*(.))(?!.*((?i)群|邀请|返利|循环|官网|客服|网站|网址|获取|订阅|流量|到期|机场|下次|版本|官址|备用|过期|已用|联系|邮箱|工单|贩卖|通知|倒卖|防止|国内|地址|频道|无法|说明|使用|提示|特别|访问|支持|教程|关注|更新|作者|加入|(\\b(USE|USED|TOTAL|EXPIRE|EMAIL|Panel|Channel|Author)\\b|(\\d{4}-\\d{2}-\\d{2}|\\d+G)))).*$";
  FilterRate1x = "^(?=.*(?i:(\\s|\\||-)((0\\.[0-9]{1,})|1)(?:\\s*(?:×|x))\\b)).*$";
  FilterRate2x = "^(?=.*(?i:(\\s|\\||-)(2)(?:\\s*(?:×|x))\\b)).*$";
  FilterRate3x = "^(?=.*(?i:(\\s|\\||-)(3)(?:\\s*(?:×|x))\\b)).*$";
  FilterRate5x = "^(?=.*(?i:(\\s|\\||-)(5)(?:\\s*(?:×|x))\\b)).*$";
  FilterLJC = "^(?=.*(LJC)).*$";
  FilterHy = "^(?=.*(花云)).*$";

  Select = {
    type = "select";
    url = "http://1.1.1.1/generate_204";
    disable-udp = false;
    hidden = false;
    include-all = true;
  };

  Auto = {
    type = "url-test";
    url = "http://1.1.1.1/generate_204";
    interval = 300;
    tolerance = 50;
    disable-udp = false;
    hidden = true;
    include-all = true;
  };

  Loadbalance = {
    type = "load-balance";
    url = "http://1.1.1.1/generate_204";
    interval = 300;
    strategy = "round-robin";
    disable-udp = false;
    hidden = true;
    include-all = true;
  };

  SelectProxies = [
    "节点选择"
    "DIRECT"
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
in {
  services.mihomo.config.proxy-groups = lib.mkIf config.services.mihomo.enable [
    {
      name = "节点选择";
      type = "select";
      proxies = [
        "自动选择"
        "手动选择"
        "DIRECT"
      ];
      url = "http://1.1.1.1/generate_204";
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Global.png";
    }

    (Select
      // {
        name = "垃圾场";
        filter = FilterLJC;
      })

    (Select
      // {
        name = "花云";
        filter = FilterHy;
      })

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
        "一倍速率"
        "二倍速率"
        "三倍速率"
        "五倍速率"
        "花云"
        "垃圾场"
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
      url = "http://1.1.1.1/generate_204";
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Urltest.png";
    }

    {
      name = "电报信息";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Telegram.png";
    }

    {
      name = "人工智能";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/OpenAI.png";
    }

    {
      name = "苹果服务";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Apple.png";
    }

    {
      name = "Github";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Microsoft.png";
    }

    {
      name = "长桥网站";
      type = "select";
      proxies = SelectProxies;
    }

    {
      name = "微软服务";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Microsoft.png";
    }

    {
      name = "暴雪网站";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Netease.png";
    }

    {
      name = "国外媒体";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Streaming.png";
    }

    {
      name = "其余网站";
      type = "select";
      proxies = SelectProxies;
      icon = "https://testingcf.jsdelivr.net/gh/Orz-3/mini@master/Color/Netease.png";
    }

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

    (Loadbalance
      // {
        name = "其他节点";
        filter = FilterOthers;
      })
  ];
}
