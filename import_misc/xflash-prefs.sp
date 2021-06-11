#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <shavit>

#pragma newdecls required
#pragma semicolon 1

#define FLASHBANG_W "models/faqgame/flash/flashbang.mdl"

// cookies
Handle gH_FlashTypeCookie = null;
Handle gH_FlashColorCookie = null;

enum struct colors_t
{
	int iId;
	char sColorName[8];
	int iRed;
	int iGreen;
	int iBlue;
}

#define MAX_COLORS 7
colors_t gA_ColorsTable[MAX_COLORS];

// client prefered color
colors_t gA_PreferedColor[MAXPLAYERS + 1];

// client prefered type
int gI_PreferedType[MAXPLAYERS + 1]; // as Integer
char gS_PreferedTypeString[MAXPLAYERS + 1][10]; // as Char[10]

int gI_ModelIndex;

public Plugin myinfo =
{
	name = "Flashbang preferences",
	author = "Log",
	description = "",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_flash", Command_Flash);
	RegConsoleCmd("sm_fl", Command_Flash);
	RegConsoleCmd("sm_fb", Command_Flash);
	RegConsoleCmd("sm_fs", Command_Flash);
	
	gH_FlashTypeCookie = RegClientCookie("flashbang_type", "flashbang type cookie", CookieAccess_Protected);
	gH_FlashColorCookie = RegClientCookie("flashbang_color", "flashbang color cookie", CookieAccess_Protected);

	LoadColors();
}

public void OnMapStart()
{
	gI_ModelIndex = PrecacheModel(FLASHBANG_W);

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
}

public void LoadColors()
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

public Action Command_Flash(int client, int args) 
{
	if(client == 0)
	{
		return Plugin_Handled;
	}

	OpenFlashMenu(client);

	return Plugin_Handled;
}

/**
 * Root Menu Handler
 */
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

/**
 * Type Menu Handler
 */
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

/**
 * Color Menu Handler
 */
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

public void OnEntityCreated(int edict, const char[] classname)
{
	if(IsValidEntity(edict))
	{		
		if(StrEqual(classname, "flashbang_projectile"))
		{
			SDKHook(edict, SDKHook_SpawnPost, OnProjectileSpawned);
		}
	}
}

public void OnProjectileSpawned(int edict)
{
	if(IsValidEdict(edict))
	{
		int owner = GetEntPropEnt(edict, Prop_Data, "m_hOwnerEntity");
		
		if(IsModelPrecached(FLASHBANG_W) && gI_PreferedType[owner] != 0)
		{
			char sType[2];
			IntToString(gI_PreferedType[owner], sType, 2);

			//SetEntityModel(edict, FLASHBANG_W); 
			SetEntProp(edict, Prop_Send, "m_nModelIndex", gI_ModelIndex);
			DispatchKeyValue(edict, "skin", sType);
			SetEntityRenderColor(edict, gA_PreferedColor[owner].iRed, gA_PreferedColor[owner].iGreen, gA_PreferedColor[owner].iBlue, 255);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client) || !IsClientInGame(client))
	{
		return;
	}
	
	char sCookie[4];

	// retrieving type cookie
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

	// retrieving color cookie
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
}

/**
 *	API
 */

/**
 * @param client			Client index
 * @param type				Integer representation of flash type
 * @noreturn
 */
public void SetPrefTypeString(int client, int type)
{
	switch(type) {
		case 0: {
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "default");
		}
		case 1: {
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "glow");
		}
		case 2: {
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "shadow");
		}
		case 3: {
			FormatEx(gS_PreferedTypeString[client], 10, "%s", "wireframe");
		}
	}
}

/**
 * @param client			Client index
 * @param color				Int representation of flash color
 * @noreturn
 */
public void SetPrefColor(int client, int color)
{
	gA_PreferedColor[client] = gA_ColorsTable[color];
}

/**
 * @param client			Client index
 * @param color				Int representation of flash color
 * @return					True if given color matches client's prefered color
 */
public bool IsPreferedColor(int client, int color)
{
	return gA_PreferedColor[client].iId == color;
}