#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <trikz>

#pragma semicolon 1
#pragma newdecls required

int gB_AngleStats[MAXPLAYERS + 1]; 
Handle g_hSyncHud[MAXPLAYERS + 1];
int gI_SpectatorTarget[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[Trikz] Stats angles",
	author = "Skipper"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_ac", Command_AngleStats);
	
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i)) 
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	gB_AngleStats[client] = 0;
	g_hSyncHud[client] = CreateHudSynchronizer();
	
	gI_SpectatorTarget[client] = -1;
}

Action Command_AngleStats(int client, int args)
{
	if(gB_AngleStats[client] == 0)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Chat.");
		gB_AngleStats[client] = 1;
	}
	
	else if(gB_AngleStats[client] == 1)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Hud.");
		gB_AngleStats[client] = 2;
	}
	
	else if(gB_AngleStats[client] == 2)
	{
		CPrintToChat(client, "{white}Angles check is on. Mode: Both.");
		gB_AngleStats[client] = 3;
	}
	
	else if(gB_AngleStats[client] == 3)
	{
		CPrintToChat(client, "{white}Angles check is off.");
		gB_AngleStats[client] = 0;
	}
	
	return Plugin_Handled;
}

public void OnEntityCreated(int entity, const char[] classname) 
{
	if(StrContains(classname, "_projectile") != -1) 
	{
		SDKHook(entity, SDKHook_Spawn, SpawnPost_Grenade); 
	}
}

Action SpawnPost_Grenade(int entity)
{	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
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
		
		if(gB_AngleStats[client] == 1 || gB_AngleStats[client] == 3)
		{
			CPrintToChat(client, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s", iAngle, sStatus);
			
			if(iPartner != -1)
			{
				if(gB_AngleStats[iPartner] == 1 || gB_AngleStats[iPartner] == 3)
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
				if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gB_AngleStats[i] == 1 || gB_AngleStats[i] == 3))
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
				if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gB_AngleStats[i] == 1 || gB_AngleStats[i] == 3))
				{
					if(gI_SpectatorTarget[i] == client || gI_SpectatorTarget[i] == iPartner)
					{
						CPrintToChat(i, "{dimgray}[{white}AC{dimgray}] {white}Angle: {orange}%i{white}° {dimgray}| {white}%s {dimgray}| {orange}%N", iAngle, sStatus, client);
					}
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
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
		if((gB_AngleStats[client] == 2 || gB_AngleStats[client] == 3) && IsPlayerAlive(client))
		{
			ShowSyncHudText(client, g_hSyncHud[client], "%i° | %s", iAngle, sStatus);
		}
		
		SpectatorCheck(client);
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsClientSourceTV(i) && !IsClientReplay(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (gB_AngleStats[i] == 2 || gB_AngleStats[i] == 3))
			{
				if(gI_SpectatorTarget[i] == client)
				{
					ShowSyncHudText(i, g_hSyncHud[client], "%i° | %s", iAngle, sStatus);
				}
			}
		}
	}
}

void SpectatorCheck(int client)
{
	//Manage spectators
	if(!IsClientObserver(client))
	{
		return;
	}
	
	if(0 < gB_AngleStats[client] < 4)
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