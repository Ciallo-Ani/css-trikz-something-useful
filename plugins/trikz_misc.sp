/**
 *		Trikz -- Miscellaneous
*/

#define PLUGIN_NAME           "Trikz - Miscellaneous"
#define PLUGIN_AUTHOR         "Bara, Bacardi, Ciallo, Denwo, Dr!fter, George, Grey83, Gurman, IT-KiLLER, Killjoy64, Log, NeoxX, Oshizu, ReFlexPoison, Selja, Shavit, Skydive, Smesh, Skipper, Thetwistedpanda, TnTSCS, Zipcorem"
#define PLUGIN_DESCRIPTION    "Expert zone plugins compilation(see './import_misc')"
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            "https://github.com"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <cstrike>
#include <dhooks>
#include <shavit>
#include <morecolors>
#include <trikz>

#pragma newdecls required
#pragma semicolon 1

#define FLASHBANG_W				"models/faqgame/flash/flashbang.mdl"
#define ping_path				"models/expert_zone/pingtool/pingtool"
#define circle_arrow_path			"materials/expert_zone/pingtool/circle_arrow"
#define circle_point_path			"materials/expert_zone/pingtool/circle_point"
#define grad_path				"materials/expert_zone/pingtool/grad"
#define click_path				"expert_zone/pingtool/click.wav"
#define dGIGN					"models/expert_zone/player/ct_gign.mdl"
#define dGSG9					"models/expert_zone/player/ct_gsg9.mdl"
#define dSAS					"models/expert_zone/player/ct_sas.mdl"
#define dURBAN					"models/expert_zone/player/ct_urban.mdl"
#define	OBS_MODE_IN_EYE 4			// follow a player in first person view
#define	OBS_MODE_CHASE 5			// follow a player in third person view
#define MAX_COLORS 7

enum struct colors_t
{
	int iId;
	char sColorName[8];
	int iRed;
	int iGreen;
	int iBlue;
}

enum struct model_t
{
	int iGIGN;
	int iGSG9;
	int iSAS;
	int iURBAN;
}

enum struct skin_t
{
	// cookies
	Handle iType;
	Handle iRGB;
}

enum struct skincolor_t
{
	int iRED;
	int iGREEN;
	int iBLUE;
}

enum
{
	Type_Default,
	Type_Lightmap,
	Type_Fullbright
}

bool gB_IsCPLoaded;
bool gB_Late = false;
bool gB_CanPing[MAXPLAYERS] = {true, ...};
bool gB_Ammo[MAXPLAYERS+1];
bool gB_AmmoCheck[MAXPLAYERS+1];
bool gB_AutoSwitch[MAXPLAYERS+1];
bool gB_AutoFlash[MAXPLAYERS+1];
bool gB_Checkpoint[MAXPLAYERS+1][3];
bool gB_FlashThrown[MAXPLAYERS+1];
bool gB_Mirror_Trigger[MAXPLAYERS+1];
bool gB_Hurt[MAXPLAYERS+1];
bool gB_Noclip[MAXPLAYERS+1];
bool gB_Restore[MAXPLAYERS+1][2];
bool gB_Request[MAXPLAYERS+1][MAXPLAYERS+1];
bool gB_Viewmodel[MAXPLAYERS+1];

int gI_AngleStats[MAXPLAYERS+1];
int gI_Button[MAXPLAYERS+1];
int gI_Cooldown[MAXPLAYERS+1];
int gI_tick[MAXPLAYERS+1];
int gI_FlashModelIndex;
int gI_Partner[MAXPLAYERS+1] = {-1, ...};
int gI_Pings[MAXPLAYERS+1];
int gI_Partner_Pings[MAXPLAYERS+1];
int gI_PreferedType[MAXPLAYERS+1]; // client prefered type -> as Integer
int gI_Skin[MAXPLAYERS+1];
int gI_SpectatorTarget[MAXPLAYERS+1];
int gI_Stored_Partnered[MAXPLAYERS+1];

float gF_autocheckpoint[MAXPLAYERS+1][3][3];
float gF_checkpoint[MAXPLAYERS+1][2][3][3];
float gF_LastThrowTime[MAXPLAYERS + 1];

char gS_PreferedTypeString[MAXPLAYERS+1][10]; // client prefered type -> as Char[10]
char gS_Profile[MAXPLAYERS+1][64];
char gS_SkinType_Default[2];
char gS_SkinType_Lightmap[2];
char gS_SkinType_Fullbright[2];

// client prefered color
colors_t gA_ColorsTable[MAX_COLORS];
colors_t gA_PreferedColor[MAXPLAYERS+1];

// skin prefs
model_t gI_ModelIndex;
skin_t gH_Skin;
skincolor_t gI_SkinColor[MAXPLAYERS+1];

Handle gH_Timer_handle[MAXPLAYERS];
Handle gH_Delay_handle[MAXPLAYERS];
Handle gH_Ammo[MAXPLAYERS+1];
Handle gH_SyncHud[MAXPLAYERS+1];

// cookies
Handle gH_FlashTypeCookie = null;
Handle gH_FlashColorCookie = null;

