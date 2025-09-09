{...}: let
  FilterHK = "^(?=.*((?i)🇭🇰|香港|\\b(HK|Hong)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterTW = "^(?=.*((?i)🇹🇼|台湾|\\b(TW|Tai|Taiwan)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterJP = "^(?=.*((?i)🇯🇵|日本|川日|东京|大阪|泉日|埼玉|\\b(JP|Japan)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterKR = "^(?=.*((?i)🇰🇷|韩国|韓|首尔|\\b(KR|Korea)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterSG = "^(?=.*((?i)🇸🇬|新加坡|狮|\\b(SG|Singapore)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterUS = "^(?=.*((?i)🇺🇸|美国|波特兰|达拉斯|俄勒冈|凤凰城|费利蒙|硅谷|拉斯维加斯|洛杉矶|圣何塞|圣克拉拉|西雅图|芝加哥|\\b(US|United States)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterUK = "^(?=.*((?i)🇬🇧|英国|伦敦|\\b(UK|United Kingdom)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterFR = "^(?=.*((?i)🇫🇷|法国|\\b(FR|France)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterDE = "^(?=.*((?i)🇩🇪|德国|\\b(DE|Germany)(\\d+)?\\b))(?!.*((?i)回国|校园|网站|地址|剩余|过期|时间|有效|网址|禁止|邮箱|发布|客服|订阅|节点)).*$";
  FilterOthers = "^(?!.*(🇭🇰|HK|Hong|香港|🇹🇼|TW|Taiwan|Wan|🇯🇵|JP|Japan|日本|🇸🇬|SG|Singapore|狮城|🇺🇸|US|United States|America|美国|🇩🇪|DE|Germany|德国|🇬🇧|UK|United Kingdom|英国|🇰🇷|KR|Korea|韩国|韓|🇫🇷|FR|France|法国)).*$";
  FilterAll = "^(?=.*(.))(?!.*((?i)群|邀请|返利|循环|官网|客服|网站|网址|获取|订阅|流量|到期|机场|下次|版本|官址|备用|过期|已用|联系|邮箱|工单|贩卖|通知|倒卖|防止|国内|地址|频道|无法|说明|使用|提示|特别|访问|支持|教程|关注|更新|作者|加入|(\\b(USE|USED|TOTAL|EXPIRE|EMAIL|Panel|Channel|Author)\\b|(\\d{4}-\\d{2}-\\d{2}|\\d+G)))).*$";

  Select = {
    type = "select";
    url = "http://connectivitycheck.platform.hicloud.com/generate_204";
    disable-udp = false;
    hidden = false;
    include-all = true;
  };
  Auto = {
    type = "url-test";
    url = "http://connectivitycheck.platform.hicloud.com/generate_204";
    interval = 300;
    tolerance = 50;
    disable-udp = false;
    hidden = true;
    include-all = true;
  };
in {
  services.mihomo.config.proxy-groups =
    [
      # 主选择组
      {
        name = "🎯 节点选择";
        type = "select";
        proxies = ["自动选择" "手动选择" "DIRECT"];
        url = "http://connectivitycheck.platform.hicloud.com/generate_204";
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Static.png";
      }
      # 手动/自动
      {
        name = "手动选择";
        type = "select";
        proxies = [
          "🇭🇰 - 手动选择"
          "🇯🇵 - 手动选择"
          "🇰🇷 - 手动选择"
          "🇸🇬 - 手动选择"
          "🇺🇸 - 手动选择"
          "🇬🇧 - 手动选择"
          "🇫🇷 - 手动选择"
          "🇩🇪 - 手动选择"
          "🇹🇼 - 手动选择"
          "Others - 手动选择"
          "AllIn - 手动选择"
        ];
        url = "http://connectivitycheck.platform.hicloud.com/generate_204";
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Cylink.png";
      }
      {
        name = "自动选择";
        type = "select";
        proxies = [
          "🇭🇰 - 自动选择"
          "🇯🇵 - 自动选择"
          "🇰🇷 - 自动选择"
          "🇸🇬 - 自动选择"
          "🇺🇸 - 自动选择"
          "🇬🇧 - 自动选择"
          "🇫🇷 - 自动选择"
          "🇩🇪 - 自动选择"
          "🇹🇼 - 自动选择"
          "AllIn - 自动选择"
        ];
        url = "http://connectivitycheck.platform.hicloud.com/generate_204";
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Urltest.png";
      }
      # 应用分组
      {
        name = "✈️ 电报信息";
        type = "select";
        proxies = [
          "🎯 节点选择"
          "🇭🇰 - 自动选择"
          "🇯🇵 - 自动选择"
          "🇸🇬 - 自动选择"
          "🇺🇸 - 自动选择"
        ];
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Telegram.png";
      }
      {
        name = "🤖 AIGC";
        type = "select";
        proxies = [
          "🇺🇸 - 自动选择"
          "🎯 节点选择"
          "🇭🇰 - 自动选择"
          "🇯🇵 - 自动选择"
          "🇸🇬 - 自动选择"
        ];
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/OpenAI.png";
      }
      {
        name = "🍎 苹果服务";
        type = "select";
        proxies = ["DIRECT" "🎯 节点选择" "🇭🇰 - 自动选择" "🇺🇸 - 自动选择"];
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Apple.png";
      }
      {
        name = "Ⓜ️ 微软服务";
        type = "select";
        proxies = ["DIRECT" "🎯 节点选择" "🇭🇰 - 自动选择" "🇺🇸 - 自动选择"];
        icon = "https://raw.githubusercontent.com/Orz-3/mini/master/Color/Microsoft.png";
      }
    ]
    ++ (map (x: Auto // x) [
      # 自动选择 - 按地区
      {
        name = "🇭🇰 - 自动选择";
        filter = FilterHK;
      }
      {
        name = "🇯🇵 - 自动选择";
        filter = FilterJP;
      }
      {
        name = "🇰🇷 - 自动选择";
        filter = FilterKR;
      }
      {
        name = "🇸🇬 - 自动选择";
        filter = FilterSG;
      }
      {
        name = "🇺🇸 - 自动选择";
        filter = FilterUS;
      }
      {
        name = "🇬🇧 - 自动选择";
        filter = FilterUK;
      }
      {
        name = "🇫🇷 - 自动选择";
        filter = FilterFR;
      }
      {
        name = "🇩🇪 - 自动选择";
        filter = FilterDE;
      }
      {
        name = "🇹🇼 - 自动选择";
        filter = FilterTW;
      }
    ])
    ++ (map (x: Select // x) [
      # 手动选择 - 按地区
      {
        name = "🇭🇰 - 手动选择";
        filter = FilterHK;
      }
      {
        name = "🇯🇵 - 手动选择";
        filter = FilterJP;
      }
      {
        name = "🇰🇷 - 手动选择";
        filter = FilterKR;
      }
      {
        name = "🇸🇬 - 手动选择";
        filter = FilterSG;
      }
      {
        name = "🇺🇸 - 手动选择";
        filter = FilterUS;
      }
      {
        name = "🇬🇧 - 手动选择";
        filter = FilterUK;
      }
      {
        name = "🇫🇷 - 手动选择";
        filter = FilterFR;
      }
      {
        name = "🇩🇪 - 手动选择";
        filter = FilterDE;
      }
      {
        name = "🇹🇼 - 手动选择";
        filter = FilterTW;
      }
      {
        name = "Others - 手动选择";
        filter = FilterOthers;
      }
    ])
    ++ [
      # 全部节点
      (Select
        // {
          name = "AllIn - 手动选择";
          filter = FilterAll;
        })
      (Auto
        // {
          name = "AllIn - 自动选择";
          filter = FilterAll;
        })
    ];
}
