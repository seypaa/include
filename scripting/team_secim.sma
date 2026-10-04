/*
 * Takim Secim Menusu (CS 1.6 / ReHLDS + ReGameDLL + ReAPI)
 *
 * Oyunun varsayilan takim secme ekranini degistirir:
 *   1. Terrorist
 *   2. Counter-Terrorist
 *   5. Otomatik Sec  (oyuncu sayisi az olan takima yerlestirir)
 *   6. Izleyici
 *   0. Kapat         (sadece zaten bir takimda olan oyuncular icin)
 *
 * Menude her takimdaki oyuncu sayisi gorunur, oyuncunun mevcut takimi
 * ve mp_limitteams yuzunden girilemeyen takim isaretlenir.
 *
 * Komutlar (sohbet): /takim, /team
 *
 * Cvar'lar (configs/plugins/team_secim.cfg dosyasi otomatik olusur):
 *   ts_spec_izin       1 = herkes izleyiciye gecebilir, 0 = sadece yetkililer
 *   ts_yetkili_bayrak  ts_spec_izin 0 iken izleyiciye gecebilen admin bayragi
 *
 * Metinler Turkce karakter sorunu yasamamak icin bilerek ASCII yazilmistir.
 */

#include <amxmodx>
#include <amxmisc>
#include <reapi>

#define PLUGIN  "Takim Secim Menusu"
#define VERSION "1.0.0"
#define AUTHOR  "seypaa"

#define MENU_ID "TakimSecimMenusu"

const TEAM_ID_T    = 1;
const TEAM_ID_CT   = 2;
const TEAM_ID_SPEC = 3;

new g_pLimitTeams;
new g_iSpecIzin;
new g_szYetkiliBayrak[16];

/* Her takimdaki oyuncu sayisi (HLTV haric). count[1] = T, count[2] = CT, count[3] = izleyici. */
CountTeams(count[4])
{
	arrayset(count, 0, sizeof count);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i) || is_user_hltv(i))
			continue;

		new team = _:get_member(i, m_iTeam);

		if (team >= 0 && team < sizeof count)
			count[team]++;
	}
}

/* mp_limitteams'e gore oyuncu bu takima girerse takimlar dengesiz olur mu? */
bool:IsTeamStacked(const id, const team)
{
	if (!g_pLimitTeams)
		return false;

	new limit = get_pcvar_num(g_pLimitTeams);

	if (limit <= 0)
		return false;

	new cur = _:get_member(id, m_iTeam);

	if (cur == team)
		return false;

	new count[4];
	CountTeams(count);

	if (cur == TEAM_ID_T || cur == TEAM_ID_CT)
		count[cur]--;

	new other = (team == TEAM_ID_T) ? TEAM_ID_CT : TEAM_ID_T;

	return bool:(count[team] + 1 - count[other] > limit);
}

/*
 * Oyuncu sayisi az olan takim. Esitlikte oyuncu zaten bir takimdaysa orada kalir,
 * degilse oyunun kendi onceligi, o da yoksa rastgele.
 */
GetSmallerTeam(const id)
{
	new count[4];
	CountTeams(count);

	new cur = _:get_member(id, m_iTeam);
	new bool:inTeam = bool:(cur == TEAM_ID_T || cur == TEAM_ID_CT);

	if (inTeam)
		count[cur]--;

	if (count[TEAM_ID_T] < count[TEAM_ID_CT])
		return TEAM_ID_T;

	if (count[TEAM_ID_CT] < count[TEAM_ID_T])
		return TEAM_ID_CT;

	if (inTeam)
		return cur;

	new priority = _:rg_get_join_team_priority();

	if (priority == TEAM_ID_T || priority == TEAM_ID_CT)
		return priority;

	return random_num(TEAM_ID_T, TEAM_ID_CT);
}

bool:CanSpectate(const id)
{
	return bool:(g_iSpecIzin || (get_user_flags(id) & read_flags(g_szYetkiliBayrak)));
}

GetTeamTag(const id, const team, const cur, tag[], const len)
{
	if (cur == team)
		copy(tag, len, " \y[Takimin]");
	else if (IsTeamStacked(id, team))
		copy(tag, len, " \r[Dolu]");
	else
		tag[0] = 0;
}