// forwards
Handle gH_Forwards_OnPartner = null;
Handle gH_Forwards_OnBreakPartner = null;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Trikz_FindPartner", Native_FindPartner);
	CreateNative("Trikz_GetClientColorR", Native_GetClientColorR);
	CreateNative("Trikz_GetClientColorG", Native_GetClientColorG);
	CreateNative("Trikz_GetClientColorB", Native_GetClientColorB);
	CreateNative("Trikz_GetClientNoclip", Native_GetClientNoclip);
	CreateNative("Trikz_LoadCP", Native_LoadCP);
	gB_Late = late;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	char sCheckpoint[][] = {"sm_checkpoints", "sm_checkpoint", "sm_cpmenu", "sm_cp"};
	char sBlock[][] = {"sm_bl", "sm_block", "sm_ghost", "sm_switch"};
	char sPartner[][] = {"sm_p", "sm_partner", "sm_mate"};
	char sUnPartner[][] = {"sm_unp", "sm_unpartner", "sm_nomate"};
	char sTeleport[][] = {"sm_teleportto", "sm_teleport", "sm_tpto", "sm_tp"};
	char sWeaponmenu[][] = {"sm_equipment", "sm_e", "sm_weapon", "sm_weapons"};
	char sWeapon[][] = {"sm_knife", "sm_glock", "sm_usp", "sm_flashbangs", "sm_flashbang", "sm_scout"};

	for(int i = 0; i < sizeof(sCheckpoint); i++)
	{
		RegConsoleCmd(sCheckpoint[i], Command_Checkpoint, "Checkpoints menu");
	}

	for(int i = 0; i < sizeof(sBlock); i++)
	{
		RegConsoleCmd(sBlock[i], Command_Block, "Toggle blocking");
	}

	for(int i = 0; i < sizeof(sPartner); i++)
	{
		RegConsoleCmd(sPartner[i], Command_Partner, "Select your partner.");
	}
	
	for(int i = 0; i < sizeof(sUnPartner); i++)
	{
		RegConsoleCmd(sUnPartner[i], Command_UnPartner, "Disable your partnership.");
	}

	for(int i = 0; i < sizeof(sTeleport); i++)
	{
		RegConsoleCmd(sTeleport[i], Command_Teleport, "Teleport menu");
	}

	for(int i = 0; i < sizeof(sWeaponmenu); i++)
	{
		RegConsoleCmd(sWeaponmenu[i], Command_Weaponmenu, "Equipment menu");
	}

	for(int i = 0; i < sizeof(sWeapon); i++)
	{
		RegConsoleCmd(sWeapon[i], Command_Weapon, "Spawn weapon");
	}

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);

	RegConsoleCmd("sm_ac", Command_AngleStats);
	RegConsoleCmd("sm_ammo", Command_Ammo);
	RegConsoleCmd("sm_autoswitch", Command_AutoSwitch, "Auto switch flashbang.");
	RegConsoleCmd("sm_as", Command_AutoSwitch, "Auto switch flashbang. Alias of sm_autoswitch.");
	RegConsoleCmd("sm_autoflash", Command_AutoFlash, "Auto give flashbang.");
	RegConsoleCmd("sm_af", Command_AutoFlash, "Auto give flashbang. Alias of sm_autoflash");
	RegConsoleCmd("sm_button", Command_Button);
	RegConsoleCmd("sm_hurt", Command_Hurt);
	RegConsoleCmd("sm_flash", Command_Flash, "Give flash.");
	RegConsoleCmd("sm_fl", Command_Flash, "Give flash. Alias of sm_flash");
	RegConsoleCmd("sm_fb", Command_Flash, "Give flash. Alias of sm_flash");
	RegConsoleCmd("sm_fs", Command_Flash, "Give flash. Alias of sm_flash");
	RegConsoleCmd("sm_inbox", Command_Inbox);
	RegConsoleCmd("sm_nc", Command_NoClip, "Toggle noclip");
	RegConsoleCmd("sm_ping", Command_Ping, "pings a position");
	RegConsoleCmd("sm_rate", Command_Rate, "Check rate.");
	RegConsoleCmd("sm_rates", Command_Rate, "Check rate. Alias of sm_rate");
	RegConsoleCmd("sm_skin", Command_SkinMenu);
	RegConsoleCmd("sm_skinrgb", Command_SkinRGB);
	RegConsoleCmd("sm_gsc", Command_GetSkinColor);
	RegConsoleCmd("sm_getskincolor", Command_GetSkinColor);
	RegConsoleCmd("sm_ems", Command_ExamineMySelf);
	RegConsoleCmd("sm_examinemyself", Command_ExamineMySelf);
	RegConsoleCmd("sm_vm", Command_VM);
	
	HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEventEx("player_death", Player_Death, EventHookMode_Pre);
	HookEventEx("player_spawn", Player_Spawn, EventHookMode_Pre);
	HookEventEx("weapon_fire", Weapon_Fire, EventHookMode_Pre);

	AddNormalSoundHook(NSH_hurt);

	RegConsoleCmd("say", Server_Say);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_SayTeam, "say_team");

	HookEntityOutput("func_button", "OnPressed", UseButton);
	HookEntityOutput("func_button", "OnDamaged", OnButtonDamaged);

	AddTempEntHook("Blood Sprite", TE_OnWorldDecal);
	AddTempEntHook("Entity Decal", TE_OnWorldDecal);
	AddTempEntHook("World Decal", TE_OnWorldDecal);
	AddTempEntHook("Impact", TE_OnWorldDecal);
	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);

	SetConVarFlags(FindConVar("sm_nextmap"), GetConVarFlags(FindConVar("mp_roundtime")) &~ FCVAR_NOTIFY);
	SetConVarBounds(FindConVar("mp_roundtime"), ConVarBound_Lower, true, 0.0);

	gH_FlashTypeCookie = RegClientCookie("flashbang_type", "flashbang type cookie", CookieAccess_Protected);
	gH_FlashColorCookie = RegClientCookie("flashbang_color", "flashbang color cookie", CookieAccess_Protected);
	gH_Skin.iType = RegClientCookie("skin_type", "skin type cookie", CookieAccess_Protected);
	gH_Skin.iRGB = RegClientCookie("skin_color_rgb", "skin color rgb cookie", CookieAccess_Protected);

	IntToString(Type_Default, gS_SkinType_Default, 2);
	IntToString(Type_Lightmap, gS_SkinType_Lightmap, 2);
	IntToString(Type_Fullbright, gS_SkinType_Fullbright, 2);

	LoadColors();
	LoadDhooks();

	// forwards
	gH_Forwards_OnPartner = CreateGlobalForward("Trikz_OnPartner", ET_Event, Param_Cell, Param_Cell);
	gH_Forwards_OnBreakPartner = CreateGlobalForward("Trikz_OnBreakPartner", ET_Event, Param_Cell, Param_Cell);
	
	if(gB_Late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

void LoadColors()
{
	// White 0
	gA_ColorsTable[0].iId = 0;
	Format(gA_ColorsTable[0].sColorName, 8, "%s", "white");
	gA_ColorsTable[0].iRed = 255;
	gA_ColorsTable[0].iGreen = 255;
	gA_ColorsTable[0].iBlue = 255;

	// Red 1
	gA_ColorsTable[1].iId = 1;
	Format(gA_ColorsTable[1].sColorName, 8, "%s", "red");
	gA_ColorsTable[1].iRed = 245;
	gA_ColorsTable[1].iGreen = 22;
	gA_ColorsTable[1].iBlue = 22;

	// Green 2
	gA_ColorsTable[2].iId = 2;
	Format(gA_ColorsTable[2].sColorName, 8, "%s", "green");
	gA_ColorsTable[2].iRed = 48;
	gA_ColorsTable[2].iGreen = 245;
	gA_ColorsTable[2].iBlue = 22;

	// Blue 3
	gA_ColorsTable[3].iId = 3;
	Format(gA_ColorsTable[3].sColorName, 8, "%s", "blue");
	gA_ColorsTable[3].iRed = 0;
	gA_ColorsTable[3].iGreen = 40;
	gA_ColorsTable[3].iBlue = 255;

	// Yellow 4
	gA_ColorsTable[4].iId = 4;
	Format(gA_ColorsTable[4].sColorName, 8, "%s", "yellow");
	gA_ColorsTable[4].iRed = 240;
	gA_ColorsTable[4].iGreen = 255;
	gA_ColorsTable[4].iBlue = 40;

	// Orange 5
	gA_ColorsTable[5].iId = 5;
	Format(gA_ColorsTable[5].sColorName, 8, "%s", "orange");
	gA_ColorsTable[5].iRed = 245;
	gA_ColorsTable[5].iGreen = 152;
	gA_ColorsTable[5].iBlue = 22;

	// Pink 6
	gA_ColorsTable[6].iId = 6;
	Format(gA_ColorsTable[6].sColorName, 8, "%s", "pink");
	gA_ColorsTable[6].iRed = 245;
	gA_ColorsTable[6].iGreen = 22;
	gA_ColorsTable[6].iBlue = 180;
}

void LoadDhooks()
{
	Handle hGamedata = LoadGameConfigFile("fbdetonate.games");
	if(!hGamedata)
	{
		SetFailState("Failed to load fbtools.games!");
		delete hGamedata;
	}

	Handle hFunctions = DHookCreateFromConf(hGamedata, "CFlashbangProjectile__Detonate");
	if(!hFunctions)
	{
		delete hGamedata;
		delete hFunctions;
		SetFailState("Failed to setup detour for FlashbangProjectile__Detonate");
	}

	if(!DHookEnableDetour(hFunctions, false, OnFlashDetonate))
	{
		delete hGamedata;
		delete hFunctions;
		SetFailState("Failed to detour CFlashbangProjectile__Detonate.");
	}

	delete hGamedata;
	delete hFunctions;
}

public MRESReturn OnFlashDetonate(int pThis, Handle hReturn)
{
	if(IsValidEntity(pThis))
	{
		AcceptEntityInput(pThis, "Kill");
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public void OnMapStart()
{
	PrecacheFlashbang();
	PrecachePing();
	PrecacheSkin();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if(AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}

	if(IsValidClient(client))
	{
		for(int i = 0; i < 2; i++)
		{
			gB_Restore[client][i] = false;
		}
		
		for(int i = 0; i < 3; i++)
		{
			gB_Checkpoint[client][i] = false;
		}

		gB_Noclip[client] = false;
		gB_Viewmodel[client] = true;

		gH_SyncHud[client] = CreateHudSynchronizer();

		SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
		SDKHook(client, SDKHook_SpawnPost, SpawnPostClient);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	
	gI_Button[client] = 6;
	gI_SpectatorTarget[client] = -1;
	gI_AngleStats[client] = 0;
	gB_Ammo[client] = true;
	gB_AmmoCheck[client] = true;
	gB_AutoSwitch[client] = true;
	gB_AutoFlash[client] = true;
	gB_FlashThrown[client] = false;
	gB_Hurt[client] = false;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client) || !IsClientInGame(client))
	{
		return;
	}
	
	// flashbang prefs
	char sCookie[4];
	GetClientCookie(client, gH_FlashTypeCookie, sCookie, 4);

	if(strlen(sCookie) == 0)
	{
		SetClientCookie(client, gH_FlashTypeCookie, "0");
		gI_PreferedType[client] = 0;
		FormatEx(gS_PreferedTypeString[client], 10, "%s", "default");
	}

	else
	{
		int type = StringToInt(sCookie, 10);
		gI_PreferedType[client] = type;
		SetPrefTypeString(client, type);
	}

	GetClientCookie(client, gH_FlashColorCookie, sCookie, 4);
	
	if(strlen(sCookie) == 0)
	{
		SetClientCookie(client, gH_FlashColorCookie, "0");
		gA_PreferedColor[client] = gA_ColorsTable[0];
	}

	else
	{
		int color = StringToInt(sCookie, 10);
		SetClientCookie(client, gH_FlashColorCookie, sCookie);
		SetPrefColor(client, color);
	}

	// skin prefs
	char sSkinType[2];
	GetClientCookie(client, gH_Skin.iType, sSkinType, 2);

	if(StrEqual(sSkinType, gS_SkinType_Default) || (strlen(sSkinType) == 0))
	{
		gI_Skin[client] = Type_Default;
	}

	if(StrEqual(sSkinType, gS_SkinType_Lightmap))
	{
		gI_Skin[client] = Type_Lightmap;
	}

	if(StrEqual(sSkinType, gS_SkinType_Fullbright))
	{
		gI_Skin[client] = Type_Fullbright;
	}

	char sSkinColor[12];
	GetClientCookie(client, gH_Skin.iRGB, sSkinColor, 12);

	if(strlen(sSkinColor) == 0)
	{
		SetClientCookie(client, gH_Skin.iRGB, "255;255;255");
		gI_SkinColor[client].iRED = 255;
		gI_SkinColor[client].iGREEN = 255;
		gI_SkinColor[client].iBLUE = 255;
	}
	
	else
	{
		char sExploded[4][3];
		ExplodeString(sSkinColor, ";", sExploded, 3, 4);
		gI_SkinColor[client].iRED = StringToInt(sExploded[0]);
		gI_SkinColor[client].iGREEN = StringToInt(sExploded[1]);
		gI_SkinColor[client].iBLUE = StringToInt(sExploded[2]);
	}
}

public void OnClientDisconnect(int client)
{
	if(!IsClientInGame(client))
	{
		return;
	}

	if(IsClientInGame(client) || !IsFakeClient(client))
	{
		int iPartner = gI_Partner[client];
		
		if(iPartner != -1)
		{
			Call_StartForward(gH_Forwards_OnBreakPartner);
			Call_PushCell(client);
			Call_PushCell(iPartner);
			Call_Finish();
			
			if(Shavit_GetTimerStatus(client) == Timer_Running)
			{
				Shavit_StopTimer(iPartner);
				
				Shavit_PrintToChat(client, "Timer has been stopped while disconnecting.");
				Shavit_PrintToChat(iPartner, "Timer has been stopped while your partner disconnecting.");
			}
			
			gI_Partner[gI_Partner[client]] = -1;
			gI_Partner[client] = -1;
		}
	}

	if(!gB_AmmoCheck[client])
	{
		delete gH_Ammo[client];
	}

	int entity = -1;
	
	while((entity = FindEntityByClassname(entity, "weapon_*")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		{
			RequestFrame(RemoveWeapon, EntIndexToEntRef(entity));
		}
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		gB_Request[i][client] = false;
	}
}

public void OnEntityCreated(int entity, const char[] classname) 
{
	if(IsValidEntity(entity))
	{
		if(StrContains(classname, "_projectile") != -1) 
		{
			SDKHook(entity, SDKHook_Spawn, OnProjectileSpawned);
			SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned_Post);
		}
	}
}

public Action OnWeaponDrop(int client, int entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public void OnWeaponEquip(int client)
{
	int Slot1 = GetPlayerWeaponSlot(client, 0);
	int Slot2 = GetPlayerWeaponSlot(client, 1);
	
	if(IsPlayerAlive(client) && gB_Ammo[client])
	{
		if(IsValidEntity(Slot1))
		{
			if(GetEntProp(Slot1, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot1, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot1, FindDataMapInfo(client, "m_iClip1"));
			}
		}
		
		if(IsValidEntity(Slot2))
		{
			if(GetEntProp(Slot2, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot2, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot2, FindDataMapInfo(client, "m_iClip1"));
			}
		}
		
		RequestFrame(doublecheck, client);
	}
}

public void SpawnPostClient(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client))
	{
		return;
	}
	
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
	SetEntityRenderMode(client, RENDER_NORMAL);
	
	if(GetEntData(client, (FindDataMapInfo(client, "m_iAmmo") + (12 * 4))) == 0)
	{
		GivePlayerItem(client, "weapon_flashbang");
		SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + 12 * 4, 2);
	}
	
	if(GetEntData(client, (FindDataMapInfo(client, "m_iAmmo") + (12 * 4))) == 1)
	{
		SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + 12 * 4, 2);
	}
}

public Action OnTakeDamage(int victim, int &attacker)
{
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
	
	return Plugin_Handled;
}

public Action OnProjectileSpawned(int entity)
{	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(!IsValidClient(client) || !IsValidEntity(entity))
	{
		return;
	}
	
	float iAngles[3];
	GetClientEyeAngles(client, iAngles);
	
	int iAngle = RoundFloat(iAngles[0] * -1);
	
	char sStatus[64];
	
	//Thanks to https://forums.alliedmods.net/showpost.php?p=1856915&postcount=2
	//Thanks to https://www.unknowncheats.me/forum/1900520-post1.html
	//For angles measure thanks to "Trikzbb"
	
	if(-27 < iAngle < 7)
	{
		sStatus = "Low Megalong";
	}
	
	else if(6 < iAngle < 26)
	{
		sStatus = "Megalong"; }
	
	else if(25 < iAngle < 41)
	{
		sStatus = "Medium high Megalong";
	}
	
	else if(40 < iAngle < 66)
	{
		sStatus = "High Megalong";
	}
	
	else if(65 < iAngle < 76)
	{
		sStatus = "Low fast Megahigh";
	}
	
	else if(75 < iAngle < 86)
	{
		sStatus = "Medium fast Megahigh";
	}
	
	else if(85 < iAngle < 90)
	{
		sStatus = "Megahigh";
	}
	
	if(-27 < iAngle < 90)
	{
		int iPartner = Trikz_FindPartner(client);
		
		if(gI_AngleStats[client] == 1 || gI_AngleStats[client] == 3)
		{
			CPrintToChat(client, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s", iAngle, sStatus);
			
			if(iPartner != -1)
			{
				if(gI_AngleStats[iPartner] == 1 || gI_AngleStats[iPartner] == 3)
				{
					CPrintToChat(iPartner, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s {dimgray}| {orange}%N", iAngle, sStatus, client);
				}
			}
		}
		
		if(iPartner == -1)
		{
			SpectatorCheck(client);
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gI_AngleStats[i] == 1 || gI_AngleStats[i] == 3))
				{
					if(gI_SpectatorTarget[i] == client)
					{
						CPrintToChat(i, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s", iAngle, sStatus);
					}
				}
			}
		}
		
		else
		{
			SpectatorCheck(iPartner);
			
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gI_AngleStats[i] == 1 || gI_AngleStats[i] == 3))
				{
					if(gI_SpectatorTarget[i] == client || gI_SpectatorTarget[i] == iPartner)
					{
						CPrintToChat(i, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s {dimgray}| {orange}%N", iAngle, sStatus, client);
					}
				}
			}
		}
	}
	
	// switch flashbang stuff
	if(gB_AutoFlash[client])
	{
		SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + 12 * 4, 2);
	}
	
	if(!gB_AutoSwitch[client])
	{
		return;
	}
	
	gB_FlashThrown[client] = true;
	
	float iTime = GetGameTime();
	gF_LastThrowTime[client] = iTime;
	
	int iWeapon = GetPlayerWeaponSlot(client, 1);
	int iTeam = GetClientTeam(client);
	
	if(iWeapon == -1 && iTeam == CS_TEAM_T)
	{
		GivePlayerItem(client, "weapon_glock");
		iWeapon = GetPlayerWeaponSlot(client, 1);
	}
	
	if(iWeapon == -1 && iTeam == CS_TEAM_CT)
	{
		GivePlayerItem(client, "weapon_usp");
		iWeapon = GetPlayerWeaponSlot(client, 1);
	}
	
	char sWeapon[17];
	GetEntityClassname(iWeapon, sWeapon, sizeof(sWeapon));
	FakeClientCommand(client, "use %s", sWeapon);
	
	//Hide sWeapon model
	iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 0.0);
	 
	int iViewModel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	
	if(iViewModel != INVALID_ENT_REFERENCE) 
	{
		SetEntPropFloat(iViewModel, Prop_Send, "m_flPlaybackRate", 0.0);
	}
	
	SetEntPropFloat(iWeapon, Prop_Send, "m_flTimeWeaponIdle", 20.0);
	
	//Make nade visible
	ClientCommand(client, "lastinv");
}

public void OnProjectileSpawned_Post(int edict)
{
	if(IsValidEdict(edict))
	{
		int owner = GetEntPropEnt(edict, Prop_Data, "m_hOwnerEntity");
		
		if(IsModelPrecached(FLASHBANG_W) && gI_PreferedType[owner] != 0)
		{
			char sType[2];
			IntToString(gI_PreferedType[owner], sType, 2);

			//SetEntityModel(edict, FLASHBANG_W); 
			SetEntProp(edict, Prop_Send, "m_nModelIndex", gI_FlashModelIndex);
			DispatchKeyValue(edict, "skin", sType);
			SetEntityRenderColor(edict, gA_PreferedColor[owner].iRed, gA_PreferedColor[owner].iGreen, gA_PreferedColor[owner].iBlue, 255);
		}
	}
}

