{ pkgs, ... }:

{
  programs.git = {
    enable = true;

    ignores = [
      ".DS_Store"
      "mise.toml"
      "**/.claude/settings.local.json"
      "**/.claude/.cc-writes/"
      "tmp"
    ]

    settings = {
      user = {
        name = "ta2min";
        email = "ta2mi.prostudy@gmail.com";
      };

      alias = {
        st = "status";
        ss = "status";
        co = "checkout";
        sw = "switch";
        c = "commit";
        cm = "commit -m";
        cno = "commit --amend --no-edit";
        pushf = "push --force-with-lease --force-if-includes";
      };

      core = {
        editor = "code --wait";
        hooksPath = "/Users/ta2min/.config/git/hooks";
      };

      push = {
        autoSetupRemote = true;
      };
    };
  };
}
