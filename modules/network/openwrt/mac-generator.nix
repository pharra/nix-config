{lib}: let
  generateMac = type: str: let
    hex = lib.toLower (lib.substring 0 12 (builtins.hashString "sha256" str));
    firstChar = lib.substring 0 1 hex;
    secondCharRaw = lib.substring 1 1 hex;

    # 正确的映射表
    typeMap = {
      unicast = {
        # 单播地址：第1位=0，第2位=1
        # 有效字符：2, 6, a, e
        "0" = "2";
        "1" = "2";
        "2" = "2";
        "3" = "2";
        "4" = "6";
        "5" = "6";
        "6" = "6";
        "7" = "6";
        "8" = "a";
        "9" = "a";
        "a" = "a";
        "b" = "a";
        "c" = "e";
        "d" = "e";
        "e" = "e";
        "f" = "e";
      };
      multicast = {
        # 多播地址：第1位=1
        # 有效字符：1, 3, 5, 7, 9, b, d, f
        "0" = "1";
        "1" = "1";
        "2" = "3";
        "3" = "3";
        "4" = "5";
        "5" = "5";
        "6" = "7";
        "7" = "7";
        "8" = "9";
        "9" = "9";
        "a" = "b";
        "b" = "b";
        "c" = "d";
        "d" = "d";
        "e" = "f";
        "f" = "f";
      };
    };

    modifiedSecondChar = typeMap.${type}.${secondCharRaw};
    fullHex = firstChar + modifiedSecondChar + lib.substring 2 10 hex;
  in "${lib.substring 0 2 fullHex}:${lib.substring 2 2 fullHex}:${lib.substring 4 2 fullHex}:${lib.substring 6 2 fullHex}:${lib.substring 8 2 fullHex}:${lib.substring 10 2 fullHex}";
in {
  unicast = generateMac "unicast";
  multicast = generateMac "multicast";
}