public Action Command_Checkpoint(int client, int args)
{	
	Menu menu = new Menu(H_CheckpointPanel);
	menu.SetTitle("Checkpoints menu\n ");
	menu.AddItem("save1", "Save checkpoint 1");
	menu.AddItem("load1", "Load checkpoint 1\n ", gB_Checkpoint[client][0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("save2", "Save checkpoint 2");
	menu.AddItem("load2", "Load checkpoint 2\n ", gB_Checkpoint[client][1] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	menu.AddItem("loadautocp", "Load auto-cp");
	menu.AddItem("newcp", "New CP Menu\n ");

	char sDisplay[64];

	FormatEx(sDisplay, sizeof(sDisplay), "Restore angles [%s]", gB_Restore[client][0] ? "ON" : "OFF");
	menu.AddItem("restoreang", sDisplay);

	FormatEx(sDisplay, sizeof(sDisplay), "Restore velocity [%s]\n ", gB_Restore[client][1] ? "ON" : "OFF");
	menu.AddItem("restorevel", sDisplay);

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int H_CheckpointPanel(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			menu.GetItem(param2, sItem, sizeof(sItem));
			
			if(StrEqual(sItem, "save1"))
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				SaveCP(param1, 1);
			}
			
			if(StrEqual(sItem, "load1"))
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				if(Shavit_GetTimerStatus(param1) == Timer_Running)
				{
					OpenStopWarningMenu(param1);
					
					return view_as<int>(Plugin_Continue);
				}
				
				else
				{
					LoadCP(param1, 1);
				}
			}
			
			if(StrEqual(sItem, "save2"))
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				SaveCP(param1, 2);
			}
			
			if(StrEqual(sItem, "load2"))
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				if(Shavit_GetTimerStatus(param1) == Timer_Running)
				{
					OpenStopWarningMenu(param1);
					
					return view_as<int>(Plugin_Continue);
				}
				
				else
				{
					LoadCP(param1, 2);
				}
			}
			
			if(StrEqual(sItem, "loadautocp"))
			{
				if(!IsPlayerAlive(param1))
				{
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				if(Shavit_GetTimerStatus(param1) == Timer_Running)
				{
					OpenStopWarningMenu(param1);
					
					return view_as<int>(Plugin_Continue);
				}
				
				else
				{
					bool b[2];
					b[0] = gB_Restore[param1][0];
					b[1] = gB_Restore[param1][1];
					float origin[3];
					origin = gF_autocheckpoint[param1][0];
					float angles[3];
					angles = gF_autocheckpoint[param1][1];
					float velocity[3];
					velocity = gF_autocheckpoint[param1][2];
					
					if(gB_Checkpoint[param1][2])
					{
						if(b[0] && b[1])
						{
							TeleportEntity(param1, origin, angles, velocity);
						}
						
						if(!b[0] && b[1])
						{		
							TeleportEntity(param1, origin, NULL_VECTOR, velocity);
						}
						
						if(b[0] && !b[1])
						{		
							TeleportEntity(param1, origin, angles, view_as<float>({0.0, 0.0, 0.0}));
						}
						
						if(!b[0] && !b[1])
						{	
							TeleportEntity(param1, origin, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
						}
					}
					
					else
					{
						CPrintToChat(param1, "{white}You must get nade boost to use this feature!");
					}
				}
			}

			if(StrEqual(sItem, "newcp"))
			{
				FakeClientCommand(param1, "sm_newcp");
				return 0;
			}
			
			if(StrEqual(sItem, "restoreang"))
			{
				gB_Restore[param1][0] = !gB_Restore[param1][0];
			}
			
			if(StrEqual(sItem, "restorevel"))
			{
				gB_Restore[param1][1] = !gB_Restore[param1][1];
			}
			
			Command_Checkpoint(param1, 1);
		}
		
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					FakeClientCommand(param1, "sm_trikz");
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return view_as<int>(Plugin_Continue);
}

public Action Command_Block(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		
		return Plugin_Handled;
	}
	
	if(Shavit_GetClientTrack(client) != Track_Solobonus)
	{
		if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 5)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
			SetEntityRenderMode(client, RENDER_TRANSALPHA);
			//SetEntityRenderColor(client, 255, 255, 255, 75);
			SetEntityRenderColor(client, Trikz_GetClientColorR(client), Trikz_GetClientColorG(client), Trikz_GetClientColorB(client), 100);
			CPrintToChat(client, "{red}已切换：虚体.");
			
			return Plugin_Handled;
		}

		else if(GetEntProp(client, Prop_Data, "m_CollisionGroup") == 2)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
			SetEntityRenderMode(client, RENDER_NORMAL);
			CPrintToChat(client, "{green}已切换：实体.");
			
			return Plugin_Handled;
		}
	}
	
	else
	{
		CPrintToChat(client, "{dimgray}[{white}TIMER{dimgray}] {white}Block cannot be toggled in solobonus track. Type {orange}/r {white}or {orange}/b {white}or {orange}/end {white}or {orange}/bend {white}to change the track.");
	}
	
	return Plugin_Handled;
}

public Action Command_Partner(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		
		return Plugin_Handled;
	}
	
	if(gI_Partner[client] != -1)
	{
		CPrintToChat(client, "{white}You already have a partner.");
		
		return Plugin_Handled;
	}
	
	PartnerMenu(client);
	
	return Plugin_Handled;
}

public Action Command_UnPartner(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(gI_Partner[client] == -1)
	{
		CPrintToChat(client, "{white}You need a partner to cancel your partnership with the current one.");
		
		return Plugin_Handled;
	}
	
	UnPartnerMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(H_TeleportMenu);
	menu.SetTitle("Teleport menu\n ");
	menu.AddItem("aim_tp", "Aim teleport");
	
	bool bOnceCircle = false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}
		
		if(!bOnceCircle && i != client && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			menu.AddItem("inbox", "Your inbox\n \nActive player list:\n ");
			bOnceCircle = true;
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!bOnceCircle && i == client && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			menu.AddItem("inbox", "Your inbox\n ");
			bOnceCircle = true;
		}
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		char sInfo[64];
		FormatEx(sInfo, sizeof(sInfo), "%i", GetClientUserId(i));
		char sDisplay[64];
		GetClientName(i, sDisplay, sizeof(sDisplay));
		menu.AddItem(sInfo, sDisplay);
	}
	
	if(menu.ItemCount == 0)
	{
		FakeClientCommand(client, "sm_trikz");
		CPrintToChat(client, "{white}No alive players that you could teleport to!");
		
		return Plugin_Handled;
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int H_TeleportMenu(Menu oldmenu, MenuAction action, int param1, int param2)
{
	if(!param1 || !IsValidClient(param1))
	{
		return view_as<int>(Plugin_Handled);
	}
	
	switch(action)
	{
		case MenuAction_Select:
		{
			char sItem[64];
			oldmenu.GetItem(param2, sItem, sizeof(sItem));
			
			if(StrEqual(sItem, "inbox"))
			{
				if(!IsPlayerAlive(param1))
				{
					FakeClientCommand(param1, "sm_t");
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				else
				{
					inbox(param1);
				}
				
				return view_as<int>(Plugin_Continue);
			}
			
			if(StrEqual(sItem, "aim_tp"))
			{
				if(!IsPlayerAlive(param1))
				{
					FakeClientCommand(param1, "sm_t");
					CPrintToChat(param1, "{white}You must be alive to use this feature!");
				}
				
				else
				{
					TeleportClient(param1);
					Command_Teleport(param1, 0);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					FakeClientCommand(param1, "sm_trikz");
				}
			}
		}
	}
	
	char sInfo[32];
	
	if(!GetMenuItem(oldmenu, param2, sInfo, sizeof(sInfo)))
	{
		return view_as<int>(Plugin_Handled);
	}
	
	if(!IsPlayerAlive(param1))
	{
		CPrintToChat(param1, "{white}You must be alive to use this feature!");
		
		return view_as<int>(Plugin_Handled);
	}
	
	int reciever = GetClientOfUserId(StringToInt(sInfo));
	
	if(!reciever)
	{
		return view_as<int>(Plugin_Handled);
	}
	
	gB_Request[reciever][param1] = true;
	CPrintToChat(reciever, "{orange}%N {white}wants to teleport to you.", param1);
	
	return view_as<int>(Plugin_Continue);
}

public int H_TeleportMenu_Confirm(Menu menu, MenuAction action, int param1, int param2)
{
	if(!param1 || !IsValidClient(param1))
	{
		return;
	}
	
	char sInfo[32];
	
	if(!GetMenuItem(menu, param2, sInfo, sizeof(sInfo)))
	{
		return;
	}
	
	int sender = GetClientOfUserId(StringToInt(sInfo));
	GetClientName(sender, sInfo, sizeof(sInfo));
	
	if(!sender || IsFakeClient(param1))
	{
		return;
	}
	
	gB_Request[param1][sender] = false;
	
	char sDisplay[64];
	GetClientName(param1, sDisplay, sizeof(sDisplay));
	
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
				{					
					Shavit_StopTimer(sender);
					
					if(Trikz_FindPartner(sender) != -1)
					{
						if(Shavit_GetClientTrack(Trikz_FindPartner(sender)) != Track_Solobonus)
						{
							Shavit_StopTimer(Trikz_FindPartner(sender));
						}
					}
					
					if(Shavit_GetClientTrack(param1) != Track_Solobonus)
					{
						if(GetEntProp(param1, Prop_Data, "m_CollisionGroup") == 5)
						{
							SetEntProp(param1, Prop_Data, "m_CollisionGroup", 2);
							SetEntityRenderMode(param1, RENDER_TRANSALPHA);
							SetEntityRenderColor(param1, Trikz_GetClientColorR(param1), Trikz_GetClientColorG(param1), Trikz_GetClientColorB(param1), 100);
							CreateTimer(2.0, EnableBlockAfterTpto, param1);
						}
					}
					
					if(Shavit_GetClientTrack(sender) != Track_Solobonus)
					{
						if(GetEntProp(sender, Prop_Data, "m_CollisionGroup") == 5)
						{
							SetEntProp(sender, Prop_Data, "m_CollisionGroup", 2);
							SetEntityRenderMode(sender, RENDER_TRANSALPHA);
							SetEntityRenderColor(sender, Trikz_GetClientColorR(sender), Trikz_GetClientColorG(sender), Trikz_GetClientColorB(sender), 100);
							CreateTimer(2.0, EnableBlockAfterTpto, sender);
						}
					}
					
					float origin[3];
					GetEntPropVector(param1, Prop_Send, "m_vecOrigin", origin);
					TeleportEntity(sender, origin, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
					
					CPrintToChat(sender, "{white}You teleported to {orange}%s{white}.", sDisplay);
					CPrintToChat(param1, "{orange}%s{white} teleported to you.", sInfo);
				}
				
				case 1:
				{
					CPrintToChat(sender, "{white}Your teleportation request to {orange}%s {white}is declined.", sDisplay);
					CPrintToChat(param1, "{white}You have denied a teleportation request from {orange}%s{white}.", sInfo);
				}
			}
		}
	}
}

public Action Command_Weaponmenu(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		return Plugin_Handled;
	}

	Weaponmenu(client);

	return Plugin_Handled;
}

