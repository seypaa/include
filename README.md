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

## Yilbasi Ambiyansi (`scripting/yilbasi_ambiyans.sma`)

Sadece `de_dust2` haritasinda calisan yilbasi eklentisi, baska haritalarda hicbir sey yapmaz.
Haritayi degistirmek icin dosyadaki `HARITA` satirini duzenle.

- Kar yagisi (`env_snow`, oyuncularda `cl_weather 1` ayarlanir)
- Hafif mavi-beyaz sis (her dogusta tekrar gonderilir)
- Giriste karsilama mesaji ve belirli araliklarla yilbasi mesajlari
- Raund basinda yilbasi sesi (sadece ses dosyasi varsa)
- Gereksinim: ReHLDS + ReGameDLL_CS + ReAPI

Ses icin `cstrike/sound/yilbasi/jingle.wav` dosyasini sunucuya koy ve FastDL'e ekle.
Dosya yoksa ses ozelligi sessizce kapali kalir.

| Cvar | Varsayilan | Aciklama |
| --- | --- | --- |
| `yb_sis_yogunluk` | `0.0006` | Sis yogunlugu, `0` = sis yok. Oyunu etkiliyorsa dusur |
| `yb_mesaj_sure` | `180` | Yilbasi mesaji araligi (saniye), `0` = kapali |
| `yb_ses` | `1` | `1` = raund basinda ses cal |

Derleme ve kurulum team_secim ile aynidir (`amxxpc scripting/yilbasi_ambiyans.sma -i. -oyilbasi_ambiyans.amxx`).
