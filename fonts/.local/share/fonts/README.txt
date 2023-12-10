packages: 

arch:
```
sudo pacman -S $(echo << "EOF"
	ttf-dejavu # basic symbols missing from ComicCode
	ttf-nerd-fonts-symbols
	ttf-nerd-fonts-symbols-mono
	adobe-source-han-sans-cn-fonts
	adobe-source-han-sans-kr-fonts
	adobe-source-han-sans-tw-fonts
	adobe-source-han-sans-jp-fonts
	adobe-source-han-sans-hk-fonts 
	noto-fonts-emoji
EOF
)
```