public Action Command_Weapon(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		return Plugin_Handled;
	}

	else
	{
		int Time = GetTime();
		int iWeapon;
		char sCommand[16];
		char sWeapon[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		GetClientWeapon(client, sWeapon, sizeof(sWeapon));
		if(StrContains(sCommand, "flashbang") != -1)
		{
			if(StrContains(sWeapon, "flashbang") == -1)
			{
				if(Time - gI_Cooldown[client] <= 5)
				{
					CPrintToChat(client, "{white}You can't do that now. Try again in a few seconds.");
					return Plugin_Handled;
				}
				gI_Cooldown[client] = Time;

				iWeapon = GetPlayerWeaponSlot(client, 3);
				if(iWeapon != -1)
				{
					RemovePlayerItem(client, iWeapon);
				}
				iWeapon = GivePlayerItem(client, "weapon_flashbang");
				SetEntData(client, FindDataMapInfo(client, "m_iAmmo") + 12 * 4, 2);
				FakeClientCommand(client, "use weapon_flashbang");
				CPrintToChat(client, "{white}Successfully obtained a flashbangs.");
			}

			else
			{
				CPrintToChat(client, "{white}You already have a flashbangs.");
			}
		}
		if(StrContains(sCommand, "usp") != -1)
		{
			if(StrContains(sWeapon, "usp") == -1)
			{
				if(Time - gI_Cooldown[client] <= 5)
				{
					CPrintToChat(client, "{white}You can't do that now. Try again in a few seconds.");
					return Plugin_Handled;
				}
				gI_Cooldown[client] = Time;

				iWeapon = GetPlayerWeaponSlot(client, 1);
				if(iWeapon != -1)
				{
					RemovePlayerItem(client, iWeapon);
				}
				iWeapon = GivePlayerItem(client, "weapon_usp");
				SetEntProp(iWeapon, Prop_Data, "m_iClip1", 90);
				FakeClientCommand(client, "use weapon_usp");
				CPrintToChat(client, "{white}Successfully obtained a usp.");
			}

			else
			{
				CPrintToChat(client, "{white}You already have a usp.");
			}
		}
		if(StrContains(sCommand, "glock") != -1)
		{
			if(StrContains(sWeapon, "glock") == -1)
			{
				if(Time - gI_Cooldown[client] <= 5)
				{
					CPrintToChat(client, "{white}You can't do that now. Try again in a few seconds.");
					return Plugin_Handled;
				}
				gI_Cooldown[client] = Time;

				iWeapon = GetPlayerWeaponSlot(client, 1);
				if(iWeapon != -1)
				{
					RemovePlayerItem(client, iWeapon);
				}
				iWeapon = GivePlayerItem(client, "weapon_glock");
				SetEntProp(iWeapon, Prop_Data, "m_iClip1", 90);
				FakeClientCommand(client, "use weapon_glock");
				CPrintToChat(client, "{white}Successfully obtained a glock.");
			}

			else
			{
				CPrintToChat(client, "{white}You already have a glock.");
			}
		}
		if(StrContains(sCommand, "scout") != -1)
		{
			if(StrContains(sWeapon, "scout") == -1)
			{
				if(Time - gI_Cooldown[client] <= 5)
				{
					CPrintToChat(client, "{white}You can't do that now. Try again in a few seconds.");
					return Plugin_Handled;
				}
				gI_Cooldown[client] = Time;

				iWeapon = GetPlayerWeaponSlot(client, 0);
				if(iWeapon != -1)
				{
					RemovePlayerItem(client, iWeapon);
				}
				iWeapon = GivePlayerItem(client, "weapon_scout");
				SetEntProp(iWeapon, Prop_Data, "m_iClip1", 90);
				FakeClientCommand(client, "use weapon_scout");
				CPrintToChat(client, "{white}Successfully obtained a scout.");
			}

			else
			{
				CPrintToChat(client, "{white}You already have a scout.");
			}
		}
		if(StrContains(sCommand, "knife") != -1)
		{
			if(StrContains(sWeapon, "knife") == -1)
			{
				if(Time - gI_Cooldown[client] <= 5)
				{
					CPrintToChat(client, "{white}You can't do that now. Try again in a few seconds.");
					return Plugin_Handled;
				}
				gI_Cooldown[client] = Time;

				iWeapon = GetPlayerWeaponSlot(client, 2);
				if(iWeapon != -1)
				{
					RemovePlayerItem(client, iWeapon);
				}
				iWeapon = GivePlayerItem(client, "weapon_knife");
				SetEntProp(iWeapon, Prop_Data, "m_iClip1", 90);
				FakeClientCommand(client, "use weapon_knife");
				CPrintToChat(client, "{white}Successfully obtained a knife.");
			}
			else
			{
				CPrintToChat(client, "{white}You already have a knife.");
			}
		}
	}

	return Plugin_Handled;
}

public Action Command_AngleStats(int client, int args)
{
	if(gI_AngleStats[client] == 0)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Chat.");
		gI_AngleStats[client] = 1;
	}
	
	else if(gI_AngleStats[client] == 1)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Hud.");
		gI_AngleStats[client] = 2;
	}
	
	else if(gI_AngleStats[client] == 2)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Both.");
		gI_AngleStats[client] = 3;
	}
	
	else if(gI_AngleStats[client] == 3)
	{
		CPrintToChat(client, "{white}Angles check is off.");
		gI_AngleStats[client] = 0;
	}
	
	return Plugin_Handled;
}

public Action Command_Ammo(int client, int args)
{
	gB_Ammo[client] = !gB_Ammo[client];
	
	if(gB_Ammo[client])
	{
		CPrintToChat(client, "{white}Infinite ammonition is on.");
	}
	
	else
	{
		CPrintToChat(client, "{white}Infinite ammonition is off.");
	}
	
	int Slot1 = GetPlayerWeaponSlot(client, 0);
	int Slot2 = GetPlayerWeaponSlot(client, 1);
	
	if(IsPlayerAlive(client) && gB_Ammo[client])
	{
		if(IsValidEntity(Slot1))
		{
			if(GetEntProp(Slot1, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot1, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot1, FindDataMapInfo(client, "m_iClip1"));
			}
		}
		
		if(IsValidEntity(Slot2))
		{
			if(GetEntProp(Slot2, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot2, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot2, FindDataMapInfo(client, "m_iClip1"));
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_AutoSwitch(int client, int args)
{
	gB_AutoSwitch[client] = !gB_AutoSwitch[client];

	if(gB_AutoSwitch[client])
	{  
		CPrintToChat(client, "{white}Autoswitch is on.");
	}

	else
	{
		CPrintToChat(client, "{white}Autoswitch is off.");
	}

	return Plugin_Handled;
}

public Action Command_AutoFlash(int client, int args)
{
	gB_AutoFlash[client] = !gB_AutoFlash[client];

	if(gB_AutoFlash[client])
	{  
		CPrintToChat(client, "{white}Autoflash is on.");
	}

	else
	{
		CPrintToChat(client, "{white}Autoflash is off.");
	}

	return Plugin_Handled;
}

public Action Command_Button(int client, int args)
{	
	if(gI_Button[client] == 0)
	{
		gI_Button[client] = 1;
		CPrintToChat(client, "{blue}Button announcer is on. Mode: Own chat only.");
	}
	
	else if(gI_Button[client] == 1)
	{
		gI_Button[client] = 2;
		CPrintToChat(client, "{yellow}Button announcer is on. Mode: Own chat only. +Fade");
	}
	
	else if(gI_Button[client] == 2)
	{
		gI_Button[client] = 3;
		CPrintToChat(client, "{blue}Button announcer is on. Mode: Partner chat only.");
	}
	
	else if(gI_Button[client] == 3)
	{
		gI_Button[client] = 4;
		CPrintToChat(client, "{yellow}Button announcer is on. Mode: Partner chat only. +Fade");
	}
	
	else if(gI_Button[client] == 4)
	{
		gI_Button[client] = 5;
		CPrintToChat(client, "{yellow}Button announcer is on. Mode: Only both fades.");
	}
	
	else if(gI_Button[client] == 5)
	{
		gI_Button[client] = 6;
		CPrintToChat(client, "{blue}Button announcer is on. Mode: Only both chats.");
	}
	
	else if(gI_Button[client] == 6)
	{
		gI_Button[client] = 7;
		CPrintToChat(client, "{green}Button announcer is on. Mode: All.");
	}
	
	else if(gI_Button[client] == 7)
	{
		gI_Button[client] = 0;
		CPrintToChat(client, "{red}Button announcer is off.");
	}
	
	return Plugin_Handled;
}

public Action Command_Hurt(int client, int args)
{
	gB_Hurt[client] = !gB_Hurt[client];

	if(gB_Hurt[client])
	{
		CPrintToChat(client, "{white}Hurt sounds is on.");
	}
	
	else
	{
		CPrintToChat(client, "{white}Hurt sounds is off.");
	}
	
	return Plugin_Handled;
}

public Action Command_Flash(int client, int args) 
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}

	OpenFlashMenu(client);

	return Plugin_Handled;
}

public Action Command_Inbox(int client, int args)
{
	inbox(client);

	return Plugin_Handled;
}

public Action Command_NoClip(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!", client);
		
		return Plugin_Handled;
	}
	
	if(Shavit_GetTimerStatus(client) == Timer_Running)
	{
		Menu hMenu = new Menu(MenuHandler_StopWarning_Noclip);
		hMenu.SetTitle("Would you like to stop timer?\n ");

		char sDisplay[32];
		FormatEx(sDisplay, sizeof(sDisplay), "Yes\n ");
		hMenu.AddItem("yes", sDisplay);

		FormatEx(sDisplay, sizeof(sDisplay), "No");
		hMenu.AddItem("no", sDisplay);

		hMenu.ExitButton = false;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
	
	else
	{
		if(GetEntityMoveType(client) == MOVETYPE_WALK)
		{
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			gB_Noclip[client] = true;
			CPrintToChat(client, "{white}%s.", gB_Noclip[client] ? "Noclip is on" : "Noclip is off");
			
			return Plugin_Handled;
		}
		
		if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
			gB_Noclip[client] = false;
			CPrintToChat(client, "{white}%s.", gB_Noclip[client] ? "Noclip is on" : "Noclip is off");
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Handled;
}

public int MenuHandler_StopWarning_Noclip(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[8];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		if(StrEqual(sInfo, "yes"))
		{
			Shavit_StopTimer(param1);
			FakeClientCommand(param1, "sm_trikz");
			
			int iPartner = Trikz_FindPartner(param1);
			
			if(iPartner != -1)
			{
				Shavit_StopTimer(iPartner);
			}
			
			if(GetEntityMoveType(param1) == MOVETYPE_WALK)
			{
				SetEntityMoveType(param1, MOVETYPE_NOCLIP);
				gB_Noclip[param1] = true;
				CPrintToChat(param1, "{white}%s.", gB_Noclip[param1] ? "Noclip is on" : "Noclip is off");
				
				return view_as<int>(Plugin_Handled);
			}
			
			if(GetEntityMoveType(param1) == MOVETYPE_NOCLIP)
			{
				SetEntityMoveType(param1, MOVETYPE_WALK);
				gB_Noclip[param1] = false;
				CPrintToChat(param1, "{white}%s.", gB_Noclip[param1] ? "Noclip is on" : "Noclip is off");
				
				return view_as<int>(Plugin_Handled);
			}
		}
		
		else if(StrEqual(sInfo, "no"))
		{
			FakeClientCommand(param1, "sm_trikz");
		}
	}

	return view_as<int>(Plugin_Continue);
}

public Action Command_Ping(int client, int args)
{
	PING(client);
	
	return Plugin_Handled;
}

public Action Command_Rate(int client, int args)
{
	if(args == 1)
	{
		char arg[MAX_NAME_LENGTH + 9]; 
		GetCmdArgString(arg, sizeof(arg));
		int target = FindTarget(client, arg, true, false);
	
		if(IsValidClient(target))
		{
			PrintRateMenu(target, client);
		}
	}
	
	else
	{
		char szInfo[66];
		char szDisplay[MAX_NAME_LENGTH];

		Menu menu = new Menu(Handler_RateMenu);
		menu.SetTitle("Networking for:\n ");
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				Format(szInfo, sizeof(szInfo), "%i", GetClientUserId(i));
				GetClientName(i, szDisplay, sizeof(szDisplay));
				menu.AddItem(szInfo, szDisplay);
			}
		}
		
		menu.ExitBackButton = true;
		menu.ExitButton = true;
		
		if(menu.ItemCount != 0)
		{
			menu.Display(client, MENU_TIME_FOREVER);
		}
		
		else
		{
			CPrintToChat(client, "{white}No players to check rates.");
		}
	}
	
	return Plugin_Handled;
}

public Action Command_SkinMenu(int client, int args)
{
	SkinMenu(client);

	return Plugin_Handled;
}

public Action Command_SkinRGB(int client, int args)
{
	char value[15];
	GetCmdArgString(value, sizeof(value));

	char buffer[3][15];
	if(ExplodeString(value, " ", buffer, sizeof(buffer), sizeof(buffer[])) < 3)
	{
		return Plugin_Handled;
	}

	gI_SkinColor[client].iRED = StringToInt(buffer[0]);
	gI_SkinColor[client].iGREEN = StringToInt(buffer[1]);
	gI_SkinColor[client].iBLUE = StringToInt(buffer[2]);

	//Random color
	if(gI_SkinColor[client].iRED == -1 && gI_SkinColor[client].iGREEN == -1 && gI_SkinColor[client].iBLUE == -1)
	{
		gI_SkinColor[client].iRED = GetRandomInt(0, 255);
		gI_SkinColor[client].iGREEN = GetRandomInt(0, 255);
		gI_SkinColor[client].iBLUE = GetRandomInt(0, 255);
		CPrintToChat(client, "{white}Your new color is: {darkred}%i {darkgreen}%i {darkblue}%i", gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE);
	}

	if(gI_SkinColor[client].iRED == -1 && gI_SkinColor[client].iGREEN == -1)
	{
		gI_SkinColor[client].iRED = GetRandomInt(0, 255);
		gI_SkinColor[client].iGREEN = GetRandomInt(0, 255);
		CPrintToChat(client, "{white}Your new color is: {darkred}%i {darkgreen}%i {darkblue}%i", gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE);
	}

	if(gI_SkinColor[client].iRED == -1 && gI_SkinColor[client].iBLUE == -1)
	{
		gI_SkinColor[client].iRED = GetRandomInt(0, 255);
		gI_SkinColor[client].iBLUE = GetRandomInt(0, 255);
		CPrintToChat(client, "{white}Your new color is: {darkred}%i {darkgreen}%i {darkblue}%i", gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE);
	}

	if(gI_SkinColor[client].iGREEN == -1 && gI_SkinColor[client].iBLUE == -1)
	{
		gI_SkinColor[client].iGREEN = GetRandomInt(0, 255);
		gI_SkinColor[client].iBLUE = GetRandomInt(0, 255);
		CPrintToChat(client, "{white}Your new color is: {darkred}%i {darkgreen}%i {darkblue}%i", gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE);
	}
	SetEntityRenderColor(client, gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE, 255);

	char sSkinColor[3][4];
	IntToString(gI_SkinColor[client].iRED, sSkinColor[0], 4);
	IntToString(gI_SkinColor[client].iGREEN, sSkinColor[1], 4);
	IntToString(gI_SkinColor[client].iBLUE, sSkinColor[2], 4);

	char sColorCookie[12];
	FormatEx(sColorCookie, 12, "%s;%s;%s", sSkinColor[0], sSkinColor[1], sSkinColor[2]);
	SetClientCookie(client, gH_Skin.iRGB, sColorCookie);

	Mirror_Trigger(client);

	return Plugin_Handled;
}

