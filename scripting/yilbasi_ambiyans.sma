/*
 * Yilbasi Ambiyansi (CS 1.6 / ReHLDS + ReGameDLL + ReAPI)
 *
 * Sadece de_dust2 haritasinda calisir, baska haritalarda hicbir sey yapmaz.
 *
 *   - Kar yagisi            (env_snow, oyuncularda cl_weather 1 ayarlanir)
 *   - Hafif mavi-beyaz sis  (her dogusta tekrar gonderilir)
 *   - Girisde karsilama mesaji ve belirli araliklarla yilbasi mesajlari
 *   - Raund basinda yilbasi sesi (sadece ses dosyasi sunucuda varsa)
 *
 * Ses icin: sunucuya cstrike/sound/yilbasi/jingle.wav dosyasini koy, oyuncularin
 * indirebilmesi icin FastDL'e de ekle. Dosya yoksa ses ozelligi sessizce kapali kalir.
 *
 * Cvar'lar (configs/plugins/yilbasi_ambiyans.cfg dosyasi otomatik olusur):
 *   yb_sis_yogunluk  Sis yogunlugu, 0 = sis yok            (varsayilan 0.0006)
 *   yb_mesaj_sure    Yilbasi mesaji araligi (sn), 0 = kapali (varsayilan 180)
 *   yb_ses           1 = raund basinda ses cal              (varsayilan 1)
 *
 * Haritayi degistirmek icin asagidaki HARITA satirini duzenle.
 * Metinler Turkce karakter sorunu yasamamak icin bilerek ASCII yazilmistir.
 */

#include <amxmodx>
#include <fakemeta>
#include <reapi>

#define PLUGIN  "Yilbasi Ambiyansi"
#define VERSION "1.0.0"
#define AUTHOR  "seypaa"

#define HARITA          "de_dust2"
#define SES_DOSYASI     "sound/yilbasi/jingle.wav"
#define SES_PRECACHE    "yilbasi/jingle.wav"
#define SES_OYNAT       "yilbasi/jingle"

const FOG_R = 200;
const FOG_G = 215;
const FOG_B = 235;

const MESAJ_KONTROL_ARALIK = 30;

new bool:g_bAktif;
new bool:g_bSesVar;
new g_iFogMsg;
new g_iGecen;
new g_iMesajSira;

new Float:g_flSisYogunluk;
new g_iMesajSure;
new g_iSesCal;

new const g_szMesajlar[][] =
{
	"Yeni yiliniz kutlu olsun!",
	"Karli dust2'de iyi oyunlar!",
	"Yilbasi hediyesi: bol fragli bir yil!",
	"Mutlu yillar, takim arkadaslarini unutma!"
};

SendFog(const id)
{
	if (!g_iFogMsg || g_flSisYogunluk <= 0.0)
		return;

	message_begin(MSG_ONE_UNRELIABLE, g_iFogMsg, _, id);
	write_byte(FOG_R);
	write_byte(FOG_G);
	write_byte(FOG_B);
	write_long(_:g_flSisYogunluk);
	message_end();
}

public plugin_precache()
{
	new harita[32];
	get_mapname(harita, charsmax(harita));

	if (!equali(harita, HARITA))
		return;

	g_bAktif = true;

	/* Kar efekti: env_snow varligi harita yuklenirken olusturulmali. */
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"));

	if (file_exists(SES_DOSYASI))
	{
		precache_sound(SES_PRECACHE);
		g_bSesVar = true;
	}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	if (!g_bAktif)
		return;

	if (!is_regamedll())
		set_fail_state("Bu eklenti ReGameDLL_CS gerektirir.");

	bind_pcvar_float(create_cvar("yb_sis_yogunluk", "0.0006", _,
		"Sis yogunlugu (0 = sis yok)", true, 0.0, true, 0.01), g_flSisYogunluk);

	bind_pcvar_num(create_cvar("yb_mesaj_sure", "180", _,
		"Yilbasi mesaji araligi, saniye (0 = kapali)", true, 0.0), g_iMesajSure);

	bind_pcvar_num(create_cvar("yb_ses", "1", _,
		"1 = raund basinda yilbasi sesi cal", true, 0.0, true, 1.0), g_iSesCal);

	AutoExecConfig(true, "yilbasi_ambiyans");

	g_iFogMsg = get_user_msgid("Fog");

	register_event("HLTV", "OnYeniRaund", "a", "1=0", "2=0");
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnSpawnPost", true);

	set_task(float(MESAJ_KONTROL_ARALIK), "MesajKontrol", 0, "", 0, "b");
}

public client_putinserver(id)
{
	if (!g_bAktif || is_user_bot(id) || is_user_hltv(id))
		return;

	client_cmd(id, "cl_weather 1");
	set_task(8.0, "Karsila", id);
}

public client_disconnected(id, bool:drop, message[], maxlen)
{
	remove_task(id);
}

public Karsila(const id)
{
	if (!is_user_connected(id))
		return;

	new isim[32];
	get_user_name(id, isim, charsmax(isim));

	client_cmd(id, "cl_weather 1");
	client_print_color(id, print_team_default,
		"^4[Yilbasi] ^1Hos geldin ^3%s^1! Yeni yiliniz kutlu olsun.", isim);
}

public OnSpawnPost(const id)
{
	if (is_user_alive(id))
		SendFog(id);

	return HC_CONTINUE;
}

public OnYeniRaund()
{
	if (g_bSesVar && g_iSesCal)
		client_cmd(0, "spk %s", SES_OYNAT);
}

public MesajKontrol()
{
	g_iGecen += MESAJ_KONTROL_ARALIK;

	if (g_iMesajSure <= 0 || g_iGecen < g_iMesajSure)
		return;

	g_iGecen = 0;

	client_print_color(0, print_team_default, "^4[Yilbasi] ^1%s", g_szMesajlar[g_iMesajSira]);
	g_iMesajSira = (g_iMesajSira + 1) % sizeof g_szMesajlar;
}
