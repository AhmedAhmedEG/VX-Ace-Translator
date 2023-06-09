# Description
Efficient translator for RPG Maker VX Ace games, fully written in Ruby, that can decompile all .rvdata2 files that are text-related to a readable text files and vice-versa.

# How To Use
Call the VXAceTranslator.exe file with the following arguments:-

```VXAceTranslator.exe -d GAME_DIR|-c DECOMPILED_DIR -o OUTPUT```

# How To Build
1- Make sure you have Ruby v2.7.8, any version higher than that have a different formate for marshaled files, and it's not compatible with the engine.

2- Make sure RubyGems is not installed at all, as it causes crashes with executables generated by Ocra library, a verion of Ocra ripped from the official gem is included in the project.

3- Simply run Build.bat, and make sure you set the project folder as your current working directory.

> **_NOTE:_** As the newest version of RubyGems causes crashes with executables generated by Ocra library, and the source code in the official Ocra github is outdated, and the updated working code is available only in the gem version of Ocra, I installed Ocra gem, copied Ocra folder from RubyGems directory, reinstalled Ruby, and used the copied Ocra library manually, and it worked perfectly.