public Action Command_GetSkinColor(int client, int args)
{
	if(args == 1)
	{
		char arg[MAX_NAME_LENGTH + 9];
		GetCmdArgString(arg, sizeof(arg));
		int target = FindTarget(client, arg, true, false);
		if(IsClientInGame(target))
		{
			int r, g, b, a;
			GetEntityRenderColor(target, r, g, b, a);
			CPrintToChat(target, "{orange}%N {white}currect skin color is: {darkred}%i {darkgreen}%i {darkblue}%i", target, r, g, b);
		}
	}
	else
	{
		char sInfo[66];
		char sDisplay[MAX_NAME_LENGTH];
		Menu menu = new Menu(Handler_GetSkinColorMenu);
		menu.SetTitle("Get skin color from:\n ");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				Format(sInfo, sizeof(sInfo), "%i", GetClientUserId(i));
				GetClientName(i, sDisplay, sizeof(sDisplay));
				menu.AddItem(sInfo, sDisplay);
			}
		}

		menu.ExitBackButton = true;
		menu.ExitButton = true;

		if(menu.ItemCount != 0)
		{
			menu.Display(client, MENU_TIME_FOREVER);
		}

		else
		{
			CPrintToChat(client, "{white}No players to get his/her skin color.");
		}
	}

	return Plugin_Handled;
}