ShowTeamMenu(const id)
{
	new count[4];
	CountTeams(count);

	new cur = _:get_member(id, m_iTeam);
	new bool:joined = bool:(cur == TEAM_ID_T || cur == TEAM_ID_CT || cur == TEAM_ID_SPEC);

	new tagT[24], tagCT[24];
	GetTeamTag(id, TEAM_ID_T, cur, tagT, charsmax(tagT));
	GetTeamTag(id, TEAM_ID_CT, cur, tagCT, charsmax(tagCT));

	new menu[512];
	new len = formatex(menu, charsmax(menu), "\yTakim Sec^n^n");

	len += formatex(menu[len], charsmax(menu) - len,
		"\r1. \wTerrorist \d(%d oyuncu)%s^n", count[TEAM_ID_T], tagT);
	len += formatex(menu[len], charsmax(menu) - len,
		"\r2. \wCounter-Terrorist \d(%d oyuncu)%s^n^n", count[TEAM_ID_CT], tagCT);
	len += formatex(menu[len], charsmax(menu) - len,
		"\r5. \wOtomatik Sec^n");
	len += formatex(menu[len], charsmax(menu) - len,
		"\r6. %sIzleyici%s^n", CanSpectate(id) ? "\w" : "\d", (cur == TEAM_ID_SPEC) ? " \y[Buradasin]" : "");

	new keys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_5 | MENU_KEY_6;

	if (joined)
	{
		formatex(menu[len], charsmax(menu) - len, "^n\r0. \wKapat");
		keys |= MENU_KEY_0;
	}

	/* jointeam komutu, oyuncunun menu durumu takim secimi degilse reddedilir. */
	new state = _:get_member(id, m_iMenu);

	if (state != _:Menu_ChooseTeam && state != _:Menu_IGChooseTeam)
		set_member(id, m_iMenu, joined ? Menu_IGChooseTeam : Menu_ChooseTeam);

	show_menu(id, keys, menu, -1, MENU_ID);
}

Deny(const id, const message[])
{
	client_print_color(id, print_team_default, "^4[Takim] ^1%s", message);
	ShowTeamMenu(id);

	return HC_SUPERCEDE;
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	if (!is_regamedll())
		set_fail_state("Bu eklenti ReGameDLL_CS gerektirir.");

	bind_pcvar_num(create_cvar("ts_spec_izin", "1", _,
		"1 = herkes izleyiciye gecebilir, 0 = sadece yetkililer",
		true, 0.0, true, 1.0), g_iSpecIzin);

	bind_pcvar_string(create_cvar("ts_yetkili_bayrak", "a", _,
		"ts_spec_izin 0 iken izleyiciye gecebilen admin bayragi"),
		g_szYetkiliBayrak, charsmax(g_szYetkiliBayrak));

	AutoExecConfig(true, "team_secim");

	g_pLimitTeams = get_cvar_pointer("mp_limitteams");

	register_menucmd(register_menuid(MENU_ID),
		MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_0,
		"TeamMenuHandler");

	register_clcmd("say /takim", "CmdTeamMenu");
	register_clcmd("say_team /takim", "CmdTeamMenu");
	register_clcmd("say /team", "CmdTeamMenu");
	register_clcmd("say_team /team", "CmdTeamMenu");

	RegisterHookChain(RG_ShowVGUIMenu, "OnShowVGUIMenu");
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeam");
}

public CmdTeamMenu(const id)
{
	ShowTeamMenu(id);
	return PLUGIN_HANDLED;
}

/* Oyunun kendi takim menusu yerine bizimkini goster. */
public OnShowVGUIMenu(const id, VGUIMenu:menuType, const bitsSlots, szOldMenu[])
{
	if (menuType != VGUI_Menu_Team || is_user_bot(id) || is_user_hltv(id))
		return HC_CONTINUE;

	ShowTeamMenu(id);
	return HC_SUPERCEDE;
}

/* Hem bizim menuden hem de baska yollardan (konsol, bind) gelen secimleri denetle. */
public OnChooseTeam(const id, MenuChooseTeam:slot)
{
	if (is_user_bot(id) || is_user_hltv(id))
		return HC_CONTINUE;

	if (slot == MenuChoose_T || slot == MenuChoose_CT)
	{
		new team = (slot == MenuChoose_T) ? TEAM_ID_T : TEAM_ID_CT;

		if (IsTeamStacked(id, team))
			return Deny(id, "Bu takim dolu, diger takima gecmelisin.");
	}
	else if (slot == MenuChoose_AutoSelect)
	{
		if (GetSmallerTeam(id) == TEAM_ID_T)
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_T);
		else
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_CT);
	}
	else if (slot == MenuChoose_Spec)
	{
		if (!CanSpectate(id))
			return Deny(id, "Izleyiciye gecme izni kapali.");
	}

	return HC_CONTINUE;
}

public TeamMenuHandler(const id, const key)
{
	switch (key)
	{
		case 0: engclient_cmd(id, "jointeam", "1");
		case 1: engclient_cmd(id, "jointeam", "2");
		case 4: engclient_cmd(id, "jointeam", "5");
		case 5: engclient_cmd(id, "jointeam", "6");
	}

	return PLUGIN_HANDLED;
}
