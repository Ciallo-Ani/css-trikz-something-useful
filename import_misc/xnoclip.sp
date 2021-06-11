#include <trikz>
#include <shavit>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

bool gB_Noclip[MAXPLAYERS + 1];
bool gB_Late = false;

public Plugin myinfo =
{
	name = "Noclip",
	author = "https://forums.alliedmods.net/showthread.php?t=209155 (killjoy64), modified by Smesh",
	description = "You can toggle noclip.",
	version = "14.01.2021",
	url = "https://steamcommunity.com/id/smesh292/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Trikz_GetClientNoclip", Native_GetClientNoclip);
	gB_Late = late;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_nc", Command_NoClip);
	
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
	
	HookEvent("player_death", Player_Death);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		gB_Noclip[client] = false;
	}
}

Action Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	gB_Noclip[client] = false;
}

//Thanks to https://forums.alliedmods.net/showthread.php?t=209155
Action Command_NoClip(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{white}You must be alive to use this feature!", client);
		
		return Plugin_Handled;
	}
	
	if(Shavit_GetTimerStatus(client) == Timer_Running)
	{
		Menu hMenu = new Menu(MenuHandler_StopWarning);
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

public int MenuHandler_StopWarning(Menu menu, MenuAction action, int param1, int param2)
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

int Native_GetClientNoclip(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
	
    return gB_Noclip[client];
}