public int Handler_GetSkinColorMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[MAX_NAME_LENGTH];
			menu.GetItem(param2, item, sizeof(item));
			int client = GetClientOfUserId(StringToInt(item));
			if(IsClientInGame(client))
			{
				int r, g, b, a;
				GetEntityRenderColor(client, r, g, b, a);
				CPrintToChat(param1, "{orange}%N {white}currect skin color is: {darkred}%i {darkgreen}%i {darkblue}%i", client, r, g, b);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public Action Command_ExamineMySelf(int client, int args)
{
	Mirror_Trigger(client);

	return Plugin_Handled;
}

public Action Command_VM(int client, int args)
{
	if(view_as<bool>(GetEntProp(client, Prop_Send, "m_bDrawViewmodel")) == false)
	{
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", true);
		ChangeEdictState(client, FindDataMapInfo(client, "m_bDrawViewmodel"));
		gB_Viewmodel[client] = true;
		CPrintToChat(client, "{white}%s", gB_Viewmodel[client] ? "Viewmodel is on." : "Viewmodel is off.");
		
		return Plugin_Handled;
	}
	
	if(view_as<bool>(GetEntProp(client, Prop_Send, "m_bDrawViewmodel")) == true)
	{
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", false);
		ChangeEdictState(client, FindDataMapInfo(client, "m_bDrawViewmodel"));
		gB_Viewmodel[client] = false;
		CPrintToChat(client, "{white}%s", gB_Viewmodel[client] ? "Viewmodel is on." : "Viewmodel is off.");
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Event_PlayerTeam(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return Plugin_Handled;
	}
	
	int iOldTeam = GetEventInt(hEvent, "oldteam");
	int iintTeam = GetEventInt(hEvent, "team");
	
	SetEventBroadcast(hEvent, true);
	//Counter-Strike
	//2 = Terrorists (Red)
	//3 = Counter-Terrorists (Blue)
	switch(iOldTeam)
	{
		case 0, 1, 2, 3:
		{
			switch(iintTeam)
			{
				case 1: CPrintToChatAll("{orange}%N {white}joined team {gray}Spectators{white}.", client);
				case 2: CPrintToChatAll("{orange}%N {white}joined team {red}Terrorists{white}.", client);
				case 3: CPrintToChatAll("{orange}%N {white}joined team {blue}Counter-Terrorists{white}.", client);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if(!IsValidEdict(ragdoll))
	{
		return Plugin_Continue;
	}
	
	AcceptEntityInput(ragdoll, "Kill");
	
	gB_Noclip[client] = false;

	return Plugin_Continue;
}

public Action Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SkinApply(client);

	return Plugin_Continue;
}

public Action Weapon_Fire(Event event, const char[] name, bool dB)
{	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"); 
	
	if(!IsValidEntity(weapon))
	{
		return Plugin_Handled;
	}
	
	char sWeapon[20];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, "weapon_flashbang") || StrEqual(sWeapon, "weapon_hegrenade") || StrEqual(sWeapon, "weapon_smokegrenade") || StrEqual(sWeapon, "weapon_knife"))
	{
		return Plugin_Handled;
	}
	
	if(gB_AmmoCheck[client])
	{
		gH_Ammo[client] = CreateTimer(6.0, Timer_Ammo, client); //Less server-side load
		
		gB_AmmoCheck[client] = false;
	}

	return Plugin_Continue;
}

public Action NSH_hurt(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags)
{
	if(0 < entity <= MaxClients)
	{
		if(!gB_Hurt[entity])
		{
			//Disable hurt sounds	
			if(StrContains(sample, "player/damage") != -1)
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action Server_Say(int client, int args)
{
	if(client == 0)
	{
		char sBuffer[256];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		CPrintToChatAll("{dimgray}[{white}ADVERT{dimgray}] {white}%s", sBuffer);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	char sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if(sText[0] == '!' || sText[0] == '/')
	{
		if(IsCharUpper(sText[1]))
		{
			for(int i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}

			FakeClientCommand(client, "say %s", sText);
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
 
public Action Command_SayTeam(int client, const char[] command, int argc)
{
	char sText[300];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	if((sText[0] == '!') || (sText[0] == '/'))
	{
		if(IsCharUpper(sText[1]))
		{
			for(int i = 0; i <= strlen(sText); ++i)
			{
				sText[i] = CharToLower(sText[i]);
			}

			FakeClientCommand(client, "say_team %s", sText);
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void UseButton(const char[] output, int caller, int activator, float delay)
{
	if(IsValidClient(activator) && GetClientButtons(activator) & IN_USE)
	{
		if(gI_Button[activator] == 1 || gI_Button[activator] == 5 || gI_Button[activator] == 7)
		{
			Handle hMsg = StartMessageOne("Fade", activator);
			BfWriteShort(hMsg, 100);
			BfWriteShort(hMsg, 0);
			BfWriteShort(hMsg, 1 << 0);
			BfWriteByte(hMsg, 173); //Lightblue
			BfWriteByte(hMsg, 216);
			BfWriteByte(hMsg, 230);
			BfWriteByte(hMsg, 16);
			EndMessage();
		}
		
		if(gI_Button[activator] == 2 || gI_Button[activator] == 6 || gI_Button[activator] == 7)
		{
			CPrintToChat(activator, "{green}You have pressed a button.");
		}
		
		int iPartner = Trikz_FindPartner(activator);
		
		if(iPartner != -1)
		{
			if(gI_Button[iPartner] == 3 || gI_Button[iPartner] == 5 || gI_Button[iPartner] == 7)
			{
				Handle hMsg = StartMessageOne("Fade", iPartner);
				BfWriteShort(hMsg, 100);
				BfWriteShort(hMsg, 0);
				BfWriteShort(hMsg, 1 << 0);
				BfWriteByte(hMsg, 173); //Lightblue
				BfWriteByte(hMsg, 216);
				BfWriteByte(hMsg, 230);
				BfWriteByte(hMsg, 16);
				EndMessage();
			}
			
			if(gI_Button[iPartner] == 4 || gI_Button[iPartner] == 6 || gI_Button[iPartner] == 7)
			{
				CPrintToChat(iPartner, "{yellow}Your partner have pressed a button.");
			}
		}
	}
}

public void OnButtonDamaged(const char[] output, int caller, int activator, float delay)
{
	if(IsValidClient(activator) && gI_Button[activator] != 0 && GetClientButtons(activator) & IN_ATTACK)
	{
		Handle hMsg = StartMessageOne("Fade", activator);
		BfWriteShort(hMsg, 100);
		BfWriteShort(hMsg, 0);
		BfWriteShort(hMsg, 1 << 0);
		BfWriteByte(hMsg, 255); //Orange
		BfWriteByte(hMsg, 165);
		BfWriteByte(hMsg, 0);
		BfWriteByte(hMsg, 16);
		EndMessage();
	}
}

public Action TE_OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
	float vecOrigin[3];
	int nIndex = TE_ReadNum("m_nIndex");
	char sDecalName[64];

	TE_ReadVector("m_vecOrigin", vecOrigin);
	GetDecalName(nIndex, sDecalName, sizeof(sDecalName));

	if (StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	int nHitBox = TE_ReadNum("m_nHitBox");
	char sEffectName[64];

	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));

	if (StrEqual(sEffectName, "csblood")|| StrEqual(sEffectName, "Impact"))
	{	
		return Plugin_Handled;
	}

	if (StrEqual(sEffectName, "ParticleEffect"))
	{
		char sParticleEffectName[64];
		GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
		if(StrEqual(sParticleEffectName, "impact_helmet_headshot"))
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

void doublecheck(int client)
{
	if(!IsClientInGame(client))
	{
		return;
	}
	
	int Slot1 = GetPlayerWeaponSlot(client, 0);
	int Slot2 = GetPlayerWeaponSlot(client, 1);
	
	if(IsPlayerAlive(client) && gB_Ammo[client])
	{
		if(IsValidEntity(Slot1))
		{
			if(GetEntProp(Slot1, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot1, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot1, FindDataMapInfo(client, "m_iClip1"));
			}
		}
		
		if(IsValidEntity(Slot2))
		{
			if(GetEntProp(Slot2, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot2, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot2, FindDataMapInfo(client, "m_iClip1"));
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	// ping stuff
	if(buttons & IN_USE)
	{
		gI_tick[client]++;
		
		if(gI_tick[client] == 50)
		{
			PING(client);
		}
	}
	
	else
	{
		if(gI_tick[client] != 0)
		{
			gI_tick[client] = 0;
		}
	}

	// angle check stuff
	float iAngles[3];
	GetClientEyeAngles(client, iAngles);
	
	int iAngle = RoundFloat(iAngles[0] * -1);
	SetHudTextParams(0.395, 0.0, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	
	char sStatus[64];
	
	if(-27 < iAngle < 7)
	{
		sStatus = "Low Megalong";
	}

	else if(6 < iAngle < 26)
	{
		sStatus = "Megalong";
	}

	else if(25 < iAngle < 41)
	{
		sStatus = "Medium high Megalong";
	}

	else if(40 < iAngle < 66)
	{
		sStatus = "High Megalong";
	}

	else if(65 < iAngle < 76)
	{
		sStatus = "Low fast Megahigh";
	}

	else if(75 < iAngle < 86)
	{
		sStatus = "Medium fast Megahigh";
	}

	else if(85 < iAngle < 90)
	{
		sStatus = "Megahigh";
	}
	
	if(-27 < iAngle < 90)
	{
		if((gI_AngleStats[client] == 2 || gI_AngleStats[client] == 3) && IsPlayerAlive(client))
		{
			ShowSyncHudText(client, gH_SyncHud[client], "%i° | %s", iAngle, sStatus);
		}
		
		SpectatorCheck(client);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gI_AngleStats[i] == 2 || gI_AngleStats[i] == 3))
			{
				if(gI_SpectatorTarget[i] == client)
				{
					ShowSyncHudText(i, gH_SyncHud[client], "%i° | %s", iAngle, sStatus);
				}
			}
		}
	}

	// button stuff
	if(!IsPlayerAlive(client) && GetEntProp(client, Prop_Data, "m_afButtonPressed") & IN_USE)
	{
		int nObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		int nObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
		if(4 <= nObserverMode <= 6 && !IsFakeClient(nObserverTarget))
		{
			int iPartner = Trikz_FindPartner(nObserverTarget);
			
			if(iPartner != -1)
			{
				SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", iPartner);
			}
		}
	}

	// skin prefs stuff
	if(IsClientInGame(client) && IsPlayerAlive(client) && gB_Mirror_Trigger[client])
	{
		float fSpeed[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fSpeed);
		if(fSpeed[0] != 0.0 || fSpeed[1] != 0.0 || fSpeed[2] != 0.0)
		{
			//https://github.com/dvarnai/store-plugin/blob/master/addons/sourcemod/scripting/thirdperson.sp#L166-L179
			//SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1)
			SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
			//SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1)
			SetEntProp(client, Prop_Send, "m_iFOV", 90);
			gB_Mirror_Trigger[client] = false;
		}
	}

	// switch flashbang stuff
	if(!IsPlayerAlive(client) || IsFakeClient(client) || !gB_AutoSwitch[client])
	{
		return Plugin_Continue;
	}

	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(!IsValidEntity(iWeapon))
	{
		return Plugin_Continue;
	}
	
	float iTime = GetGameTime();
	
	if(iTime - gF_LastThrowTime[client] > 1.3 && gB_FlashThrown[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
		SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
		
		gB_FlashThrown[client] = false;
	}

	return Plugin_Continue;
}

void SpectatorCheck(int client)
{
	//Manage spectators
	if(!IsClientObserver(client))
	{
		return;
	}
	
	if(0 < gI_AngleStats[client] < 4)
	{
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		
		if(3 < iObserverMode < 7)
		{
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			if(gI_SpectatorTarget[client] != iTarget)
			{
				gI_SpectatorTarget[client] = iTarget;
			}
		}
		
		else
		{
			if(gI_SpectatorTarget[client] != -1)
			{
				gI_SpectatorTarget[client] = -1;
			}
		}
	}
}

public Action Timer_Ammo(Handle timer, int client)
{
	int Slot1 = GetPlayerWeaponSlot(client, 0);
	int Slot2 = GetPlayerWeaponSlot(client, 1);
	
	if(IsPlayerAlive(client) && gB_Ammo[client])
	{
		if(IsValidEntity(Slot1))
		{
			if(GetEntProp(Slot1, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot1, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot1, FindDataMapInfo(client, "m_iClip1"));
			}
		}
		
		if(IsValidEntity(Slot2))
		{
			if(GetEntProp(Slot2, Prop_Data, "m_iClip1") <= 90)
			{
				SetEntProp(Slot2, Prop_Data, "m_iClip1", 90);
				ChangeEdictState(Slot2, FindDataMapInfo(client, "m_iClip1"));
			}
		}
	}
	
	gB_AmmoCheck[client] = true;
}

public void Trikz_OnBoost(int client)
{
	if(IsValidClient(client) || IsPlayerAlive(client))
	{
		float origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		gF_autocheckpoint[client][0] = origin;
		float angles[3];
		GetClientEyeAngles(client, angles);
		gF_autocheckpoint[client][1] = angles;
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		gF_autocheckpoint[client][2] = velocity;
		gB_Checkpoint[client][2] = true;
	}
}

void SaveCP(int client, int cpnumber)
{
	if(IsValidClient(client) || cpnumber || IsPlayerAlive(client))
	{
		float origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		float angles[3];
		GetClientEyeAngles(client, angles);
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		cpnumber = cpnumber - 1;
		gF_checkpoint[client][cpnumber][0] = origin;
		gF_checkpoint[client][cpnumber][1] = angles;
		gF_checkpoint[client][cpnumber][2] = velocity;
		gB_Checkpoint[client][cpnumber] = true;
	}
}

void OpenStopWarningMenu(int client)
{
	Menu hMenu = new Menu(MenuHandler_StopWarning);
	hMenu.SetTitle("Would you like to stop timer?\n ");
	hMenu.AddItem("yes", "Yes\n ");
	hMenu.AddItem("no", "No");
	hMenu.ExitButton = false;
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_StopWarning(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[8];
		menu.GetItem(param2, sInfo, sizeof(sInfo));

		if(StrEqual(sInfo, "yes"))
		{
			Shavit_StopTimer(param1);
			Command_Checkpoint(param1, 1);
			
			if(Trikz_FindPartner(param1) != -1)
			{
				Shavit_StopTimer(Trikz_FindPartner(param1));
			}
		}
		
		else if(StrEqual(sInfo, "no"))
		{
			Command_Checkpoint(param1, 1);
		}
	}

	return view_as<int>(Plugin_Continue);
}
 
void LoadCP(int client, int cpnumber)
{
	if(IsValidClient(client) || cpnumber)
	{
		cpnumber = cpnumber - 1;
		
		if(gB_Checkpoint[client][cpnumber])
		{
			float origin[3];
			origin = gF_checkpoint[client][cpnumber][0];
			float angles[3];
			angles = gF_checkpoint[client][cpnumber][1];
			float velocity[3];
			velocity = gF_checkpoint[client][cpnumber][2];
			bool b[2];
			b[0] = gB_Restore[client][0];
			b[1] = gB_Restore[client][1];
			gB_IsCPLoaded = true;
			
			if(b[0] && b[1])
			{
				TeleportEntity(client, origin, angles, velocity);
			}
			
			if(!b[0] && b[1])
			{
				TeleportEntity(client, origin, NULL_VECTOR, velocity);
			}
			
			if(b[0] && !b[1])
			{
				TeleportEntity(client, origin, angles, view_as<float>({0.0, 0.0, 0.0}));
			}
			
			if(!b[0] && !b[1])
			{
				TeleportEntity(client, origin, NULL_VECTOR, view_as<float>({0.0, 0.0, 0.0}));
			}
			
			RequestFrame(RF_frameFirst, client);
		}
	}
}

void RF_frameFirst(int client)
{
	RequestFrame(RF_frameSecond, client);
}

void RF_frameSecond(int client)
{
	Shavit_StopTimer(client);
	
	if(Trikz_FindPartner(client) != -1)
	{
		Shavit_StopTimer(Trikz_FindPartner(client));
	}
	
	gB_IsCPLoaded = false;
}

void Weaponmenu(int client)
{
	Menu menu = new Menu(Weapon_MenuHandler);
	menu.SetTitle("Equipments menu\n ");
	menu.AddItem("sm_flash", "Give flashbangs\n ");
	menu.AddItem("sm_usp", "Give usp");
	menu.AddItem("sm_glock", "Give glock\n ");
	menu.AddItem("sm_scout", "Give scout\n ");
	menu.AddItem("sm_knife", "Give knife");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Weapon_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item, "sm_flash"))
			{
				FakeClientCommandEx(param1, "sm_flashbangs");
			}
			if(StrEqual(item, "sm_usp"))
			{
				FakeClientCommandEx(param1, "sm_usp");
			}
			if(StrEqual(item, "sm_glock"))
			{
				FakeClientCommandEx(param1, "sm_glock");
			}
			if(StrEqual(item, "sm_scout"))
			{
				FakeClientCommandEx(param1, "sm_scout");
			}
			if(StrEqual(item, "sm_knife"))
			{
				FakeClientCommandEx(param1, "sm_knife");
			}

			Weaponmenu(param1);
		}
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					FakeClientCommandEx(param1, "sm_trikz");
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return view_as<int>(Plugin_Continue);
}

void OpenFlashMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Flash);

	menu.SetTitle("Flashbang preference\n ");

	char sDisplay[18];

	FormatEx(sDisplay, 18, "Type [%s]", gS_PreferedTypeString[client]);
	menu.AddItem("type_chooser", sDisplay);

	FormatEx(sDisplay, 18, "Color [%s]", gA_PreferedColor[client].sColorName);
	menu.AddItem("color_chooser", sDisplay);

	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Flash(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[16];
		menu.GetItem(param2, sInfo, 16);

		if(StrEqual(sInfo, "type_chooser"))
		{
			OpenTypeChooserMenu(param1);
		}
		
		else if(StrEqual(sInfo, "color_chooser"))
		{
			OpenColorChooserMenu(param1);
		}
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void OpenTypeChooserMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MenuType);
	menu.SetTitle("Select flashbang type\n ");

	char sDisplay[16];
	FormatEx(sDisplay, 16, "%sDefault", (gI_PreferedType[client] == 0)? "＋ ":"");
	menu.AddItem("0", sDisplay, (gI_PreferedType[client] == 0)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	FormatEx(sDisplay, 16, "%sGlow", (gI_PreferedType[client] == 1)? "＋ ":"");
	menu.AddItem("1", sDisplay, (gI_PreferedType[client] == 1)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	FormatEx(sDisplay, 16, "%sShadow", (gI_PreferedType[client] == 2)? "＋ ":"");
	menu.AddItem("2", sDisplay, (gI_PreferedType[client] == 2)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	FormatEx(sDisplay, 16, "%sWireframe", (gI_PreferedType[client] == 3)? "＋ ":"");
	menu.AddItem("3", sDisplay, (gI_PreferedType[client] == 3)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuType(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[2];
		menu.GetItem(param2, sInfo, 2);

		int type = StringToInt(sInfo, 10);

		SetClientCookie(param1, gH_FlashTypeCookie, sInfo);
		gI_PreferedType[param1] = type;
		SetPrefTypeString(param1, type);

		OpenTypeChooserMenu(param1);
	}

	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			OpenFlashMenu(param1);
		}
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void OpenColorChooserMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MenuColor);
	menu.SetTitle("Select flashbang color\n ");

	char sDisplay[16];

	for(int i = 0; i < MAX_COLORS; i++) {
		char sColorId[4];
		IntToString(i, sColorId, 4);

		bool isPrefered = IsPreferedColor(client, i);

		FormatEx(sDisplay, 16, "%s%s", (isPrefered)? "＋ ":"", gA_ColorsTable[i].sColorName);
		menu.AddItem(sColorId, sDisplay, (isPrefered)? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	}

	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuColor(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sInfo[2];
		menu.GetItem(param2, sInfo, 2);

		int color = StringToInt(sInfo, 10);

		SetClientCookie(param1, gH_FlashColorCookie, sInfo);
		SetPrefColor(param1, color);

		OpenColorChooserMenu(param1);
	}

	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			OpenFlashMenu(param1);
		}
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void SetPrefTypeString(int client, int type)
{
	switch(type)
	{
		case 0:
		{
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "default");
		}
		case 1:
		{
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "glow");
		}
		case 2:
		{
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "shadow");
		}
		case 3:
		{
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "wireframe");
		}
	}
}

void SetPrefColor(int client, int color)
{
	gA_PreferedColor[client] = gA_ColorsTable[color];
}

bool IsPreferedColor(int client, int color)
{
	return gA_PreferedColor[client].iId == color;
}

public Action TextMsg(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if(reliable)
	{
		char sBuffer[256];
		BfReadString(bf, sBuffer, sizeof(sBuffer));
		
		if(StrContains(sBuffer, "\x03[SM]") == 0)
		{
			Handle hPack;
			CreateDataTimer(0.0, timer_strip, hPack);
			WritePackCell(hPack, playersNum);
			
			for(int i = 0; i < playersNum; i++)
			{
				WritePackCell(hPack, players[i]);
			}
			
			WritePackString(hPack, sBuffer);
			ResetPack(hPack);
			
			return Plugin_Handled;
        }
    }
	
	return Plugin_Continue;
}

public Action timer_strip(Handle timer, Handle pack)
{
	int playersNum = ReadPackCell(pack);
	int[] iPlayers = new int[playersNum];
	int iCount;
	
	for(int i = 1; i <= playersNum; i++)
	{
		int client = ReadPackCell(pack);
		
		if(IsClientInGame(client))
		{
			iPlayers[iCount++] = client;
		}
	}
	
	if(iCount > 0)
	{		
		playersNum = iCount;
		
		//Thanks to https://hlmod.ru/threads/sm-prefix-changer.18250/
		Handle hBf = StartMessage("SayText2", iPlayers, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
		BfWriteByte(hBf, -1);
		BfWriteByte(hBf, true);
		char sBuffer[256];
		ReadPackString(pack, sBuffer, sizeof(sBuffer));
		ReplaceString(sBuffer, sizeof(sBuffer), "[SM] ", "\x07FFFFFF");
		BfWriteString(hBf, sBuffer);
		EndMessage();
	}
}

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}

	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}

	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
	int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("decalprecache");
	}

	return ReadStringTable(table, index, sDecalName, maxlen);
}

void RemoveWeapon(any data)
{
	if(IsValidEntity(data))
	{
		AcceptEntityInput(data, "Kill");
	}
}

void PartnerMenu(int client)
{
	Menu menu = new Menu(PartnerAsk_MenuHandler);
	menu.SetTitle("Select your partner:\n ");
	
	char sDisplay[MAX_NAME_LENGTH];
	char sClientID[8];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client)
		{
			continue;
		}
		
		if(IsValidClient(i, true) && !IsFakeClient(i) && !IsClientSourceTV(i) && gI_Partner[i] == -1)
		{
			GetClientName(i, sDisplay, MAX_NAME_LENGTH);
			ReplaceString(sDisplay, MAX_NAME_LENGTH, "#", "?");
			IntToString(i, sClientID, sizeof(sClientID));
			menu.AddItem(sClientID, sDisplay);
		}
	}
	
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	
	if(menu.ItemCount > 0)
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
	
	else
	{
		CPrintToChat(client, "{white}No partners are available.");
		
		delete menu;
	}
}

public int PartnerAsk_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{	
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int client = StringToInt(info);
			
			if(IsValidClient(client, true) && IsValidClient(param1, true) && gI_Partner[client] == -1)
			{
				Menu menuask = new Menu(Partner_MenuHandler);
				menuask.SetTitle("%N wants to be your partner\n ", param1);
				char sDisplay[32];
				char sMenuInfo[32];
				IntToString(param1, sMenuInfo, sizeof(sMenuInfo));
				FormatEx(sDisplay, MAX_NAME_LENGTH, "Accept");
				menuask.AddItem(sMenuInfo, "Accept\n ");
				FormatEx(sDisplay, MAX_NAME_LENGTH, "Deny");
				menuask.AddItem(sMenuInfo, "Deny");
				menuask.ExitButton = false;
				menuask.Display(client, MENU_TIME_FOREVER);
			}
			
			else if(gI_Partner[client] != -1)
			{
				CPrintToChat(client, "{orange}%N {white}wants to be your partner.", param1);
			}
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_trikz");
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public int Partner_MenuHandler(Menu menuask, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menuask.GetItem(param2, info, sizeof(info));
			
			int client = StringToInt(info);
			
			if(gI_Partner[client] == -1)
			{
				switch(param2)
				{
					case 0:
					{
						gI_Partner[client] = param1; //partner = param1
						gI_Partner[param1] = client; //client = client
						
						Call_StartForward(gH_Forwards_OnPartner);
						Call_PushCell(client);
						Call_PushCell(param1);
						Call_Finish();
						
						if((Shavit_GetClientTrack(param1) == Track_Main || Shavit_GetClientTrack(param1) == Track_Bonus) 
							&& (Shavit_GetClientTrack(client) == Track_Main || Shavit_GetClientTrack(client) == Track_Bonus))
						{
							if(IsPlayerAlive(client))
							{
								SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
								SetEntityRenderMode(client, RENDER_NORMAL);
							}
							
							if(IsPlayerAlive(param1))
							{
								SetEntProp(param1, Prop_Data, "m_CollisionGroup", 5);
								SetEntityRenderMode(param1, RENDER_NORMAL);
							}
						}
						
						CPrintToChat(client, "{orange}%N {white}has accepted your partnership request.", param1);
						CPrintToChat(param1, "{white}You accepted partnership request with {orange}%N.", client);
					}
					
					case 1:
					{
						CPrintToChat(client, "{orange}%N {white}has denied your partnership request.", param1);
						CPrintToChat(param1, "{white}You denied partnership request with {orange}%N.", client);
					}
				}
			}
			
			else
			{
				CPrintToChat(param1, "{orange}%N {white}already have a partner.", client);
			}
		}
		
		case MenuAction_End:
		{
			delete menuask;
		}
	}
}

void UnPartnerMenu(int client)
{
	Menu menu = new Menu(UnPartnerAsk_MenuHandler);
	menu.SetTitle("Do you want to cancel your partnership with %N\n ", gI_Partner[client]);
	menu.AddItem("sm_accept", "Accept\n ");
	menu.AddItem("sm_deny", "Deny");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int UnPartnerAsk_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if(StrEqual(info, "sm_accept"))
			{
				int iPartner = gI_Partner[param1];
				
				if(gI_Partner[param1] != -1 && gI_Partner[iPartner] != -1)
				{
					gI_Partner[param1] = -1; //client
					gI_Partner[iPartner] = -1; //partner
					Call_StartForward(gH_Forwards_OnBreakPartner);
					Call_PushCell(param1);
					Call_PushCell(iPartner);
					Call_Finish();
					Shavit_StopTimer(param1);
					Shavit_StopTimer(iPartner);
					CPrintToChat(param1, "{orange}%N {white}is not your partner anymore.", iPartner);
					CPrintToChat(iPartner, "{orange}%N {white}has disabled his partnership with you.", param1);
				}
				
				else if(gI_Partner[param1] == -1)
				{
					CPrintToChat(param1, "{white}You don't have partner anymore.");
				}
			}
			
			if(StrEqual(info, "sm_deny"))
			{
				if(gI_Partner[param1] == -1)
				{
					CPrintToChat(param1, "{white}You don't have partner anymore.");
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
			{
				FakeClientCommand(param1, "sm_trikz");
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

void PrecacheFlashbang()
{
	gI_FlashModelIndex = PrecacheModel(FLASHBANG_W);

	AddFileToDownloadsTable("models/faqgame/flash/flashbang.mdl");
	AddFileToDownloadsTable("models/faqgame/flash/flashbang.dx90.vtx");
	AddFileToDownloadsTable("models/faqgame/flash/flashbang.dx80.vtx");
	AddFileToDownloadsTable("models/faqgame/flash/flashbang.phy");
	AddFileToDownloadsTable("models/faqgame/flash/flashbang.sw.vtx");
	AddFileToDownloadsTable("models/faqgame/flash/flashbang.vvd");

	AddFileToDownloadsTable("materials/faqgame/flash/default.vmt");
	AddFileToDownloadsTable("materials/faqgame/flash/view1.vmt");
	AddFileToDownloadsTable("materials/faqgame/flash/view2.vmt");
	AddFileToDownloadsTable("materials/faqgame/flash/view3.vmt");
}

void PrecachePing()
{
	char path[256];
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".mdl");
	PrecacheModel(path);
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".dx80.vtx");
	AddFileToDownloadsTable(path);
	
	Format(path, 256, "sound/%s", click_path);
	AddFileToDownloadsTable(path);
	PrecacheSound(click_path);
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".dx90.vtx");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".mdl");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".sw.vtx");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, ping_path);
	StrCat(path,255,".vvd");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, circle_arrow_path);
	StrCat(path,255,".vmt");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, circle_arrow_path);
	StrCat(path,255,".vtf");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, circle_point_path);
	StrCat(path,255,".vmt");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, circle_point_path);
	StrCat(path,255,".vtf");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, grad_path);
	StrCat(path,255,".vmt");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255, grad_path);
	StrCat(path,255,".vtf");
	AddFileToDownloadsTable(path);
}

