#include <sdkhooks>
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "No damage",
	author = "https://forums.alliedmods.net/showthread.php?p=1687371 (thetwistedpanda), modified by Smesh",
	description = "You can fall down and be alive.",
	version = "14.01.2021",
	url = "https://steamcommunity.com/id/smesh292/"
};

public void OnPluginStart()
{
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
	if(!IsValidClient(client))
	{
		return;
	}
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	//https://forums.alliedmods.net/showthread.php?p=1687371
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", NULL_VECTOR);
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngleVel", NULL_VECTOR);
	
	return Plugin_Handled; //Full godmode
}