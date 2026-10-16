# cowsay — 天鹅 cowfile 集

| 文件 | 说明 |
|---|---|
| `swan.cow` | 迷你天鹅，闭合喙 |
| `swanhonk.cow` | 迷你天鹅鸣叫变体（`>o`） |
| `bigswan.cow` | 大天鹅；[出处](https://asciiart.website/art/273) |
| `bigswancouple.cow` | 大天鹅一对；[出处](https://asciiart.website/art/274) |

## 使用

`scripts/shell/aliases.sh` 的别名经 `-f` 直接指向仓库文件：

```bash
swansay "honk!"
swanthink "To be, or not to be..."
swanhonk "HONK!"
```

无别名的 cowfile 直接传路径（相对路径需 `./` 前缀，否则 Perl 报 @INC 错）：

```bash
cowsay -f "$DOTFILES_ROOT/manual/cowsay/bigswan.cow" "HONK!"
```

## 预览

```text
$ swanhonk "HONK!"
 _______
< HONK! >
 -------
    \
     \
      \ >o)
           /_///
          (____>
```