void PrecacheSkin()
{
	gI_ModelIndex.iGIGN = PrecacheModel(dGIGN);
	gI_ModelIndex.iGSG9 = PrecacheModel(dGSG9);
	gI_ModelIndex.iSAS = PrecacheModel(dSAS);
	gI_ModelIndex.iURBAN = PrecacheModel(dURBAN);
}

void PING(int client)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You need to be alive to use this command!");
		return;
	}
	
	if(Trikz_FindPartner(client) < 1)
	{
		CPrintToChat(client, "{white}You need a partner to use this command!");
		return;
	}
	
	float ang[3], src[3], dst[3];
	
	GetClientEyePosition(client, src);
	
	GetClientEyeAngles(client, ang);
	
	GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
	
	ang[0] *= 8192.0;
	ang[1] *= 8192.0;
	ang[2] *= 8192.0;
	
	dst[0] = src[0] + ang[0];
	dst[1] = src[1] + ang[1];
	dst[2] = src[2] + ang[2];
	
	TR_TraceRayFilter(src, dst, MASK_ALL, RayType_EndPoint, is_player, client);
	
	if(TR_DidHit(null))
	{
		float end_pos[3];
		TR_GetEndPosition(end_pos, null);
		
		float end_plane[3];
		TR_GetPlaneNormal(null, end_plane);
		
		GetVectorAngles(end_plane, end_plane);
		
		float fwd[3];
		GetAngleVectors(end_plane, fwd, NULL_VECTOR, NULL_VECTOR);
		
		end_pos[0] += fwd[0] * 1.0;
		end_pos[1] += fwd[1] * 1.0;
		end_pos[2] += fwd[2] * 1.0;
		
		end_plane[0] -= 270.0;
		
		spawn_ping(client, end_pos, end_plane);
	}
}

bool is_player(int entity, int mask, any data)
{
	if(entity == data || entity <= MaxClients)
	{
		return false;
	}
	return true;
}

void spawn_ping(int client, float origin[3], float rotation[3])
{
	if(!gB_CanPing[client])
	{
		return;
	}
	
	if(gI_Pings[client] > 0 && gH_Timer_handle[client] != null)
	{
		KillTimer(gH_Timer_handle[client]);
		AcceptEntityInput(gI_Pings[client], "Kill");
		AcceptEntityInput(gI_Partner_Pings[Trikz_FindPartner(client)], "Kill");

		gI_Pings[client] = 0;
		gI_Partner_Pings[Trikz_FindPartner(client)] = -1;
	}
	
	char path[255];
	strcopy(path,255,ping_path);
	StrCat(path,255,".mdl");
	
	int client_ping_idx = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(client_ping_idx, path);
	DispatchSpawn(client_ping_idx);
	ActivateEntity(client_ping_idx);
	SetEntPropVector(client_ping_idx, Prop_Data, "m_angRotation", rotation);
	SetEntityRenderMode(client_ping_idx, RENDER_TRANSALPHA);
	SetEntityRenderColor(client_ping_idx, 134, 226, 213, 150);
	TeleportEntity(client_ping_idx, origin, NULL_VECTOR, NULL_VECTOR);
	
	int partner_ping_idx = CreateEntityByName("prop_dynamic_override");
	SetEntityModel(partner_ping_idx, path);
	DispatchSpawn(partner_ping_idx);
	ActivateEntity(partner_ping_idx);
	SetEntPropVector(partner_ping_idx, Prop_Data, "m_angRotation", rotation);
	SetEntityRenderMode(partner_ping_idx, RENDER_TRANSALPHA);
	SetEntityRenderColor(partner_ping_idx, 0, 230, 64, 150);
	TeleportEntity(partner_ping_idx, origin, NULL_VECTOR, NULL_VECTOR);
	
	gI_Pings[client] = client_ping_idx;
	gI_Partner_Pings[Trikz_FindPartner(client)] = partner_ping_idx;
	
	float client_origin[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", client_origin);
	
	SDKHook(client_ping_idx, SDKHook_SetTransmit, ping_transmit);
	SDKHook(partner_ping_idx, SDKHook_SetTransmit, ping_transmit);
	
	EmitSoundToClient(Trikz_FindPartner(client), click_path);
	EmitSoundToClient(client, click_path);
	
	gB_CanPing[client] = false;
	
	gI_Stored_Partnered[client] = Trikz_FindPartner(client);
	
	gH_Timer_handle[client] = CreateTimer(3.0, ping_timer, client);
	gH_Delay_handle[client] = CreateTimer(0.5, ping_delay, client);
}

public Action ping_transmit(int ping_entity, int others)
{
	int spec_mode = GetEntProp(others, Prop_Send, "m_iObserverMode");
	if(spec_mode == OBS_MODE_IN_EYE || spec_mode == OBS_MODE_CHASE)
	{
		others = GetEntPropEnt(others, Prop_Send, "m_hObserverTarget");
	}
	
	if(ping_entity != gI_Pings[others] && ping_entity != gI_Partner_Pings[others])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
} 

public Action ping_delay(Handle timer, any data)
{
	gB_CanPing[data] = true;
}

public Action ping_timer(Handle timer, any data)
{
	AcceptEntityInput(gI_Pings[data], "Kill");
	AcceptEntityInput(gI_Partner_Pings[gI_Stored_Partnered[data]], "Kill");
	gI_Pings[data] = 0;
	gI_Partner_Pings[gI_Stored_Partnered[data]] = 0;
	gI_Stored_Partnered[data] = 0;
}

void PrintRateMenu(int target, int client)
{
	char sInterp[8];
	char sInterp_ratio[8];
	char sLagCompensation[8];
	
	GetClientInfo(target, "cl_interp", sInterp, sizeof(sInterp));
	GetClientInfo(target, "cl_interp_ratio", sInterp_ratio, sizeof(sInterp_ratio));
	GetClientInfo(target, "cl_lagcompensation", sLagCompensation, sizeof(sLagCompensation));
	
	float fInterp = StringToFloat(sInterp);
	float fInterp_ratio = StringToFloat(sInterp_ratio);
	int fLagCompensation = StringToInt(sLagCompensation);
	
	Menu menu = new Menu(Rate_MenuHandler);
	menu.SetTitle("Networking for %N\n \ncl_interp %.5f\ncl_interp_ratio %.3f\ncl_lagcompensation %i\n \nCurrent lerp: %.1f ms\n ", target, fInterp, fInterp_ratio, fLagCompensation, GetEntPropFloat(target, Prop_Data, "m_fLerpTime") * 1000);
	char sTargetID[112];
	GetClientAuthId(target, AuthId_SteamID64, sTargetID, 26, true);
	FormatEx(gS_Profile[client], 64, "https://steamcommunity.com/profiles/%s", sTargetID);
	menu.AddItem("0", "Open steam profile\n ");
	menu.AddItem("1", "Back");
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_RateMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[MAX_NAME_LENGTH];
			menu.GetItem(param2, item, sizeof(item));
			int client = GetClientOfUserId(StringToInt(item));

			if(IsValidClient(client))
			{
				PrintRateMenu(client, param1);
			}
		}
		
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					FakeClientCommandEx(param1, "sm_trikz");
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public int Rate_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			
			switch(param2)
			{
				case 0:
				{
					ShowMOTDPanel(param1, "Steam profile", gS_Profile[param1][0], 2);
				}
				
				case 1:
				{
					FakeClientCommandEx(param1, "sm_rate");
				}
			}
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

void SkinApply(int client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		char sModelPath[64];
		GetClientModel(client, sModelPath, 32);

		if(StrEqual(sModelPath, "models/player/ct_gign.mdl") || GetClientTeam(client) == 2)
		{
			SetEntProp(client, Prop_Send, "m_nModelIndex", gI_ModelIndex.iGIGN);
		}

		if(StrEqual(sModelPath, "models/player/ct_gsg9.mdl"))
		{
			SetEntProp(client, Prop_Send, "m_nModelIndex", gI_ModelIndex.iGSG9);
		}

		if(StrEqual(sModelPath, "models/player/ct_sas.mdl"))
		{
			SetEntProp(client, Prop_Send, "m_nModelIndex", gI_ModelIndex.iSAS);
		}

		if(StrEqual(sModelPath, "models/player/ct_urban.mdl"))
		{
			SetEntProp(client, Prop_Send, "m_nModelIndex", gI_ModelIndex.iURBAN);
		}


		char sSkinType[2];
		GetClientCookie(client, gH_Skin.iType, sSkinType, 2);

		if(StrEqual(sSkinType, gS_SkinType_Default))
		{
			SetEntProp(client, Prop_Send, "m_nSkin", Type_Default);
		}

		if(StrEqual(sSkinType, gS_SkinType_Lightmap))
		{
			SetEntProp(client, Prop_Send, "m_nSkin", Type_Lightmap);
		}

		if(StrEqual(sSkinType, gS_SkinType_Fullbright))
		{
			SetEntProp(client, Prop_Send, "m_nSkin", Type_Fullbright);
		}

		SetEntityRenderColor(client, gI_SkinColor[client].iRED, gI_SkinColor[client].iGREEN, gI_SkinColor[client].iBLUE, 255);
	}
}

