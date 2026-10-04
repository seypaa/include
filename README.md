# include
AMX Mod X - Half-Life 1 Scripting

## Takim Secim Menusu (`scripting/team_secim.sma`)

CS 1.6 icin oyunun varsayilan takim secme ekranini degistiren eklenti.

- `1` Terrorist, `2` Counter-Terrorist, `5` Otomatik Sec, `6` Izleyici
- Menude takim basina oyuncu sayisi, mevcut takim ve `mp_limitteams` yuzunden dolu olan takim gorunur
- Otomatik Sec, oyuncu sayisi az olan takima yerlestirir
- Sohbetten `/takim` veya `/team` yazarak menu tekrar acilir
- Gereksinim: ReHLDS + ReGameDLL_CS + ReAPI

### Cvar'lar

`configs/plugins/team_secim.cfg` ilk calistirmada otomatik olusur.

| Cvar | Varsayilan | Aciklama |
| --- | --- | --- |
| `ts_spec_izin` | `1` | `0` ise sadece yetkililer izleyiciye gecebilir |
| `ts_yetkili_bayrak` | `a` | `ts_spec_izin 0` iken izleyiciye gecebilen admin bayragi |

### Derleme ve kurulum

```
amxxpc scripting/team_secim.sma -i. -oteam_secim.amxx
```

`team_secim.amxx` dosyasini sunucudaki `addons/amxmodx/plugins/` klasorune kopyala,
`addons/amxmodx/configs/plugins.ini` dosyasina `team_secim.amxx` satirini ekle ve haritayi degistir.