void SkinMenu(int client)
{
	Menu menu = new Menu(Skin_MenuHandler);
	menu.SetTitle("Skin preferences\n \nNotice: For 'lightmap' or 'fullbright' skin use cl_minmodels 0.\nTo change skin color, use, for ex. /skinrgb 255 165 0.\nRandom skin color /skinrgb -1 -1 -1\nExtra /gsc and /ems\n ");
	menu.AddItem("skin_color", "Color\n ");

	if(gI_Skin[client] == Type_Default)
	{
		menu.AddItem("skin_type_default", "[+] Default", ITEMDRAW_DISABLED);
		menu.AddItem("skin_type_lightmap", "Lightmap");
		menu.AddItem("skin_type_fullbright", "Fullbright");
	}

	if(gI_Skin[client] == Type_Lightmap)
	{
		menu.AddItem("skin_type_default", "Default");
		menu.AddItem("skin_type_lightmap", "[+] Lightmap", ITEMDRAW_DISABLED);
		menu.AddItem("skin_type_fullbright", "Fullbright");
	}

	if(gI_Skin[client] == Type_Fullbright)
	{
		menu.AddItem("skin_type_default", "Default");
		menu.AddItem("skin_type_lightmap", "Lightmap");
		menu.AddItem("skin_type_fullbright", "[+] Fullbright", ITEMDRAW_DISABLED);
	}

	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Skin_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char item[64];
			menu.GetItem(param2, item, sizeof(item));

			if(StrEqual(item, "skin_color"))
			{
				SkinColorMenu(param1);
			}

			if(StrEqual(item, "skin_type_default"))
			{
				gI_Skin[param1] = Type_Default;
				SetClientCookie(param1, gH_Skin.iType, gS_SkinType_Default);
				SkinApply(param1);
				Mirror_Trigger(param1);
				SkinMenu(param1);
			}

			if(StrEqual(item, "skin_type_lightmap"))
			{
				gI_Skin[param1] = Type_Lightmap;
				SetClientCookie(param1, gH_Skin.iType, gS_SkinType_Lightmap);
				SkinApply(param1);
				Mirror_Trigger(param1);
				SkinMenu(param1);
			}

			if(StrEqual(item, "skin_type_fullbright"))
			{
				gI_Skin[param1] = Type_Fullbright;
				SetClientCookie(param1, gH_Skin.iType, gS_SkinType_Fullbright);
				SkinApply(param1);
				Mirror_Trigger(param1);
				SkinMenu(param1);
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return view_as<int>(Plugin_Continue);
}

void SkinColorMenu(int client) 
{
	Menu menu = new Menu(SkinColor_MenuHandler);
	menu.SetTitle("Skin preferences - Color");
	menu.AddItem("0", "Default\n ");
	menu.AddItem("1", "Red");
	menu.AddItem("2", "Green");
	menu.AddItem("3", "Yellow");
	menu.AddItem("4", "Blue");
	menu.AddItem("5", "Aqua");
	menu.AddItem("6", "Pink");
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SkinColor_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	char sItem[64];
	menu.GetItem(param2, sItem, sizeof(sItem));
	switch(action)
	{		
		case MenuAction_Select:
		{
			if(StrEqual(sItem, "0"))
			{
				gI_SkinColor[param1].iRED = 255;
				gI_SkinColor[param1].iGREEN = 255;
				gI_SkinColor[param1].iBLUE = 255;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "255;255;255");
			}

			if(StrEqual(sItem, "1"))
			{
				gI_SkinColor[param1].iRED = 255;
				gI_SkinColor[param1].iGREEN = 0;
				gI_SkinColor[param1].iBLUE = 0;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "255;0;0");
			}

			if(StrEqual(sItem, "2"))
			{
				gI_SkinColor[param1].iRED = 0;
				gI_SkinColor[param1].iGREEN = 255;
				gI_SkinColor[param1].iBLUE = 0;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "0;255;0");
			}

			if(StrEqual(sItem, "3"))
			{
				gI_SkinColor[param1].iRED = 255;
				gI_SkinColor[param1].iGREEN = 255;
				gI_SkinColor[param1].iBLUE = 0;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "255;255;0");
			}

			if(StrEqual(sItem, "4"))
			{
				gI_SkinColor[param1].iRED = 0;
				gI_SkinColor[param1].iGREEN = 0;
				gI_SkinColor[param1].iBLUE = 255;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "0;0;255");
			}

			if(StrEqual(sItem, "5"))
			{
				gI_SkinColor[param1].iRED = 0;
				gI_SkinColor[param1].iGREEN = 250;
				gI_SkinColor[param1].iBLUE = 250;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "0;250;250");
			}

			if(StrEqual(sItem, "6"))
			{				
				gI_SkinColor[param1].iRED = 255;
				gI_SkinColor[param1].iGREEN = 145;
				gI_SkinColor[param1].iBLUE = 255;
				SetEntityRenderColor(param1, gI_SkinColor[param1].iRED, gI_SkinColor[param1].iGREEN, gI_SkinColor[param1].iBLUE, 255);
				SetClientCookie(param1, gH_Skin.iRGB, "255;145;255");
			}

			Mirror_Trigger(param1);
			SkinColorMenu(param1);
		}

		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					SkinMenu(param1);
				}
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return view_as<int>(Plugin_Continue);
}

void Mirror_Trigger(int client)
{
	if(IsPlayerAlive(client) && GetEntityFlags(client) & FL_ONGROUND) //check if player is on ground
	{		
		//https://github.com/dvarnai/store-plugin/blob/master/addons/sourcemod/scripting/thirdperson.sp#L166-L179
		//SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0) 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		//SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0)   
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		gB_Mirror_Trigger[client] = true;
	}
}

Action inbox(int client)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!");
		
		return Plugin_Handled;
	}
	
	Menu mMenu = new Menu(M_MenuInbox);
	mMenu.SetTitle("Teleport request inbox\n ");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client || !IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if(gB_Request[client][i])
		{
			char sInfo[64];
			FormatEx(sInfo, sizeof(sInfo), "%i", GetClientUserId(i));
			char sDisplay[64];
			GetClientName(i, sDisplay, sizeof(sDisplay));
			mMenu.AddItem(sInfo, sDisplay);
		}
	}
	
	if(mMenu.ItemCount == 0)
	{
		Command_Teleport(client, 0);
		CPrintToChat(client, "{white}Inbox is empty!");
		
		return Plugin_Handled;
	}
	
	mMenu.ExitBackButton = true;
	mMenu.ExitButton = true;
	mMenu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public int M_MenuInbox(Menu oldmenu, MenuAction action, int param1, int param2)
{
	if(!param1 || !IsValidClient(param1))
	{
		return view_as<int>(Plugin_Handled);
	}
	
	switch(action)
	{
		case MenuAction_Cancel:
		{
			switch(param2)
			{
				case MenuCancel_ExitBack:
				{
					FakeClientCommand(param1, "sm_trikz");
				}
			}
		}
	}
	
	char sInfo[32];
	
	if(!GetMenuItem(oldmenu, param2, sInfo, sizeof(sInfo)))
	{
		return view_as<int>(Plugin_Handled);
	}
	
	if(!IsPlayerAlive(param1))
	{
		CPrintToChat(param1, "{white}You must be alive to use this feature!");
		
		return view_as<int>(Plugin_Handled);
	}
	
	int sender = GetClientOfUserId(StringToInt(sInfo));
	
	if(!sender)
	{
		return view_as<int>(Plugin_Handled);
	}
	
	{
		char sDisplay[64];
		GetClientName(sender, sDisplay, sizeof(sDisplay));
		
		Menu menu = new Menu(H_TeleportMenu_Confirm);
		menu.SetTitle("%s wants to teleport to you! Do you accept?\n ", sDisplay);
		FormatEx(sInfo, sizeof(sInfo), "%i", GetClientUserId(sender));
		menu.AddItem(sInfo, "Agree\n ");
		menu.AddItem(sInfo, "Decline");
		menu.ExitButton = false;
		
		if(IsPlayerAlive(param1))
		{
			menu.Display(param1, MENU_TIME_FOREVER);
		}
		
		else
		{
			GetClientName(sender, sDisplay, sizeof(sDisplay));
			CPrintToChat(param1, "{orange}%s {white}should be alive to teleport to him/her.", sDisplay);
		}
	}
	
	return view_as<int>(Plugin_Continue);
}

public Action EnableBlockAfterTpto(Handle timer, int client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
	SetEntityRenderMode(client, RENDER_NORMAL);
}

//https://hlmod.ru/resources/vip-aim-teleport.584/
void TeleportClient(int client)
{
	if(!IsPlayerAlive(client))
	{
		return;
	}

	float ang[3];
	float pos[3];
	float vec[3];
	float start[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(start, trace);
		GetVectorDistance(pos, start, false);
		GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
		start[0] -= 35 * vec[0];
		start[1] -= 35 * vec[1];
		start[2] -= 35 * vec[2];
		GetClientAbsOrigin(client, pos);
		Shavit_StopTimer(client);
		if(Trikz_FindPartner(client) != -1 && Shavit_GetClientTrack(Trikz_FindPartner(client)) != Track_Solobonus)
			Shavit_StopTimer(Trikz_FindPartner(client));
		TeleportEntity(client, start, NULL_VECTOR, NULL_VECTOR);
		GetClientMins(client, vec);
		GetClientMaxs(client, ang);
		TR_TraceHullFilter(start, start, vec, ang, MASK_PLAYERSOLID, TraceEntityFilterPlayer, client);
		
		if(TR_DidHit())
		{
			CloseHandle(trace);
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
			
			return;
		}

		if(GetEntProp(client, Prop_Data, "m_CollisionGroup") > 0)
		{
			SetEntProp(client, Prop_Data, "m_CollisionGroup", 17);
			CreateTimer(3.0, OffNoBlockPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	CloseHandle(trace);
}

public Action OffNoBlockPlayer(Handle timer, int client)
{
	if((client = GetClientOfUserId(client)) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
	}
}

stock bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

public int Native_GetClientColorR(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int r, g, b, a;
	GetEntityRenderColor(client, r, g, b, a);

	return r;
}

public int Native_GetClientColorG(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int r, g, b, a;
	GetEntityRenderColor(client, r, g, b, a);

	return g;
}

public int Native_GetClientColorB(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int r, g, b, a;
	GetEntityRenderColor(client, r, g, b, a);

	return b;
}

public int Native_FindPartner(Handle handler, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		return -1;
	}

	if(gI_Partner[client] != -1 && client == gI_Partner[gI_Partner[client]])
	{
		return gI_Partner[client];
	}
	
	return -1;
}

public int Native_GetClientNoclip(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
	
    return gB_Noclip[client];
}

public int Native_LoadCP(Handle plugin, int numParams)
{
	return gB_IsCPLoaded;
}
